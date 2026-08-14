param(
    [Parameter(Mandatory = $true)]
    [string]$LogPath,

    [int]$TopCodes = 15,
    [int]$TopFiles = 10
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

if (-not (Test-Path $LogPath)) {
    Write-Host "Legacy warning telemetry skipped: log not found at $LogPath"
    exit 0
}

$lines = @(Get-Content -Path $LogPath)
$warnings = @()

foreach ($line in $lines) {
    if ($line -notmatch '(?i)\bwarning\s+([A-Z]+\d+)\s*:') {
        continue
    }

    $code = $Matches[1].ToUpperInvariant()
    $file = '<unknown>'

    if ($line -match '^(.+?)\(\d+(?:,\d+)?\)\s*:\s*warning\s+[A-Z]+\d+\s*:') {
        $file = $Matches[1].Trim()
    }
    elseif ($line -match '^(.+?)\s*:\s*warning\s+[A-Z]+\d+\s*:') {
        $file = $Matches[1].Trim()
    }

    $warnings += [pscustomobject]@{
        Code = $code
        File = $file
    }
}

$total = $warnings.Count
$codeGroups = @(
    $warnings |
        Group-Object Code |
        Sort-Object Count -Descending, Name |
        Select-Object -First $TopCodes
)
$fileGroups = @(
    $warnings |
        Where-Object { $_.File -ne '<unknown>' } |
        Group-Object File |
        Sort-Object Count -Descending, Name |
        Select-Object -First $TopFiles
)

Write-Host "Legacy warning telemetry: total=$total unique_codes=$(@($warnings.Code | Sort-Object -Unique).Count)"
foreach ($group in $codeGroups) {
    Write-Host ("  {0}: {1}" -f $group.Name, $group.Count)
}

if (-not [string]::IsNullOrWhiteSpace($env:GITHUB_STEP_SUMMARY)) {
    Add-Content -Path $env:GITHUB_STEP_SUMMARY -Value '### Legacy compiler warning telemetry'
    Add-Content -Path $env:GITHUB_STEP_SUMMARY -Value ''
    Add-Content -Path $env:GITHUB_STEP_SUMMARY -Value "Total warning occurrences: **$total**"
    Add-Content -Path $env:GITHUB_STEP_SUMMARY -Value ''

    if ($codeGroups.Count -gt 0) {
        Add-Content -Path $env:GITHUB_STEP_SUMMARY -Value '| Warning code | Count |'
        Add-Content -Path $env:GITHUB_STEP_SUMMARY -Value '| --- | ---: |'
        foreach ($group in $codeGroups) {
            Add-Content -Path $env:GITHUB_STEP_SUMMARY -Value ("| `{0}` | {1} |" -f $group.Name, $group.Count)
        }
        Add-Content -Path $env:GITHUB_STEP_SUMMARY -Value ''
    }

    if ($fileGroups.Count -gt 0) {
        Add-Content -Path $env:GITHUB_STEP_SUMMARY -Value 'Top files by warning occurrences:'
        Add-Content -Path $env:GITHUB_STEP_SUMMARY -Value ''
        Add-Content -Path $env:GITHUB_STEP_SUMMARY -Value '| File | Count |'
        Add-Content -Path $env:GITHUB_STEP_SUMMARY -Value '| --- | ---: |'
        foreach ($group in $fileGroups) {
            $displayFile = $group.Name.Replace('|', '\|')
            Add-Content -Path $env:GITHUB_STEP_SUMMARY -Value ("| `{0}` | {1} |" -f $displayFile, $group.Count)
        }
        Add-Content -Path $env:GITHUB_STEP_SUMMARY -Value ''
    }

    Add-Content -Path $env:GITHUB_STEP_SUMMARY -Value '> Informational baseline only. Historical warnings do not fail the build; compile errors and existing safety gates remain blocking.'
}
