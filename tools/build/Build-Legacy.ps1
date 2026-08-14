param(
    [ValidateSet('Debug', 'Release')]
    [string]$Configuration = 'Release',

    [ValidateSet('TMSrv', 'DBSrv', 'All')]
    [string]$Project = 'All',

    [switch]$CompileOnly
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

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

        & $msbuild @arguments
        if ($LASTEXITCODE -ne 0) {
            throw "MSBuild failed for $($entry.Name) with exit code $LASTEXITCODE."
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
