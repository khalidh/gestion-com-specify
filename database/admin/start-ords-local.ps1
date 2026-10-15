$ErrorActionPreference = 'Stop'

$ordsExecutable = 'C:\app\Administrator\ords\26.2.3.237.1104\bin\ords.exe'
$ordsConfig = 'C:\app\Administrator\ords\config-gestion-commerciale'
$apexImages = 'C:\app\Administrator\apex_24.2_stage\verified\apex\images'
$port = 8080

if (-not (Test-Path -LiteralPath $ordsExecutable -PathType Leaf)) {
    throw "ORDS executable not found: $ordsExecutable"
}

if (-not (Test-Path -LiteralPath "$ordsConfig\databases\default\pool.xml" -PathType Leaf)) {
    throw "ORDS default pool configuration not found under: $ordsConfig"
}

if (-not (Test-Path -LiteralPath "$apexImages\apex_version.js" -PathType Leaf)) {
    throw "APEX static resources not found under: $apexImages"
}

$listener = Get-NetTCPConnection -State Listen -LocalPort $port -ErrorAction SilentlyContinue
if ($listener) {
    throw "Port $port is already in use. Check the existing listener before starting ORDS."
}

Write-Host "Starting ORDS 26.2 at http://localhost:$port/ords/"
Write-Host 'Keep this terminal open while using the APEX workspace. Press Ctrl+C to stop ORDS.'
& $ordsExecutable --config $ordsConfig serve
exit $LASTEXITCODE