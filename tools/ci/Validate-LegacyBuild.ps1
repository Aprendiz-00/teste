$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot '../..')
$solution = Join-Path $repoRoot 'Source/The New World.sln'
$tmProject = Join-Path $repoRoot 'Source/Code/TMSrv/TMSrv.vcxproj'
$dbProject = Join-Path $repoRoot 'Source/Code/DBSrv/DBSrv.vcxproj'
$dependencyManifestPath = Join-Path $repoRoot 'config/build-dependencies.json'

$required = @($solution, $tmProject, $dbProject, $dependencyManifestPath)
foreach ($path in $required) {
    if (-not (Test-Path $path)) {
        throw "Required legacy build file not found: $path"
    }
}

Write-Host 'Legacy build files: OK'

$projectFiles = @($tmProject, $dbProject)
$absolutePathPatterns = @(
    '[A-Za-z]:\\Users\\',
    'C:\\Novo Emulador'
)

$absolutePathHits = @()
foreach ($project in $projectFiles) {
    $content = Get-Content -Raw $project
    foreach ($pattern in $absolutePathPatterns) {
        if ($content -match $pattern) {
            $absolutePathHits += $project
            break
        }
    }
}

if ($absolutePathHits.Count -gt 0) {
    Write-Warning ('Legacy project files still contain historical machine-specific paths. Shared MSBuild policy overrides the relevant TMSrv/DBSrv settings: ' + (($absolutePathHits | Sort-Object -Unique) -join ', '))
} else {
    Write-Host 'Machine-specific paths: none detected in TMSrv/DBSrv projects'
}

$manifest = Get-Content -Raw $dependencyManifestPath | ConvertFrom-Json
$mysql = $manifest.mysql_connector_c

foreach ($property in @('version', 'server_header_version', 'architecture', 'library', 'headers', 'provisioning')) {
    if ([string]::IsNullOrWhiteSpace([string]$mysql.$property)) {
        throw "MySQL dependency manifest property is missing or empty: $property"
    }
}

if ($mysql.architecture -ne 'Win32') {
    throw "Legacy MySQL dependency architecture must remain Win32 until the server ABI is migrated explicitly. Manifest value: $($mysql.architecture)"
}

$mysqlHeaders = Join-Path $repoRoot $mysql.headers
$mysqlVersionHeader = Join-Path $mysqlHeaders 'mysql_version.h'
if (-not (Test-Path $mysqlVersionHeader)) {
    throw "Vendored MySQL version header not found: $mysqlVersionHeader"
}

$versionContent = Get-Content -Raw $mysqlVersionHeader
$connectorMatch = [regex]::Match($versionContent, '#define\s+LIBMYSQL_VERSION\s+"([^"]+)"')
$serverMatch = [regex]::Match($versionContent, '#define\s+MYSQL_SERVER_VERSION\s+"([^"]+)"')

if (-not $connectorMatch.Success) {
    throw "LIBMYSQL_VERSION was not found in: $mysqlVersionHeader"
}
if (-not $serverMatch.Success) {
    throw "MYSQL_SERVER_VERSION was not found in: $mysqlVersionHeader"
}

if ($connectorMatch.Groups[1].Value -ne [string]$mysql.version) {
    throw "Vendored MySQL headers do not match manifest Connector/C version. Header=$($connectorMatch.Groups[1].Value) manifest=$($mysql.version)"
}
if ($serverMatch.Groups[1].Value -ne [string]$mysql.server_header_version) {
    throw "Vendored MySQL headers do not match manifest server header version. Header=$($serverMatch.Groups[1].Value) manifest=$($mysql.server_header_version)"
}

Write-Host "MySQL header contract: Connector/C $($mysql.version), server headers $($mysql.server_header_version), $($mysql.architecture)"

$mysqlLibraries = @(Get-ChildItem -Path $repoRoot -Filter ([string]$mysql.library) -File -Recurse -ErrorAction SilentlyContinue)
if ($mysql.provisioning -eq 'external') {
    if ($mysqlLibraries.Count -gt 0) {
        throw "Dependency manifest declares $($mysql.library) as externally provisioned, but a copy is committed in the repository: $($mysqlLibraries[0].FullName)"
    }

    Write-Warning "Full link requires externally provisioned MySQL Connector/C $($mysql.version) $($mysql.architecture) library '$($mysql.library)' through WYD_MYSQL_LIB_DIR."
} elseif ($mysqlLibraries.Count -eq 0) {
    throw "Dependency manifest expects a vendored MySQL library, but '$($mysql.library)' was not found."
} else {
    Write-Host "MySQL client library found: $($mysqlLibraries[0].FullName)"
}

Write-Host 'Legacy preflight completed. Remaining warnings represent explicit, tracked modernization debt.'
