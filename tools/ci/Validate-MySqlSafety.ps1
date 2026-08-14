$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot '../..')
$files = @(
    (Join-Path $repoRoot 'Source/Code/TMSrv/wMySQL.cpp'),
    (Join-Path $repoRoot 'Source/Code/DBSrv/dbMySQL.cpp')
)

foreach ($file in $files) {
    if (-not (Test-Path $file)) {
        throw "Required MySQL source not found: $file"
    }

    $content = Get-Content -Raw $file

    if ($content -match 'MYSQL_OPT_CONNECT_TIMEOUT\s*,\s*"') {
        throw "MYSQL_OPT_CONNECT_TIMEOUT still receives a string pointer in: $file"
    }

    if ($content -match 'char\s+res\s*\[\s*1000\s*\]\s*;') {
        throw "wInfo still contains a stack-local result buffer in: $file"
    }

    if ($content -match 'mysql_free_result\s*\(\s*result\s*\)\s*;\s*mysql_close\s*\(\s*wSQL\s*\)') {
        throw "Buffered-result helper still closes wSQL after wRes already closed it in: $file"
    }

    if ($content -notmatch 'static\s+thread_local\s+char\s+res\s*\[\s*1000\s*\]') {
        throw "Expected thread-local compatibility buffer missing in: $file"
    }
}

Write-Host 'Legacy MySQL safety invariants: OK'
