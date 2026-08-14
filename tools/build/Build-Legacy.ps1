param(
    [ValidateSet('Debug', 'Release')]
    [string]$Configuration = 'Release',
    [ValidateSet('TMSrv', 'DBSrv', 'All')]
    [string]$Project = 'All',
    [switch]$CompileOnly
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

function ConvertTo-GitHubCommandValue([string]$Value) {
    $Value.Replace('%', '%25').Replace("`r", '%0D').Replace("`n", '%0A')
}

function Publish-BuildDiagnostics([string]$ProjectName, [object[]]$BuildOutput) {
    $lines = @($BuildOutput | ForEach-Object { $_.ToString() })
    $diagnostics = @($lines | Where-Object {
        $_ -match '(?i):\s*(fatal\s+)?error\s+' -or $_ -match '(?i)\berror\s+(C\d+|LNK\d+|MSB\d+)'
    } | Select-Object -First 20)
    if ($diagnostics.Count -eq 0) { $diagnostics = @($lines | Select-Object -Last 20) }
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

function New-BasedefCompatibilityCopy([string]$SourcePath) {
    $targetLine = 6224
    $bytes = [System.IO.File]::ReadAllBytes($SourcePath)
    $lineNumber = 1
    $lineStart = 0
    $lineEnd = -1

    for ($i = 0; $i -lt $bytes.Length; $i++) {
        if ($lineNumber -eq $targetLine -and $bytes[$i] -eq 10) {
            $lineEnd = $i
            break
        }
        if ($bytes[$i] -eq 10) {
            $lineNumber++
            $lineStart = $i + 1
        }
    }

    if ($lineEnd -lt 0 -or $lineNumber -ne $targetLine) {
        throw "Unable to locate Basedef.cpp line $targetLine for compatibility sanitization."
    }

    $replacement = [System.Text.Encoding]::ASCII.GetBytes("`t`t`tMessageBox(NULL, temp, `"Effect.h define value is not numeric or outside the valid range`", MB_OK);")
    $temporaryPath = Join-Path (Split-Path $SourcePath -Parent) 'Basedef.ci.cpp'
    $stream = New-Object System.IO.MemoryStream
    try {
        $stream.Write($bytes, 0, $lineStart)
        $stream.Write($replacement, 0, $replacement.Length)
        $stream.WriteByte(10)
        $suffixStart = $lineEnd + 1
        if ($suffixStart -lt $bytes.Length) {
            $stream.Write($bytes, $suffixStart, $bytes.Length - $suffixStart)
        }
        [System.IO.File]::WriteAllBytes($temporaryPath, $stream.ToArray())
    }
    finally {
        $stream.Dispose()
    }

    Write-Host '[legacy] generated Basedef.ci.cpp with one diagnostics-only string normalized to ASCII.'
    return $temporaryPath
}

function New-CompatibilityProjectCopy([string]$ProjectPath, [string]$ProjectName, [string]$BasedefCompatibilityPath) {
    [xml]$projectXml = Get-Content -Raw $ProjectPath
    $namespace = $projectXml.Project.NamespaceURI
    $manager = New-Object System.Xml.XmlNamespaceManager($projectXml.NameTable)
    $manager.AddNamespace('msb', $namespace)
    $compileNodes = @($projectXml.SelectNodes('//msb:ClCompile', $manager))
    if ($compileNodes.Count -eq 0) { throw "No ClCompile items found in $ProjectName." }

    foreach ($node in $compileNodes) {
        $include = $node.GetAttribute('Include')
        $sourceCharset = 'utf-8'
        if ($include -eq '..\Basedef.cpp') {
            $node.SetAttribute('Include', '..\Basedef.ci.cpp')
            $sourceCharset = '949'
        }
        $options = $projectXml.CreateElement('AdditionalOptions', $namespace)
        $options.InnerText = "/source-charset:$sourceCharset %(AdditionalOptions)"
        [void]$node.AppendChild($options)
    }

    $temporaryPath = Join-Path (Split-Path $ProjectPath -Parent) "$ProjectName.ci.vcxproj"
    $projectXml.Save($temporaryPath)
    Write-Host "[$ProjectName] generated compatibility project with explicit source charsets."
    return $temporaryPath
}

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot '../..')
$sourceRoot = Join-Path $repoRoot 'Source'
$buildRoot = Join-Path $repoRoot "out/legacy/$Configuration"
$mysqlIncludeDir = Join-Path $sourceRoot 'Code/include_mysql'
$basedefPath = Join-Path $sourceRoot 'Code/Basedef.cpp'
if (-not (Test-Path (Join-Path $mysqlIncludeDir 'mysql.h'))) { throw "Vendored MySQL headers not found: $mysqlIncludeDir" }
if (-not (Test-Path $basedefPath)) { throw "Basedef.cpp not found: $basedefPath" }

$vswhere = Join-Path ${env:ProgramFiles(x86)} 'Microsoft Visual Studio/Installer/vswhere.exe'
if (-not (Test-Path $vswhere)) { throw 'vswhere.exe not found.' }
$installationPath = & $vswhere -latest -products * -requires Microsoft.Component.MSBuild -property installationPath
if ([string]::IsNullOrWhiteSpace($installationPath)) { throw 'Visual Studio/MSBuild was not found.' }
$msbuild = Join-Path $installationPath 'MSBuild/Current/Bin/MSBuild.exe'
if (-not (Test-Path $msbuild)) { throw "MSBuild.exe not found: $msbuild" }

$projects = @()
if ($Project -eq 'TMSrv' -or $Project -eq 'All') { $projects += @{ Name='TMSrv'; Path=(Join-Path $sourceRoot 'Code/TMSrv/TMSrv.vcxproj') } }
if ($Project -eq 'DBSrv' -or $Project -eq 'All') { $projects += @{ Name='DBSrv'; Path=(Join-Path $sourceRoot 'Code/DBSrv/DBSrv.vcxproj') } }
foreach ($entry in $projects) { if (-not (Test-Path $entry.Path)) { throw "Legacy project not found: $($entry.Path)" } }

$target = if ($CompileOnly) { 'ClCompile' } else { 'Build' }
$originalLib = $env:LIB
$originalInclude = $env:INCLUDE
$originalCl = $env:CL
$temporaryProjects = @()
$basedefCompatibilityPath = $null

$env:INCLUDE = if ([string]::IsNullOrWhiteSpace($originalInclude)) { $mysqlIncludeDir } else { "$mysqlIncludeDir;$originalInclude" }
$requiredCompilerOptions = "/std:c++17 /execution-charset:utf-8 /I`"$mysqlIncludeDir`""
$env:CL = if ([string]::IsNullOrWhiteSpace($originalCl)) { $requiredCompilerOptions } else { "$requiredCompilerOptions $originalCl" }

if (-not $CompileOnly) {
    if ([string]::IsNullOrWhiteSpace($env:WYD_MYSQL_LIB_DIR)) { throw 'WYD_MYSQL_LIB_DIR is required for a full legacy link.' }
    $mysqlLibrary = Join-Path $env:WYD_MYSQL_LIB_DIR 'libmysql.lib'
    if (-not (Test-Path $mysqlLibrary)) { throw "libmysql.lib not found: $mysqlLibrary" }
    $env:LIB = if ([string]::IsNullOrWhiteSpace($originalLib)) { $env:WYD_MYSQL_LIB_DIR } else { "$($env:WYD_MYSQL_LIB_DIR);$originalLib" }
}

try {
    $basedefCompatibilityPath = New-BasedefCompatibilityCopy $basedefPath
    foreach ($entry in $projects) {
        $projectPath = New-CompatibilityProjectCopy $entry.Path $entry.Name $basedefCompatibilityPath
        $temporaryProjects += $projectPath
        $outDir = Join-Path $buildRoot "$($entry.Name)/run"
        $intDir = Join-Path $buildRoot "obj/$($entry.Name)"
        New-Item -ItemType Directory -Force -Path $outDir,$intDir | Out-Null
        Write-Host "[$($entry.Name)] target=$target config=$Configuration platform=Win32"
        $arguments = @($projectPath, "/t:$target", "/p:Configuration=$Configuration", '/p:Platform=Win32', "/p:OutDir=$outDir\", "/p:IntDir=$intDir\", '/m', '/nologo', '/verbosity:minimal')
        $buildOutput = @(& $msbuild @arguments 2>&1)
        $exitCode = $LASTEXITCODE
        $buildOutput | ForEach-Object { Write-Host $_ }
        if ($exitCode -ne 0) {
            Publish-BuildDiagnostics $entry.Name $buildOutput
            throw "MSBuild failed for $($entry.Name) with exit code $exitCode."
        }
    }
}
finally {
    $env:LIB = $originalLib; $env:INCLUDE = $originalInclude; $env:CL = $originalCl
    foreach ($temporaryProject in $temporaryProjects) { Remove-Item -Force $temporaryProject -ErrorAction SilentlyContinue }
    if ($null -ne $basedefCompatibilityPath) { Remove-Item -Force $basedefCompatibilityPath -ErrorAction SilentlyContinue }
}

if ($CompileOnly) { Write-Host 'Legacy compile-only gate completed; link intentionally skipped.' } else { Write-Host 'Legacy build completed.' }
