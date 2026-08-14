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
    param([string]$ProjectName, [object[]]$BuildOutput)

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
        Write-Host "::error title=$ProjectName legacy compile::$(ConvertTo-GitHubCommandValue $line)"
    }

    if (-not [string]::IsNullOrWhiteSpace($env:GITHUB_STEP_SUMMARY)) {
        Add-Content $env:GITHUB_STEP_SUMMARY "### $ProjectName legacy build diagnostics"
        Add-Content $env:GITHUB_STEP_SUMMARY '```text'
        $diagnostics | ForEach-Object { Add-Content $env:GITHUB_STEP_SUMMARY $_ }
        Add-Content $env:GITHUB_STEP_SUMMARY '```'
    }
}

function New-CompatibilityProjectCopy {
    param([string]$ProjectPath, [string]$ProjectName)

    if ($ProjectName -ne 'TMSrv') {
        return $ProjectPath
    }

    [xml]$projectXml = Get-Content -Raw $ProjectPath
    $namespace = $projectXml.Project.NamespaceURI
    $manager = New-Object System.Xml.XmlNamespaceManager($projectXml.NameTable)
    $manager.AddNamespace('msb', $namespace)

    $baseDefNode = $projectXml.SelectSingleNode("//msb:ClCompile[@Include='..\Basedef.cpp']", $manager)
    if ($null -eq $baseDefNode) {
        throw 'Unable to find Basedef.cpp in TMSrv project while preparing compatibility metadata.'
    }

    $additionalOptions = $projectXml.CreateElement('AdditionalOptions', $namespace)
    $additionalOptions.InnerText = '/source-charset:.1252 %(AdditionalOptions)'
    [void]$baseDefNode.AppendChild($additionalOptions)

    $temporaryPath = Join-Path (Split-Path $ProjectPath -Parent) 'TMSrv.ci.vcxproj'
    $projectXml.Save($temporaryPath)

    Write-Host '[TMSrv] Basedef.cpp uses source charset 1252 in the clean-runner compatibility project.'
    return $temporaryPath
}

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot '../..')
$sourceRoot = Join-Path $repoRoot 'Source'
$buildRoot = Join-Path $repoRoot "out/legacy/$Configuration"
$mysqlIncludeDir = Join-Path $sourceRoot 'Code/include_mysql'

if (-not (Test-Path (Join-Path $mysqlIncludeDir 'mysql.h'))) {
    throw "Vendored MySQL headers not found at: $mysqlIncludeDir"
}

$vswhere = Join-Path ${env:ProgramFiles(x86)} 'Microsoft Visual Studio/Installer/vswhere.exe'
if (-not (Test-Path $vswhere)) {
    throw 'vswhere.exe not found. Install Visual Studio/Build Tools with the C++ workload.'
}

$installationPath = & $vswhere -latest -products * -requires Microsoft.Component.MSBuild -property installationPath
if ([string]::IsNullOrWhiteSpace($installationPath)) {
    throw 'Visual Studio installation with MSBuild was not found.'
}

$msbuild = Join-Path $installationPath 'MSBuild/Current/Bin/MSBuild.exe'
if (-not (Test-Path $msbuild)) {
    throw "MSBuild.exe not found: $msbuild"
}

$projects = @()
if ($Project -eq 'TMSrv' -or $Project -eq 'All') {
    $projects += @{ Name = 'TMSrv'; Path = (Join-Path $sourceRoot 'Code/TMSrv/TMSrv.vcxproj') }
}
if ($Project -eq 'DBSrv' -or $Project -eq 'All') {
    $projects += @{ Name = 'DBSrv'; Path = (Join-Path $sourceRoot 'Code/DBSrv/DBSrv.vcxproj') }
}

foreach ($entry in $projects) {
    if (-not (Test-Path $entry.Path)) {
        throw "Legacy project not found: $($entry.Path)"
    }
}

$target = if ($CompileOnly) { 'ClCompile' } else { 'Build' }
$originalLib = $env:LIB
$originalInclude = $env:INCLUDE
$originalCl = $env:CL
$temporaryProjects = @()

$env:INCLUDE = if ([string]::IsNullOrWhiteSpace($originalInclude)) {
    $mysqlIncludeDir
} else {
    "$mysqlIncludeDir;$originalInclude"
}

# Most active source files are UTF-8. A small amount of historical common code
# still uses a legacy codepage; the temporary MSBuild compatibility project
# applies a per-file source charset only to that known translation unit.
$requiredCompilerOptions = "/std:c++17 /utf-8 /I`"$mysqlIncludeDir`""
$env:CL = if ([string]::IsNullOrWhiteSpace($originalCl)) {
    $requiredCompilerOptions
} else {
    "$requiredCompilerOptions $originalCl"
}

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
        $projectPath = New-CompatibilityProjectCopy -ProjectPath $entry.Path -ProjectName $entry.Name
        if ($projectPath -ne $entry.Path) {
            $temporaryProjects += $projectPath
        }

        $outDir = Join-Path $buildRoot "$($entry.Name)/run"
        $intDir = Join-Path $buildRoot "obj/$($entry.Name)"
        New-Item -ItemType Directory -Force -Path $outDir | Out-Null
        New-Item -ItemType Directory -Force -Path $intDir | Out-Null

        Write-Host "[$($entry.Name)] target=$target configuration=$Configuration platform=Win32"
        Write-Host "[$($entry.Name)] MySQL include root: $mysqlIncludeDir"
        Write-Host "[$($entry.Name)] compiler options: $requiredCompilerOptions"

        $arguments = @(
            $projectPath,
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
        $buildOutput | ForEach-Object { Write-Host $_ }

        if ($exitCode -ne 0) {
            Publish-BuildDiagnostics -ProjectName $entry.Name -BuildOutput $buildOutput
            throw "MSBuild failed for $($entry.Name) with exit code $exitCode."
        }
    }
}
finally {
    $env:LIB = $originalLib
    $env:INCLUDE = $originalInclude
    $env:CL = $originalCl

    foreach ($temporaryProject in $temporaryProjects) {
        Remove-Item -Force $temporaryProject -ErrorAction SilentlyContinue
    }
}

if ($CompileOnly) {
    Write-Host 'Legacy compile-only gate completed. Linking was intentionally skipped.'
} else {
    Write-Host 'Legacy build completed.'
}
