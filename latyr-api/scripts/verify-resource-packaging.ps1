param(
    [Parameter(Mandatory = $true)]
    [string] $MavenPath
)

$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path $PSScriptRoot -Parent
$fixtureRoot = Join-Path $projectRoot ('target/packaging-verification-' + [guid]::NewGuid().ToString('N'))
$resourcesRoot = Join-Path $fixtureRoot 'src/main/resources'
$classesRoot = Join-Path $fixtureRoot 'target/classes'
New-Item -ItemType Directory -Path $resourcesRoot, $classesRoot -Force | Out-Null
Copy-Item -LiteralPath (Join-Path $projectRoot 'pom.xml') -Destination (Join-Path $fixtureRoot 'pom.xml')

# Build only nonsecret fixtures: never copy the application's real resource tree.
$blockedNames = @(
    'firebase-service-account.json', 'nested/service-account-test.json',
    'nested/service_account.json', 'nested/credentials.json',
    'nested/serviceAccount-test.json', 'firebase-adminsdk-test.json',
    'google-services.json', 'GoogleService-Info.plist', 'nested/client_secret_test.json',
    'token.json', 'tokens.json', 'secrets.json', 'secrets.yml', 'secrets.yaml',
    'nested/signing.jks', 'nested/private.p8', 'local.properties',
    'application-local.yml', 'nested/application-local-dev.yaml',
    '.env', 'nested/.env.local', 'private.key', 'nested/private.pem',
    'signing.keystore', 'nested/signing.p12', 'signing.pfx',
    'application-local.properties', 'nested/application-local-test.properties'
)
foreach ($relativeName in $blockedNames) {
    foreach ($root in @($resourcesRoot, $classesRoot)) {
        $fixturePath = Join-Path $root $relativeName
        New-Item -ItemType Directory -Path (Split-Path $fixturePath -Parent) -Force | Out-Null
        Set-Content -LiteralPath $fixturePath -Value 'nonsecret packaging regression fixture'
    }
}
$staleOnly = Join-Path $classesRoot 'stale-only/firebase-service-account.json'
New-Item -ItemType Directory -Path (Split-Path $staleOnly -Parent) -Force | Out-Null
Set-Content -LiteralPath $staleOnly -Value 'nonsecret stale output fixture'
Set-Content -LiteralPath (Join-Path $resourcesRoot 'application.properties') -Value 'spring.application.name=packaging-fixture'
$migration = Join-Path $resourcesRoot 'db/migration/V1__fixture.sql'
New-Item -ItemType Directory -Path (Split-Path $migration -Parent) -Force | Out-Null
Set-Content -LiteralPath $migration -Value 'SELECT 1;'

& $MavenPath -o -f (Join-Path $fixtureRoot 'pom.xml') package '-Dmaven.test.skip=true' '-Dspring-boot.repackage.skip=true'
if ($LASTEXITCODE -ne 0) { throw 'Packaging fixture build failed.' }

$jarPath = Join-Path $fixtureRoot 'target/latyr-api-0.0.1-SNAPSHOT.jar'
Add-Type -AssemblyName System.IO.Compression.FileSystem
$archive = [System.IO.Compression.ZipFile]::OpenRead($jarPath)
try {
    $entries = @($archive.Entries | ForEach-Object { $_.FullName })
    foreach ($relativeName in @($blockedNames) + @('stale-only/firebase-service-account.json')) {
        if ($entries -contains $relativeName) { throw "Credential fixture packaged: $relativeName" }
        if (Test-Path -LiteralPath (Join-Path $classesRoot $relativeName)) { throw "Credential fixture left in output: $relativeName" }
    }
    foreach ($relativeName in @('application.properties', 'db/migration/V1__fixture.sql')) {
        if ($entries -notcontains $relativeName) { throw "Required resource missing: $relativeName" }
    }
    foreach ($relativeName in $blockedNames) {
        if (-not (Test-Path -LiteralPath (Join-Path $resourcesRoot $relativeName))) { throw "Source fixture was removed: $relativeName" }
    }
} finally {
    $archive.Dispose()
}
Write-Output 'PASS: fresh and stale credential fixtures excluded from output and packaged JAR; application config, migrations and source fixtures preserved.'
