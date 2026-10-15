[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$ConfirmTarget
)

$ErrorActionPreference = 'Stop'

if ($ConfirmTarget -cne 'GC_TEST_PDB') {
    throw 'ConfirmTarget must be exactly GC_TEST_PDB.'
}
if ($env:GC_TEST_ISOLATED -cne 'YES') {
    throw 'Set GC_TEST_ISOLATED=YES only after confirming this is a disposable isolated test PDB.'
}

$repositoryRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$credentialFile = Join-Path $repositoryRoot '.env.test.local'
$temporaryCredentialFile = "$credentialFile.tmp"
$tnsAdminPath = (Resolve-Path (Join-Path $repositoryRoot 'database\admin\tns-test')).Path
$tnsNamesFile = Join-Path $tnsAdminPath 'tnsnames.ora'
$sqlplus = (Get-Command sqlplus -ErrorAction Stop).Source
$git = (Get-Command git -ErrorAction Stop).Source

if (Test-Path -LiteralPath $credentialFile) {
    throw '.env.test.local already exists; refusing to overwrite credentials.'
}
if (Test-Path -LiteralPath $temporaryCredentialFile) {
    throw 'A temporary credential file already exists; inspect it before continuing.'
}
if (-not (Test-Path -LiteralPath $tnsNamesFile -PathType Leaf)) {
    throw 'The isolated test TNS configuration was not found.'
}
if (-not (Select-String -LiteralPath $tnsNamesFile -Pattern '^\s*GC_TEST_PDB\s*=' -Quiet)) {
    throw 'The GC_TEST_PDB TNS alias was not found.'
}
& $git -C $repositoryRoot check-ignore --quiet -- .env.test.local
if ($LASTEXITCODE -ne 0) {
    throw '.env.test.local is not ignored by Git; refusing to write credentials.'
}

$env:TNS_ADMIN = $tnsAdminPath
$passwords = @{}

function Invoke-SqlPlusText {
    param(
        [Parameter(Mandatory)]
        [string]$SqlText,
        [Parameter(Mandatory)]
        [string]$Operation
    )

    $startInfo = New-Object System.Diagnostics.ProcessStartInfo
    $startInfo.FileName = $sqlplus
    $startInfo.Arguments = '-L -S /nolog'
    $startInfo.UseShellExecute = $false
    $startInfo.CreateNoWindow = $true
    $startInfo.RedirectStandardInput = $true
    $startInfo.RedirectStandardOutput = $true
    $startInfo.RedirectStandardError = $true

    $process = New-Object System.Diagnostics.Process
    $process.StartInfo = $startInfo
    if (-not $process.Start()) {
        throw "Could not start SQL*Plus for $Operation."
    }

    $stdoutTask = $process.StandardOutput.ReadToEndAsync()
    $stderrTask = $process.StandardError.ReadToEndAsync()
    $process.StandardInput.WriteLine($SqlText)
    $process.StandardInput.Close()
    $process.WaitForExit()

    $output = $stdoutTask.GetAwaiter().GetResult()
    $errorOutput = $stderrTask.GetAwaiter().GetResult()
    foreach ($password in $passwords.Values) {
        if ($password) {
            $output = $output.Replace($password, '[redacted]')
            $errorOutput = $errorOutput.Replace($password, '[redacted]')
        }
    }

    if ($process.ExitCode -ne 0) {
        throw "$Operation failed (SQL*Plus exit $($process.ExitCode)): $output $errorOutput"
    }
    return "$output`n$errorOutput"
}

function New-TestPassword {
    $alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz23456789_#'
    $limit = [Math]::Floor(256 / $alphabet.Length) * $alphabet.Length
    $random = [System.Security.Cryptography.RandomNumberGenerator]::Create()
    $builder = New-Object System.Text.StringBuilder
    $byte = New-Object byte[] 1
    try {
        while ($builder.Length -lt 24) {
            $random.GetBytes($byte)
            if ($byte[0] -ge $limit) {
                continue
            }
            [void]$builder.Append($alphabet[[int]($byte[0] % $alphabet.Length)])
        }
        return $builder.ToString()
    }
    finally {
        $random.Dispose()
    }
}

$preflightSql = @'
SET ECHO OFF
SET VERIFY OFF
SET FEEDBACK OFF
WHENEVER SQLERROR EXIT SQL.SQLCODE
CONNECT / AS SYSDBA
DECLARE
  L_PDB_COUNT PLS_INTEGER;
BEGIN
  IF SYS_CONTEXT('USERENV', 'CON_NAME') <> 'CDB$ROOT' THEN
    RAISE_APPLICATION_ERROR(-20004, 'Expected CDB$ROOT for local SYSDBA connection.');
  END IF;
  SELECT COUNT(*) INTO L_PDB_COUNT
    FROM V$PDBS WHERE NAME = 'GC_TEST_PDB' AND OPEN_MODE = 'READ WRITE';
  IF L_PDB_COUNT <> 1 THEN
    RAISE_APPLICATION_ERROR(-20004, 'GC_TEST_PDB must be open READ WRITE.');
  END IF;
END;
/
ALTER SESSION SET CONTAINER = GC_TEST_PDB;
DECLARE
  L_USER_COUNT PLS_INTEGER;
BEGIN
  SELECT COUNT(*) INTO L_USER_COUNT
    FROM DBA_USERS
   WHERE USERNAME IN ('GC_APP', 'GC_TEST_APEX_RUNTIME', 'GC_TEST_ORDS_RUNTIME')
     AND ACCOUNT_STATUS = 'OPEN';
  IF L_USER_COUNT <> 3 THEN
    RAISE_APPLICATION_ERROR(-20004, 'All three test accounts must exist and be open.');
  END IF;
