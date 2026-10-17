[CmdletBinding()]
param(
    [string]$ModulePath
)

$ErrorActionPreference = 'Stop'

$repositoryRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
$credentialFile = Join-Path $repositoryRoot '.env.test.local'
$oracleHome = 'C:\Oracle\Middleware\Oracle_Home'
$builderExecutable = Join-Path $oracleHome 'bin\frmbld.exe'
if ([string]::IsNullOrWhiteSpace($ModulePath)) {
    $module = Join-Path $PSScriptRoot 'GC_CLIENTS_DEMO.fmb'
} else {
    $module = (Resolve-Path -LiteralPath $ModulePath).Path
}
$tnsAdmin = Join-Path $repositoryRoot 'database\admin\tns-test'
$settings = @{}

foreach ($line in [System.IO.File]::ReadAllLines($credentialFile)) {
    $separator = $line.IndexOf('=')
    if ($separator -gt 0) {
        $key = $line.Substring(0, $separator).Trim()
        if ($key -in @('GC_TEST_TNS_ALIAS', 'GC_TEST_GC_APP_PASSWORD')) {
            $settings[$key] = $line.Substring($separator + 1).Trim()
        }
    }
}

if ($settings['GC_TEST_TNS_ALIAS'] -cne 'GC_TEST_PDB' -or [string]::IsNullOrWhiteSpace($settings['GC_TEST_GC_APP_PASSWORD'])) {
    throw 'GC_TEST_TNS_ALIAS and GC_TEST_GC_APP_PASSWORD must target GC_TEST_PDB in .env.test.local.'
}
foreach ($path in @($builderExecutable, $module, $tnsAdmin)) {
    if (-not (Test-Path -LiteralPath $path)) {
        throw "Required Forms Builder path not found: $path"
    }
}
$existingBuilders = @(Get-Process -Name frmbld -ErrorAction SilentlyContinue)
$matchingBuilders = @($existingBuilders | Where-Object { $_.MainWindowTitle -like "*$module*" })
if ($matchingBuilders.Count -gt 1) {
    throw 'More than one Forms Builder process is showing the requested module.'
}

if (-not ('FormsBuilderInteropCrud' -as [type])) {
    Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;
using System.Text;
public static class FormsBuilderInteropCrud {
    public delegate bool EnumWindowsProc(IntPtr hwnd, IntPtr lParam);
    [StructLayout(LayoutKind.Sequential)] public struct RECT { public int Left; public int Top; public int Right; public int Bottom; }
    [DllImport("user32.dll")] public static extern bool EnumWindows(EnumWindowsProc callback, IntPtr lParam);
    [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr hwnd, out uint processId);
    [DllImport("user32.dll", CharSet=CharSet.Unicode)] public static extern int GetWindowText(IntPtr hwnd, StringBuilder text, int maxCount);
    [DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr hwnd);
    [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr hwnd, out RECT rect);
    [DllImport("user32.dll")] public static extern bool SetCursorPos(int x, int y);
    [DllImport("user32.dll")] public static extern void mouse_event(uint flags, uint x, uint y, uint data, IntPtr extra);
    [DllImport("user32.dll")] public static extern IntPtr GetMenu(IntPtr hwnd);
    [DllImport("user32.dll")] public static extern IntPtr GetSubMenu(IntPtr menu, int position);
    [DllImport("user32.dll")] public static extern int GetMenuItemCount(IntPtr menu);
    [DllImport("user32.dll", CharSet=CharSet.Unicode)] public static extern int GetMenuString(IntPtr menu, uint item, StringBuilder text, int maxCount, uint flags);
    [DllImport("user32.dll")] public static extern uint GetMenuItemID(IntPtr menu, int position);
    [DllImport("user32.dll")] public static extern bool PostMessage(IntPtr hwnd, uint message, IntPtr wParam, IntPtr lParam);
}
'@
}
Add-Type -AssemblyName UIAutomationClient
Add-Type -AssemblyName UIAutomationTypes
Add-Type -AssemblyName System.Windows.Forms

