$ErrorActionPreference = 'Stop'

$envFile = Join-Path (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path '.env.test.local'
$settings = @{}
foreach ($line in [System.IO.File]::ReadAllLines($envFile)) {
    $separator = $line.IndexOf('=')
    if ($separator -gt 0) {
        $key = $line.Substring(0, $separator).Trim()
        if ($key -in @('GC_TEST_TNS_ALIAS', 'GC_TEST_GC_APP_PASSWORD')) {
            $settings[$key] = $line.Substring($separator + 1).Trim()
        }
    }
}

if ([string]::IsNullOrWhiteSpace($settings['GC_TEST_TNS_ALIAS']) -or [string]::IsNullOrWhiteSpace($settings['GC_TEST_GC_APP_PASSWORD'])) {
    throw 'GC_TEST_TNS_ALIAS and GC_TEST_GC_APP_PASSWORD must be set in .env.test.local.'
}
if ($settings['GC_TEST_GC_APP_PASSWORD'] -match '[{}+%^~()]') {
    throw 'The local password contains characters that Windows SendKeys treats specially.'
}

$fsal = Get-Process java -ErrorAction SilentlyContinue |
    Where-Object { $_.MainWindowTitle -like '*Oracle Fusion Middleware Forms Services*' -and $_.MainWindowHandle -ne 0 } |
    Sort-Object StartTime -Descending |
    Select-Object -First 1

if (-not $fsal) {
    throw 'No visible FSAL login window was found. Start the demo with run_gc_clients_demo.ps1 first.'
}
if (-not $fsal.Responding) {
    throw 'The FSAL window is not responding.'
}

$shell = New-Object -ComObject WScript.Shell
if (-not $shell.AppActivate($fsal.Id)) {
    throw 'Could not activate the FSAL window; no credentials were sent.'
}

if (-not ('FsalLoginInput' -as [type])) {
    Add-Type -TypeDefinition 'using System;using System.Runtime.InteropServices;public static class FsalLoginInput{[StructLayout(LayoutKind.Sequential)]public struct RECT{public int Left;public int Top;public int Right;public int Bottom;}[DllImport("user32.dll")]public static extern bool GetWindowRect(IntPtr handle,out RECT rect);[DllImport("user32.dll")]public static extern bool SetCursorPos(int x,int y);[DllImport("user32.dll")]public static extern void mouse_event(uint flags,uint x,uint y,uint data,IntPtr extra);}'
}
Add-Type -AssemblyName System.Windows.Forms
$windowRect = New-Object FsalLoginInput+RECT
if (-not [FsalLoginInput]::GetWindowRect($fsal.MainWindowHandle, [ref]$windowRect)) {
    throw 'Could not determine the FSAL window bounds; no credentials were sent.'
}
$password = $settings['GC_TEST_GC_APP_PASSWORD']
try {
    foreach ($field in @(
        @{ X = 0.54; Y = 0.47; Value = 'GC_APP' },
        @{ X = 0.54; Y = 0.53; Value = $password },
        @{ X = 0.54; Y = 0.59; Value = $settings['GC_TEST_TNS_ALIAS'] }
    )) {
        $fieldX = $windowRect.Left + [int](($windowRect.Right - $windowRect.Left) * $field.X)
        $fieldY = $windowRect.Top + [int](($windowRect.Bottom - $windowRect.Top) * $field.Y)
        if (-not [FsalLoginInput]::SetCursorPos($fieldX, $fieldY)) {
            throw 'Could not focus a FSAL login field; credentials were not submitted.'
        }
        [FsalLoginInput]::mouse_event(0x0002, 0, 0, 0, [IntPtr]::Zero)
        [FsalLoginInput]::mouse_event(0x0004, 0, 0, 0, [IntPtr]::Zero)
        $null = Wait-Event -Timeout 0.1
        [System.Windows.Forms.SendKeys]::SendWait('{HOME}')
        [System.Windows.Forms.SendKeys]::SendWait('+{END}')
        [System.Windows.Forms.SendKeys]::SendWait('{BACKSPACE}')
        [System.Windows.Forms.SendKeys]::SendWait($field.Value)
    }

    if (-not $shell.AppActivate($fsal.Id)) {
        throw 'Could not reactivate the FSAL login window; credentials were not submitted.'
    }
    $connectX = $windowRect.Left + [int](($windowRect.Right - $windowRect.Left) * 0.455)
    $connectY = $windowRect.Top + [int](($windowRect.Bottom - $windowRect.Top) * 0.66)
    if (-not [FsalLoginInput]::SetCursorPos($connectX, $connectY)) {
        throw 'Could not focus the FSAL Connect button; credentials were not submitted.'
    }
    [FsalLoginInput]::mouse_event(0x0002, 0, 0, 0, [IntPtr]::Zero)
    [FsalLoginInput]::mouse_event(0x0004, 0, 0, 0, [IntPtr]::Zero)

    [PSCustomObject]@{
        FsalWindowProcessId = $fsal.Id
        DatabaseAlias = $settings['GC_TEST_TNS_ALIAS']
        CredentialsSubmitted = $true
        PasswordInUrlOrArguments = $false
        SecretDisplayed = $false
    }
}
finally {
    $password = $null
    $settings.Clear()
}