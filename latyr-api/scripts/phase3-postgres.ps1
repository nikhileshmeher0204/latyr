param(
    [ValidateSet('Start', 'Stop')][string]$Action = 'Start',
    [string]$PostgresBin = 'C:\Program Files\PostgreSQL\17\bin',
    [ValidateRange(1024, 65535)][int]$Port = 55439
)
$ErrorActionPreference = 'Stop'
$workspace = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..'))
$testRoot = [IO.Path]::GetFullPath((Join-Path $workspace 'graphify-out\.verification\postgres-phase3'))
$expectedPrefix = [IO.Path]::GetFullPath((Join-Path $workspace 'graphify-out\.verification')) + [IO.Path]::DirectorySeparatorChar
if (-not $testRoot.StartsWith($expectedPrefix, [StringComparison]::OrdinalIgnoreCase)) { throw 'Test cluster must remain in the verification directory.' }
$data = Join-Path $testRoot 'data'
$pgCtl = Join-Path $PostgresBin 'pg_ctl.exe'
if (-not (Test-Path -LiteralPath $pgCtl)) { throw "PostgreSQL binaries unavailable at $PostgresBin" }
if ($Action -eq 'Stop') {
    if (Test-Path -LiteralPath (Join-Path $data 'postmaster.pid')) {
        & $pgCtl -D $data -m fast -w stop
        if ($LASTEXITCODE -ne 0) { throw 'Could not stop the isolated test cluster.' }
    }
    exit 0
}
New-Item -ItemType Directory -Path $testRoot -Force | Out-Null
if (-not (Test-Path -LiteralPath (Join-Path $data 'PG_VERSION'))) {
    & (Join-Path $PostgresBin 'initdb.exe') -D $data -U latyr_test -A trust -E UTF8 --locale=C
    if ($LASTEXITCODE -ne 0) { throw 'Could not initialize the isolated test cluster.' }
}
& $pgCtl -D $data status *> $null
if ($LASTEXITCODE -ne 0) {
    & $pgCtl -D $data -l (Join-Path $testRoot 'postgres.log') -o "-h 127.0.0.1 -p $Port" -w start
    if ($LASTEXITCODE -ne 0) { throw 'Could not start the isolated test cluster.' }
}
& (Join-Path $PostgresBin 'psql.exe') -h 127.0.0.1 -p $Port -U latyr_test -d postgres -v ON_ERROR_STOP=1 -Atc "SELECT 1 FROM pg_database WHERE datname = 'latyr_phase3_test'" | Out-String | ForEach-Object {
    if ($_.Trim() -ne '1') {
        & (Join-Path $PostgresBin 'createdb.exe') -h 127.0.0.1 -p $Port -U latyr_test latyr_phase3_test
        if ($LASTEXITCODE -ne 0) { throw 'Could not create the isolated test database.' }
    }
}
Write-Output "TEST_DATABASE_URL=jdbc:postgresql://127.0.0.1:$Port/latyr_phase3_test?user=latyr_test"
Write-Output 'Loopback-only disposable test cluster; no production database or service was changed.'