$previousOracleHome = $env:ORACLE_HOME
$previousTnsAdmin = $env:TNS_ADMIN
$previousPath = $env:PATH
$builder = $null
$password = $settings['GC_TEST_GC_APP_PASSWORD']

try {
    $env:ORACLE_HOME = $oracleHome
    $env:TNS_ADMIN = (Resolve-Path $tnsAdmin).Path
    $env:PATH = "$oracleHome\bin;$oracleHome\forms\bin;$oracleHome\oracle_common\jdk\bin;$previousPath"
    if ($matchingBuilders.Count -eq 1) {
        $builder = $matchingBuilders[0]
    } else {
        $builder = Start-Process -FilePath $builderExecutable -ArgumentList @("module=$module") -WorkingDirectory (Split-Path $builderExecutable -Parent) -PassThru

        $windowDeadline = [DateTime]::UtcNow.AddSeconds(45)
        do {
            $builder.Refresh()
            if ($builder.HasExited) {
                throw 'Forms Builder exited before its main window appeared.'
            }
            if ($builder.MainWindowHandle -ne 0) {
                break
            }
            $null = Wait-Event -Timeout 0.25
        } while ([DateTime]::UtcNow -lt $windowDeadline)
        if ($builder.MainWindowHandle -eq 0) {
            throw 'Forms Builder did not show a main window within 45 seconds.'
        }
    }

    $shell = New-Object -ComObject WScript.Shell
    if (-not $shell.AppActivate($builder.Id)) {
        throw 'Could not activate Forms Builder.'
    }
    $shell.SendKeys('^j')

    $script:connectDialogHandle = [IntPtr]::Zero
    $findConnectDialog = [FormsBuilderInteropCrud+EnumWindowsProc]{
        param($handle, $lParam)
        $owner = [uint32]0
        [void][FormsBuilderInteropCrud]::GetWindowThreadProcessId($handle, [ref]$owner)
        if ($owner -eq $builder.Id -and [FormsBuilderInteropCrud]::IsWindowVisible($handle)) {
            $title = New-Object System.Text.StringBuilder 256
            [void][FormsBuilderInteropCrud]::GetWindowText($handle, $title, $title.Capacity)
            if ($title.ToString() -eq 'Connect') {
                $script:connectDialogHandle = $handle
            }
        }
        return $true
    }

    $dialogDeadline = [DateTime]::UtcNow.AddSeconds(15)
    while ([DateTime]::UtcNow -lt $dialogDeadline -and $script:connectDialogHandle -eq [IntPtr]::Zero) {
        [void][FormsBuilderInteropCrud]::EnumWindows($findConnectDialog, [IntPtr]::Zero)
        if ($script:connectDialogHandle -eq [IntPtr]::Zero) {
            $null = Wait-Event -Timeout 0.25
        }
    }
    if ($script:connectDialogHandle -eq [IntPtr]::Zero) {
        throw 'The Builder Connect dialog did not appear.'
    }

    $dialog = [System.Windows.Automation.AutomationElement]::FromHandle($script:connectDialogHandle)
    $editCondition = New-Object System.Windows.Automation.PropertyCondition(
        [System.Windows.Automation.AutomationElement]::ClassNameProperty,
        'Edit'
    )
    $editElements = $dialog.FindAll([System.Windows.Automation.TreeScope]::Descendants, $editCondition)
    if ($editElements.Count -ne 3) {
        throw 'Expected User Name, Password, and Database fields in the Connect dialog.'
    }

    $fields = New-Object 'System.Collections.Generic.List[System.Windows.Automation.AutomationElement]'
    for ($index = 0; $index -lt $editElements.Count; $index++) {
        $fields.Add($editElements.Item($index))
    }
    $orderedFields = @($fields | Sort-Object { $_.Current.BoundingRectangle.Y })

    $buttonCondition = New-Object System.Windows.Automation.PropertyCondition(
        [System.Windows.Automation.AutomationElement]::ClassNameProperty,
        'Button'
    )
    $buttons = $dialog.FindAll([System.Windows.Automation.TreeScope]::Descendants, $buttonCondition)
    $connectButton = $null
    for ($index = 0; $index -lt $buttons.Count; $index++) {
        if ($buttons.Item($index).Current.Name -eq 'Connect') {
            $connectButton = $buttons.Item($index)
            break
        }
    }
    if (-not $connectButton -or -not $connectButton.Current.IsEnabled) {
        throw 'The Connect button is unavailable.'
    }

    if (-not $shell.AppActivate($builder.Id)) {
        throw 'Could not activate the Builder Connect dialog.'
    }
    $userNameRect = $orderedFields[0].Current.BoundingRectangle
    if (-not [FormsBuilderInteropCrud]::SetCursorPos([int]($userNameRect.X + 20), [int]($userNameRect.Y + $userNameRect.Height / 2))) {
        throw 'Could not focus the User Name field.'
    }
    [FormsBuilderInteropCrud]::mouse_event(0x0002, 0, 0, 0, [IntPtr]::Zero)
    [FormsBuilderInteropCrud]::mouse_event(0x0004, 0, 0, 0, [IntPtr]::Zero)

    [System.Windows.Forms.SendKeys]::SendWait('{HOME}')
    [System.Windows.Forms.SendKeys]::SendWait('+{END}')
    [System.Windows.Forms.SendKeys]::SendWait('{BACKSPACE}')
    [System.Windows.Forms.SendKeys]::SendWait('GC_APP')
    [System.Windows.Forms.SendKeys]::SendWait('{TAB}')
    [System.Windows.Forms.SendKeys]::SendWait('{HOME}')
    [System.Windows.Forms.SendKeys]::SendWait('+{END}')
    [System.Windows.Forms.SendKeys]::SendWait('{BACKSPACE}')
    [System.Windows.Forms.SendKeys]::SendWait($password)
    [System.Windows.Forms.SendKeys]::SendWait('{TAB}')
    [System.Windows.Forms.SendKeys]::SendWait('{HOME}')
    [System.Windows.Forms.SendKeys]::SendWait('+{END}')
    [System.Windows.Forms.SendKeys]::SendWait('{BACKSPACE}')
    [System.Windows.Forms.SendKeys]::SendWait($settings['GC_TEST_TNS_ALIAS'])

    $connectRect = $connectButton.Current.BoundingRectangle
    if (-not [FormsBuilderInteropCrud]::SetCursorPos([int]($connectRect.X + $connectRect.Width / 2), [int]($connectRect.Y + $connectRect.Height / 2))) {
        throw 'Could not focus the Connect button.'
    }
    [FormsBuilderInteropCrud]::mouse_event(0x0002, 0, 0, 0, [IntPtr]::Zero)
    [FormsBuilderInteropCrud]::mouse_event(0x0004, 0, 0, 0, [IntPtr]::Zero)

    $loginDeadline = [DateTime]::UtcNow.AddSeconds(30)
    do {
        $script:connectDialogHandle = [IntPtr]::Zero
        [void][FormsBuilderInteropCrud]::EnumWindows($findConnectDialog, [IntPtr]::Zero)
        if ($script:connectDialogHandle -eq [IntPtr]::Zero) {
            break
        }
        $null = Wait-Event -Timeout 0.25
    } while ([DateTime]::UtcNow -lt $loginDeadline)
    if ($script:connectDialogHandle -ne [IntPtr]::Zero) {
        throw 'Builder kept the Connect dialog open; inspect the login error.'
    }

    [PSCustomObject]@{
        BuilderProcessId = $builder.Id
        Module = $module
        DatabaseAlias = $settings['GC_TEST_TNS_ALIAS']
        Connected = $true
        PasswordInArguments = $false
        SecretDisplayed = $false
    }
} finally {
    $env:ORACLE_HOME = $previousOracleHome
    $env:TNS_ADMIN = $previousTnsAdmin
    $env:PATH = $previousPath
    $password = $null
    $settings.Clear()
    $script:connectDialogHandle = [IntPtr]::Zero
}