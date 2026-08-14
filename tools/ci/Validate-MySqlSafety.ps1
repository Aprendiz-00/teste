$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot '../..')
$sourceFiles = @(
    (Join-Path $repoRoot 'Source/Code/TMSrv/wMySQL.cpp'),
    (Join-Path $repoRoot 'Source/Code/DBSrv/dbMySQL.cpp')
)
$legacyHeaders = @(
    (Join-Path $repoRoot 'Source/Code/TMSrv/wMySQL.h'),
    (Join-Path $repoRoot 'Source/Code/DBSrv/dbMySQL.h')
)
$databaseConfigHeader = Join-Path $repoRoot 'Source/Modern/Platform/Configuration/DatabaseConfig.h'

foreach ($file in $sourceFiles) {
    if (-not (Test-Path $file)) {
        throw "Required MySQL source not found: $file"
    }

    $content = Get-Content -Raw $file

    if ($content -match 'MYSQL_OPT_CONNECT_TIMEOUT\s*,\s*"') {
        throw "MYSQL_OPT_CONNECT_TIMEOUT still receives a string pointer in: $file"
    }

    # Match only a plain local declaration beginning the line. The intended
    # compatibility buffer is explicitly `static thread_local` and must not
    # be rejected by this invariant.
    if ($content -match '(?m)^\s*char\s+res\s*\[\s*1000\s*\]\s*;') {
        throw "wInfo still contains a stack-local result buffer in: $file"
    }

    if ($content -match 'mysql_free_result\s*\(\s*result\s*\)\s*;\s*mysql_close\s*\(\s*wSQL\s*\)') {
        throw "Buffered-result helper still closes wSQL after wRes already closed it in: $file"
    }

    if ($content -notmatch 'static\s+thread_local\s+char\s+res\s*\[\s*1000\s*\]') {
        throw "Expected thread-local compatibility buffer missing in: $file"
    }

    if ($content -notmatch 'LoadFromEnvironment\s*\(') {
        throw "MySQL connection does not load the shared environment configuration in: $file"
    }

    if ($content -match 'mysql_real_connect\s*\(\s*wSQL\s*,\s*HOST\s*,') {
        throw "MySQL connection bypasses the environment-aware configuration in: $file"
    }

    foreach ($field in @('host', 'user', 'password', 'database')) {
        if ($content -notmatch ("config\." + $field + "\.c_str\(\)")) {
            throw "MySQL connection does not use owned config.$field value in: $file"
        }
    }
}

foreach ($file in $legacyHeaders) {
    if (-not (Test-Path $file)) {
        throw "Required MySQL header not found: $file"
    }

    $content = Get-Content -Raw $file
    $passMatch = [regex]::Match($content, '(?m)^\s*#define\s+PASS\s+"([^"]*)"')
    if (-not $passMatch.Success) {
        throw "Expected transitional PASS fallback definition missing in: $file"
    }

    if ($passMatch.Groups[1].Value.Length -ne 0) {
        throw "Hardcoded non-empty MySQL password detected in: $file"
    }
}

if (-not (Test-Path $databaseConfigHeader)) {
    throw "Modern database configuration provider not found: $databaseConfigHeader"
}

$configContent = Get-Content -Raw $databaseConfigHeader
foreach ($name in @('WYD_DB_HOST', 'WYD_DB_USER', 'WYD_DB_PASSWORD', 'WYD_DB_NAME')) {
    if ($configContent -notmatch [regex]::Escape($name)) {
        throw "Expected database environment contract value missing from provider: $name"
    }
}

if ($configContent -notmatch [regex]::Escape('WYD_DB_REQUIRE_ENV')) {
    throw 'Expected strict database environment switch missing from provider: WYD_DB_REQUIRE_ENV'
}

Write-Host 'Legacy MySQL safety and configuration invariants: OK'
