[CmdletBinding()]
param(
    [switch]$Apply
)

$ErrorActionPreference = 'Stop'

if (-not $Apply) {
    throw 'No database action was taken. Rerun with -Apply only after reviewing the isolated-test prerequisites.'
}

if ($env:GC_TEST_ISOLATED -ne 'YES') {
    throw 'Set GC_TEST_ISOLATED=YES only after confirming this is a disposable isolated test PDB.'
}

$repositoryRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$localEnvFile = Join-Path $repositoryRoot '.env.local'
$testCredentialFile = Join-Path $repositoryRoot '.env.test.local'
$testAppPassword = $null
$localTestPdb = $null
if (Test-Path -LiteralPath $localEnvFile -PathType Leaf) {
    $pdbEntry = Get-Content -LiteralPath $localEnvFile |
        Where-Object { $_ -match '^\s*GC_TEST_PDB\s*=' } |
        Select-Object -Last 1
    if ($pdbEntry -match '^\s*GC_TEST_PDB\s*=\s*(?<value>GC_TEST_[A-Z0-9_]+)\s*(?:#.*)?$') {
        $localTestPdb = $Matches['value']
    }
}

$tnsAlias = $env:GC_TEST_TNS_ALIAS
if ([string]::IsNullOrWhiteSpace($tnsAlias)) {
    $tnsAlias = $localTestPdb
}
$pdbName = $env:GC_TEST_PDB_NAME
if ([string]::IsNullOrWhiteSpace($pdbName)) {
    $pdbName = $localTestPdb
}
$apexRuntimeSchema = $env:GC_TEST_APEX_RUNTIME_SCHEMA
if ([string]::IsNullOrWhiteSpace($apexRuntimeSchema)) {
    $apexRuntimeSchema = 'GC_TEST_APEX_RUNTIME'
}
$ordsRuntimeSchema = $env:GC_TEST_ORDS_RUNTIME_SCHEMA
if ([string]::IsNullOrWhiteSpace($ordsRuntimeSchema)) {
    $ordsRuntimeSchema = 'GC_TEST_ORDS_RUNTIME'
}
$liquibaseUrl = $env:LIQUIBASE_COMMAND_URL
if ([string]::IsNullOrWhiteSpace($liquibaseUrl) -and -not [string]::IsNullOrWhiteSpace($tnsAlias)) {
    $liquibaseUrl = "jdbc:oracle:thin:@$tnsAlias"
}
$tnsAdminPath = (Resolve-Path (Join-Path $repositoryRoot 'database\admin\tns-test')).Path
$tnsNamesFile = Join-Path $tnsAdminPath 'tnsnames.ora'

foreach ($target in @(
    @{ Name = 'GC_TEST_TNS_ALIAS'; Value = $tnsAlias },
    @{ Name = 'GC_TEST_PDB_NAME'; Value = $pdbName },
    @{ Name = 'GC_TEST_APEX_RUNTIME_SCHEMA'; Value = $apexRuntimeSchema },
    @{ Name = 'GC_TEST_ORDS_RUNTIME_SCHEMA'; Value = $ordsRuntimeSchema }
)) {
    if ([string]::IsNullOrWhiteSpace($target.Value) -or $target.Value -notmatch '^GC_TEST_[A-Z0-9_]+$') {
        throw "$($target.Name) must use the GC_TEST_* naming convention."
    }
}

if ($apexRuntimeSchema -eq $ordsRuntimeSchema -or 'GC_APP' -in @($apexRuntimeSchema, $ordsRuntimeSchema)) {
    throw 'APEX and ORDS require separate runtime schemas, neither of which may be GC_APP.'
}

if ([string]::IsNullOrWhiteSpace($liquibaseUrl) -or
    $liquibaseUrl -notmatch '^jdbc:oracle:thin:@' -or
    $liquibaseUrl.IndexOf($pdbName, [StringComparison]::OrdinalIgnoreCase) -lt 0 -or
    $liquibaseUrl -match '^jdbc:oracle:thin:[^@]+@') {
    throw 'LIQUIBASE_COMMAND_URL must target the declared GC_TEST_* PDB and must not embed credentials.'
}

