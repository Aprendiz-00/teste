param(
    [ValidateSet('Debug', 'Release')]
    [string]$Configuration = 'Release',

    [ValidateSet('TMSrv', 'DBSrv', 'All')]
    [string]$Project = 'All',

    [switch]$CompileOnly
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

function ConvertTo-GitHubCommandValue {
    param([string]$Value)

    return $Value.Replace('%', '%25').Replace("`r", '%0D').Replace("`n", '%0A')
}

function Publish-BuildDiagnostics {
    param(
        [string]$ProjectName,
        [object[]]$BuildOutput
    )

    $lines = @($BuildOutput | ForEach-Object { $_.ToString() })
    $diagnostics = @(
        $lines |
            Where-Object {
                $_ -match '(?i):\s*(fatal\s+)?error\s+' -or
                $_ -match '(?i)\berror\s+(C\d+|LNK\d+|MSB\d+)'
            } |
            Select-Object -First 20
    )

    if ($diagnostics.Count -eq 0) {
        $diagnostics = @($lines | Select-Object -Last 20)
    }

    foreach ($line in $diagnostics) {
        $escaped = ConvertTo-GitHubCommandValue -Value $line
        Write-Host "::error title=$ProjectName legacy compile::$escaped"
    }

    if (-not [string]::IsNullOrWhiteSpace($env:GITHUB_STEP_SUMMARY)) {
        Add-Content -Path $env:GITHUB_STEP_SUMMARY -Value "### $ProjectName legacy build diagnostics"
        Add-Content -Path $env:GITHUB_STEP_SUMMARY -Value '```text'
        foreach ($line in $diagnostics) {
            Add-Content -Path $env:GITHUB_STEP_SUMMARY -Value $line
        }
        Add-Content -Path $env:GITHUB_STEP_SUMMARY -Value '```'
    }
}

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot '../..')
$sourceRoot = Join-Path $repoRoot 'Source'
$buildRoot = Join-Path $repoRoot "out/legacy/$Configuration"

$vswhere = Join-Path ${env:ProgramFiles(x86)} 'Microsoft Visual Studio/Installer/vswhere.exe'
if (-not (Test-Path $vswhere)) {
    throw "vswhere.exe not found. Install Visual Studio/Build Tools with the Desktop development with C++ workload."
}

$installationPath = & $vswhere -latest -products * -requires Microsoft.Component.MSBuild -property installationPath
if ([string]::IsNullOrWhiteSpace($installationPath)) {
    throw 'Visual Studio installation with MSBuild was not found.'
}

$msbuild = Join-Path $installationPath 'MSBuild/Current/Bin/MSBuild.exe'
if (-not (Test-Path $msbuild)) {
    throw "MSBuild.exe not found at expected path: $msbuild"
}

$projects = @()
if ($Project -eq 'TMSrv' -or $Project -eq 'All') {
    $projects += @{
        Name = 'TMSrv'
        Path = (Join-Path $sourceRoot 'Code/TMSrv/TMSrv.vcxproj')
    }
}
if ($Project -eq 'DBSrv' -or $Project -eq 'All') {
    $projects += @{
        Name = 'DBSrv'
        Path = (Join-Path $sourceRoot 'Code/DBSrv/DBSrv.vcxproj')
    }
}

foreach ($entry in $projects) {
    if (-not (Test-Path $entry.Path)) {
        throw "Legacy project not found: $($entry.Path)"
    }
}

$target = if ($CompileOnly) { 'ClCompile' } else { 'Build' }

$originalLib = $env:LIB
if (-not $CompileOnly) {
    if ([string]::IsNullOrWhiteSpace($env:WYD_MYSQL_LIB_DIR)) {
        throw 'WYD_MYSQL_LIB_DIR must point to the Win32 MySQL Connector library directory for a full legacy link.'
    }

    $mysqlLibrary = Join-Path $env:WYD_MYSQL_LIB_DIR 'libmysql.lib'
    if (-not (Test-Path $mysqlLibrary)) {
        throw "libmysql.lib not found: $mysqlLibrary"
    }

    $env:LIB = if ([string]::IsNullOrWhiteSpace($originalLib)) {
        $env:WYD_MYSQL_LIB_DIR
    } else {
        "$($env:WYD_MYSQL_LIB_DIR);$originalLib"
    }
}

try {
    foreach ($entry in $projects) {
        $outDir = Join-Path $buildRoot "$($entry.Name)/run"
        $intDir = Join-Path $buildRoot "obj/$($entry.Name)"
        New-Item -ItemType Directory -Force -Path $outDir | Out-Null
        New-Item -ItemType Directory -Force -Path $intDir | Out-Null

        Write-Host "[$($entry.Name)] MSBuild target=$target configuration=$Configuration platform=Win32"

        $arguments = @(
            $entry.Path,
            "/t:$target",
            "/p:Configuration=$Configuration",
            '/p:Platform=Win32',
            "/p:OutDir=$outDir\",
            "/p:IntDir=$intDir\",
            '/m',
            '/nologo',
            '/verbosity:minimal'
        )

        $buildOutput = @(& $msbuild @arguments 2>&1)
        $exitCode = $LASTEXITCODE

        foreach ($line in $buildOutput) {
            Write-Host $line
        }

        if ($exitCode -ne 0) {
            Publish-BuildDiagnostics -ProjectName $entry.Name -BuildOutput $buildOutput
            throw "MSBuild failed for $($entry.Name) with exit code $exitCode."
        }
    }
}
finally {
    $env:LIB = $originalLib
}

if ($CompileOnly) {
    Write-Host 'Legacy compile-only gate completed. Linking was intentionally skipped.'
} else {
    Write-Host 'Legacy build completed.'
}
