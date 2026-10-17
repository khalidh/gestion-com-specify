$ErrorActionPreference = 'Stop'

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
$envFile = Join-Path $repoRoot '.env.test.local'
$oracleHome = 'C:\Oracle\Middleware\Oracle_Home'
$java = Join-Path $oracleHome 'oracle_common\jdk\bin\java.exe'
$fsalJar = Join-Path $oracleHome 'forms\java\frmsal.jar'
$module = Join-Path $oracleHome 'forms\GC_CLIENTS_DEMO.fmx'
$tnsAdmin = Join-Path $repoRoot 'database\admin\tns-test'
$settings = @{}

foreach ($line in [System.IO.File]::ReadAllLines($envFile)) {
    $separator = $line.IndexOf('=')
    if ($separator -gt 0) {
        $key = $line.Substring(0, $separator).Trim()
        if ($key -in @('GC_TEST_TNS_ALIAS', 'GC_TEST_GC_APP_PASSWORD')) {
            $value = $line.Substring($separator + 1).Trim()
            if ($value.Length -ge 2 -and (($value[0] -eq '"' -and $value[-1] -eq '"') -or ($value[0] -eq "'" -and $value[-1] -eq "'"))) {
                $value = $value.Substring(1, $value.Length - 2)
            }
            $settings[$key] = $value
        }
    }
}

if ([string]::IsNullOrWhiteSpace($settings['GC_TEST_TNS_ALIAS']) -or [string]::IsNullOrWhiteSpace($settings['GC_TEST_GC_APP_PASSWORD'])) {
    throw 'GC_TEST_TNS_ALIAS and GC_TEST_GC_APP_PASSWORD must be set in .env.test.local.'
}
foreach ($path in @($java, $fsalJar, $module)) {
    if (-not (Test-Path $path)) { throw "Required Forms file not found: $path" }
}
if (-not (Test-NetConnection -ComputerName 127.0.0.1 -Port 9001 -WarningAction SilentlyContinue).TcpTestSucceeded) {
    throw 'WLS_FORMS is not listening on localhost:9001.'
}

$runtimeUrl = 'http://127.0.0.1:9001/forms/frmservlet?config=standaloneapp&form=GC_CLIENTS_DEMO.fmx'
$previousOracleHome = $env:ORACLE_HOME
$previousTnsAdmin = $env:TNS_ADMIN
$previousPath = $env:PATH
$launcher = $null

try {
    $env:ORACLE_HOME = $oracleHome
    $env:TNS_ADMIN = $tnsAdmin
    $env:PATH = "$oracleHome\bin;$oracleHome\forms\bin;$oracleHome\oracle_common\jdk\bin;$previousPath"
    $launcher = Start-Process -FilePath $java -ArgumentList @('-jar', $fsalJar, '-url', $runtimeUrl) -WorkingDirectory (Split-Path $fsalJar -Parent) -PassThru

    $windowDeadline = [DateTime]::UtcNow.AddSeconds(30)
    $fsalWindow = $null
    while ([DateTime]::UtcNow -lt $windowDeadline) {
        $launcher.Refresh()
        if ($launcher.HasExited) {
            throw 'FSAL exited before the login window appeared.'
        }
        $fsalWindow = Get-Process -Id $launcher.Id -ErrorAction SilentlyContinue
        if ($fsalWindow -and $fsalWindow.MainWindowHandle -ne 0) {
            break
        }
        $null = Wait-Event -Timeout 0.25
    }
    if (-not $fsalWindow -or $fsalWindow.MainWindowHandle -eq 0) {
        throw 'No visible FSAL login window appeared within 30 seconds.'
    }

    $loginScript = Join-Path $PSScriptRoot 'connect_gc_clients_demo.ps1'
    if (-not (Test-Path -LiteralPath $loginScript -PathType Leaf)) {
        throw 'The local FSAL login helper was not found.'
    }
    & $loginScript
}
finally {
    $env:ORACLE_HOME = $previousOracleHome
    $env:TNS_ADMIN = $previousTnsAdmin
    $env:PATH = $previousPath
    $settings.Clear()
}