END;
/
SELECT 'PREFLIGHT_OK GC_TEST_PDB' FROM DUAL;
EXIT SUCCESS
'@

$preflightResult = Invoke-SqlPlusText -SqlText $preflightSql -Operation 'Test PDB preflight'
if ($preflightResult -notmatch 'PREFLIGHT_OK GC_TEST_PDB') {
    throw 'The test PDB preflight did not return its success marker.'
}

$passwords['GC_APP'] = New-TestPassword
$passwords['GC_TEST_APEX_RUNTIME'] = New-TestPassword
$passwords['GC_TEST_ORDS_RUNTIME'] = New-TestPassword

$credentialContents = @"
GC_TEST_PDB=GC_TEST_PDB
GC_TEST_PDB_NAME=GC_TEST_PDB
GC_TEST_TNS_ALIAS=GC_TEST_PDB
GC_TEST_GC_APP_PASSWORD=$($passwords['GC_APP'])
GC_TEST_APEX_RUNTIME_PASSWORD=$($passwords['GC_TEST_APEX_RUNTIME'])
GC_TEST_ORDS_RUNTIME_PASSWORD=$($passwords['GC_TEST_ORDS_RUNTIME'])
"@

$encoding = New-Object System.Text.UTF8Encoding -ArgumentList $false
[System.IO.File]::WriteAllText($temporaryCredentialFile, $credentialContents + [Environment]::NewLine, $encoding)
$identity = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
$acl = Get-Acl -LiteralPath $temporaryCredentialFile
$acl.SetAccessRuleProtection($true, $false)
$acl.SetOwner([System.Security.Principal.NTAccount]$identity)
$rule = New-Object System.Security.AccessControl.FileSystemAccessRule -ArgumentList @(
    $identity,
    [System.Security.AccessControl.FileSystemRights]::FullControl,
    [System.Security.AccessControl.AccessControlType]::Allow
)
$acl.SetAccessRule($rule)
Set-Acl -LiteralPath $temporaryCredentialFile -AclObject $acl
[System.IO.File]::Move($temporaryCredentialFile, $credentialFile)

$rotationSql = @"
SET ECHO OFF
SET VERIFY OFF
SET FEEDBACK OFF
WHENEVER SQLERROR EXIT SQL.SQLCODE
CONNECT / AS SYSDBA
DECLARE
  L_PDB_COUNT PLS_INTEGER;
BEGIN
  IF SYS_CONTEXT('USERENV', 'CON_NAME') <> 'CDB`$ROOT' THEN
    RAISE_APPLICATION_ERROR(-20004, 'Expected CDB`$ROOT for local SYSDBA connection.');
  END IF;
  SELECT COUNT(*) INTO L_PDB_COUNT
    FROM V`$PDBS WHERE NAME = 'GC_TEST_PDB' AND OPEN_MODE = 'READ WRITE';
  IF L_PDB_COUNT <> 1 THEN
    RAISE_APPLICATION_ERROR(-20004, 'GC_TEST_PDB must be open READ WRITE.');
  END IF;
END;
/
ALTER SESSION SET CONTAINER = GC_TEST_PDB;
ALTER USER GC_APP IDENTIFIED BY `"$($passwords['GC_APP'])`";
ALTER USER GC_TEST_APEX_RUNTIME IDENTIFIED BY `"$($passwords['GC_TEST_APEX_RUNTIME'])`";
ALTER USER GC_TEST_ORDS_RUNTIME IDENTIFIED BY `"$($passwords['GC_TEST_ORDS_RUNTIME'])`";
EXIT SUCCESS
"@
Invoke-SqlPlusText -SqlText $rotationSql -Operation 'Test account password rotation' | Out-Null

foreach ($account in @(
    @{ User = 'GC_APP'; Password = $passwords['GC_APP'] },
    @{ User = 'GC_TEST_APEX_RUNTIME'; Password = $passwords['GC_TEST_APEX_RUNTIME'] },
    @{ User = 'GC_TEST_ORDS_RUNTIME'; Password = $passwords['GC_TEST_ORDS_RUNTIME'] }
)) {
    $loginSql = @"
SET ECHO OFF
SET VERIFY OFF
SET FEEDBACK OFF
WHENEVER SQLERROR EXIT SQL.SQLCODE
CONNECT $($account.User)/`"$($account.Password)`"@GC_TEST_PDB
BEGIN
  IF USER <> '$($account.User)' OR SYS_CONTEXT('USERENV', 'CON_NAME') <> 'GC_TEST_PDB' THEN
    RAISE_APPLICATION_ERROR(-20004, 'Login reached an unexpected schema or PDB.');
  END IF;
END;
/
SELECT 'LOGIN_OK $($account.User) GC_TEST_PDB' FROM DUAL;
EXIT SUCCESS
"@
    $loginResult = Invoke-SqlPlusText -SqlText $loginSql -Operation "Login test for $($account.User)"
    if ($loginResult -notmatch "LOGIN_OK $($account.User) GC_TEST_PDB") {
        throw "Login test for $($account.User) did not return its success marker. The credentials remain in .env.test.local."
    }
    Write-Host "Login verified: $($account.User) on GC_TEST_PDB"
}

Write-Host 'Rotated credentials are stored in .env.test.local; the file ACL is limited to the current Windows user.'