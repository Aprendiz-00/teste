$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot '../..')
$tmRoot = Join-Path $repoRoot 'Source/Code/TMSrv'
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)

# DropControl contains a local variable whose historical Portuguese identifier
# is rejected by MSVC. The CI checkout is disposable, so normalize only the
# identifier spelling while preserving the variable's behavior and scope.
$dropPath = Join-Path $tmRoot 'DropControl.cpp'
$dropText = [System.IO.File]::ReadAllText($dropPath, [System.Text.Encoding]::UTF8)
$dropText = $dropText.Replace('ItensEvolução', 'ItensEvolucao')
[System.IO.File]::WriteAllText($dropPath, $dropText, $utf8NoBom)

# Visual Studio's #pragma region label is non-semantic, but MSVC rejects some
# legacy accented labels before semantic analysis. Normalize labels only.
$mobKilledPath = Join-Path $tmRoot 'MobKilled.cpp'
$mobLines = [System.IO.File]::ReadAllLines($mobKilledPath, [System.Text.Encoding]::UTF8)
for ($i = 0; $i -lt $mobLines.Length; $i++) {
    $trimmed = $mobLines[$i].TrimStart()
    if ($trimmed.StartsWith('#pragma region')) {
        $indentLength = $mobLines[$i].Length - $trimmed.Length
        $indent = if ($indentLength -gt 0) { $mobLines[$i].Substring(0, $indentLength) } else { '' }
        $mobLines[$i] = $indent + '#pragma region LegacyRegion'
    }
}
[System.IO.File]::WriteAllLines($mobKilledPath, $mobLines, $utf8NoBom)

Write-Host 'Ephemeral legacy CI source normalization completed.'
