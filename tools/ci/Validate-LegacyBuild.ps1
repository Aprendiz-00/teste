$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot '../..')
$solution = Join-Path $repoRoot 'Source/The New World.sln'
$tmProject = Join-Path $repoRoot 'Source/Code/TMSrv/TMSrv.vcxproj'
$dbProject = Join-Path $repoRoot 'Source/Code/DBSrv/DBSrv.vcxproj'

$required = @($solution, $tmProject, $dbProject)
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
    Write-Warning ('Legacy projects still contain machine-specific absolute paths: ' + (($absolutePathHits | Sort-Object -Unique) -join ', '))
} else {
    Write-Host 'Machine-specific paths: none detected in TMSrv/DBSrv projects'
}

$mysqlLib = Get-ChildItem -Path $repoRoot -Filter 'libmysql.lib' -File -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
if ($null -eq $mysqlLib) {
    Write-Warning 'libmysql.lib is not vendored. Full legacy build still requires an externally provisioned MySQL client library.'
} else {
    Write-Host "MySQL client library found: $($mysqlLib.FullName)"
}

$hardcodedDbHeaders = @(
    (Join-Path $repoRoot 'Source/Code/TMSrv/wMySQL.h'),
    (Join-Path $repoRoot 'Source/Code/DBSrv/dbMySQL.h')
)

foreach ($header in $hardcodedDbHeaders) {
    if (Test-Path $header) {
        $content = Get-Content -Raw $header
        if ($content -match '#define\s+(HOST|USER|PASS|DB|PORT)') {
            Write-Warning "Hardcoded database configuration remains in legacy header: $header"
        }
    }
}

Write-Host 'Legacy preflight completed. Warnings represent tracked modernization debt and are intentionally non-blocking in Foundation.'