if (-not (Test-Path -LiteralPath $tnsNamesFile -PathType Leaf)) {
    throw 'Local test-only tnsnames.ora was not found.'
}

if ($env:LIQUIBASE_COMMAND_USERNAME -and $env:LIQUIBASE_COMMAND_USERNAME -cne 'GC_APP') {
    throw 'Liquibase must connect as GC_APP, matching the preflighted SQL*Plus owner.'
}
$env:LIQUIBASE_COMMAND_USERNAME = 'GC_APP'
$env:TNS_ADMIN = $tnsAdminPath

$changelog = 'database/changelog/db.changelog-master.yaml'
$targetCheckSql = Join-Path $PSScriptRoot 'validate-foundation-target.sql'
$verificationSql = Join-Path $PSScriptRoot 'validate-foundation.sql'
$liquibase = (Get-Command liquibase -ErrorAction Stop).Source
$sqlplus = (Get-Command sqlplus -ErrorAction Stop).Source
$expectedLiquibaseUrl = "jdbc:oracle:thin:@$tnsAlias"

if (Test-Path -LiteralPath $testCredentialFile -PathType Leaf) {
    $passwordEntry = Get-Content -LiteralPath $testCredentialFile |
        Where-Object { $_ -match '^\s*GC_TEST_GC_APP_PASSWORD\s*=' } |
        Select-Object -Last 1
    if ($passwordEntry -match '^\s*GC_TEST_GC_APP_PASSWORD\s*=\s*(?<value>.+?)\s*$') {
        $testAppPassword = $Matches['value']
    }
}

if ($liquibaseUrl -ne $expectedLiquibaseUrl) {
    throw 'LIQUIBASE_COMMAND_URL must use the same explicit GC_TEST_* TNS alias as SQL*Plus.'
}

if ([string]::IsNullOrWhiteSpace($testAppPassword)) {
    $securePassword = Read-Host 'GC_APP password for the disposable test PDB (hidden)' -AsSecureString
    $passwordPointer = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($securePassword)
    try {
        $testAppPassword = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($passwordPointer)
    }
    finally {
        [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($passwordPointer)
    }
}
$env:LIQUIBASE_COMMAND_PASSWORD = $testAppPassword

function Invoke-SqlPlusValidation {
    param(
        [Parameter(Mandatory)]
        [string]$SqlFile
    )

    $sqlplusArguments = @(
        '-L', '-S', '/nolog',
        "@$SqlFile",
        $pdbName,
        $apexRuntimeSchema,
        $ordsRuntimeSchema,
        $tnsAlias
    )
    Push-Location $PSScriptRoot
    try {
        $testAppPassword | & $sqlplus @sqlplusArguments
        if ($LASTEXITCODE -ne 0) {
            throw "SQL*Plus validation failed for $SqlFile."
        }
    }
    finally {
        Pop-Location
    }
}

Push-Location $repositoryRoot
try {
    Write-Host 'Checking the actual PDB and schema before any Liquibase operation.'
    Invoke-SqlPlusValidation -SqlFile $targetCheckSql

    Write-Host 'Validating Liquibase changelog for the isolated test target.'
    & $liquibase "--changelog-file=$changelog" '--log-level=warning' validate
    if ($LASTEXITCODE -ne 0) {
        throw 'Liquibase changelog validation failed.'
    }

    Write-Host 'Applying changesets to the explicitly designated isolated test PDB.'
    & $liquibase "--changelog-file=$changelog" '--log-level=warning' update
    if ($LASTEXITCODE -ne 0) {
        throw 'Liquibase update failed on the isolated test target.'
    }

    Write-Host 'Compiling foundation packages and checking grants through the Oracle wallet.'
    Invoke-SqlPlusValidation -SqlFile $verificationSql
}
finally {
    Pop-Location
    Remove-Item Env:LIQUIBASE_COMMAND_PASSWORD -ErrorAction SilentlyContinue
    $testAppPassword = $null
}

Write-Host 'Foundation validation completed on the isolated test target.'