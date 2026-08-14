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

function Replace-LineBytes([string]$SourcePath, [string]$DestinationPath, [int]$TargetLine, [string]$Replacement) {
    $bytes = [System.IO.File]::ReadAllBytes($SourcePath)
    $lineNumber = 1; $lineStart = 0; $lineEnd = -1
    for ($i = 0; $i -lt $bytes.Length; $i++) {
        if ($lineNumber -eq $TargetLine -and $bytes[$i] -eq 10) { $lineEnd = $i; break }
        if ($bytes[$i] -eq 10) { $lineNumber++; $lineStart = $i + 1 }
    }
    if ($lineEnd -lt 0 -or $lineNumber -ne $TargetLine) { throw "Unable to locate $SourcePath line $TargetLine." }

    $replacementBytes = [System.Text.Encoding]::ASCII.GetBytes($Replacement)
    $stream = New-Object System.IO.MemoryStream
    try {
        $stream.Write($bytes, 0, $lineStart)
        $stream.Write($replacementBytes, 0, $replacementBytes.Length)
        $stream.WriteByte(10)
        $suffixStart = $lineEnd + 1
        if ($suffixStart -lt $bytes.Length) { $stream.Write($bytes, $suffixStart, $bytes.Length - $suffixStart) }
        [System.IO.File]::WriteAllBytes($DestinationPath, $stream.ToArray())
    } finally { $stream.Dispose() }
}

function New-BasedefCompatibilityCopy([string]$SourcePath) {
    $destination = Join-Path (Split-Path $SourcePath -Parent) 'Basedef.ci.cpp'
    Replace-LineBytes $SourcePath $destination 6224 "`t`t`tMessageBox(NULL, temp, `"Effect.h define value is not numeric or outside the valid range`", MB_OK);"
    Write-Host '[legacy] Basedef.ci.cpp: normalized one corrupted diagnostic string.'
    return $destination
}

function New-CNPCGeneCompatibilityCopy([string]$SourcePath) {
    $destination = Join-Path (Split-Path $SourcePath -Parent) 'CNPCGene.ci.cpp'
    $lines = [System.IO.File]::ReadAllLines($SourcePath, [System.Text.Encoding]::UTF8)
    if ($lines.Length -lt 120) { throw 'CNPCGene.cpp is shorter than expected.' }
    $lines[52] = "`t`tMessageBoxA(hWndMain, `"NPCGener.txt not found`", `"Boot error`", MB_OK);"
    for ($i = 0; $i -lt $lines.Length; $i++) {
        $lines[$i] = $lines[$i].Replace("tmp1[0] != 'Í'", "static_cast<unsigned char>(tmp1[0]) != 0xCD")
    }
    [System.IO.File]::WriteAllLines($destination, $lines, (New-Object System.Text.UTF8Encoding($false)))
    Write-Host '[legacy] CNPCGene.ci.cpp: normalized corrupted diagnostic/byte literals.'
    return $destination
}

function New-CastleZakumCompatibilityCopy([string]$SourcePath) {
    $destination = Join-Path (Split-Path $SourcePath -Parent) 'CCastleZakum.ci.cpp'
    $lines = [System.IO.File]::ReadAllLines($SourcePath, [System.Text.Encoding]::UTF8)
    for ($i = 0; $i -lt $lines.Length; $i++) {
        if ($lines[$i].TrimStart().StartsWith('#pragma region')) {
            $indent = $lines[$i].Substring(0, $lines[$i].Length - $lines[$i].TrimStart().Length)
            $lines[$i] = $indent + '#pragma region LegacyRegion'
        }
    }
    [System.IO.File]::WriteAllLines($destination, $lines, (New-Object System.Text.UTF8Encoding($false)))
    Write-Host '[legacy] CCastleZakum.ci.cpp: normalized non-semantic pragma region labels.'
    return $destination
}

function New-CompatibilityProjectCopy([string]$ProjectPath, [string]$ProjectName) {
    [xml]$projectXml = Get-Content -Raw $ProjectPath
    $namespace = $projectXml.Project.NamespaceURI
    $manager = New-Object System.Xml.XmlNamespaceManager($projectXml.NameTable)
    $manager.AddNamespace('msb', $namespace)
    $compileNodes = @($projectXml.SelectNodes('//msb:ClCompile', $manager))
    if ($compileNodes.Count -eq 0) { throw "No ClCompile items found in $ProjectName." }

    foreach ($node in $compileNodes) {
        $include = $node.GetAttribute('Include')
        $sourceCharset = 'utf-8'
        switch ($include) {
            '..\Basedef.cpp' { $node.SetAttribute('Include', '..\Basedef.ci.cpp'); $sourceCharset = '949' }
            'CNPCGene.cpp' { $node.SetAttribute('Include', 'CNPCGene.ci.cpp') }
            'CCastleZakum.cpp' { $node.SetAttribute('Include', 'CCastleZakum.ci.cpp') }
        }
        $options = $projectXml.CreateElement('AdditionalOptions', $namespace)
        $options.InnerText = "/source-charset:$sourceCharset %(AdditionalOptions)"
        [void]$node.AppendChild($options)
    }

    $temporaryPath = Join-Path (Split-Path $ProjectPath -Parent) "$ProjectName.ci.vcxproj"
    $projectXml.Save($temporaryPath)
    return $temporaryPath
}

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot '../..')
$sourceRoot = Join-Path $repoRoot 'Source'
$codeRoot = Join-Path $sourceRoot 'Code'
$buildRoot = Join-Path $repoRoot "out/legacy/$Configuration"
$mysqlIncludeDir = Join-Path $codeRoot 'include_mysql'
if (-not (Test-Path (Join-Path $mysqlIncludeDir 'mysql.h'))) { throw "Vendored MySQL headers not found: $mysqlIncludeDir" }

$vswhere = Join-Path ${env:ProgramFiles(x86)} 'Microsoft Visual Studio/Installer/vswhere.exe'
if (-not (Test-Path $vswhere)) { throw 'vswhere.exe not found.' }
$installationPath = & $vswhere -latest -products * -requires Microsoft.Component.MSBuild -property installationPath
if ([string]::IsNullOrWhiteSpace($installationPath)) { throw 'Visual Studio/MSBuild was not found.' }
$msbuild = Join-Path $installationPath 'MSBuild/Current/Bin/MSBuild.exe'

$projects = @()
if ($Project -eq 'TMSrv' -or $Project -eq 'All') { $projects += @{ Name='TMSrv'; Path=(Join-Path $codeRoot 'TMSrv/TMSrv.vcxproj') } }
if ($Project -eq 'DBSrv' -or $Project -eq 'All') { $projects += @{ Name='DBSrv'; Path=(Join-Path $codeRoot 'DBSrv/DBSrv.vcxproj') } }

$target = if ($CompileOnly) { 'ClCompile' } else { 'Build' }
$originalLib = $env:LIB; $originalInclude = $env:INCLUDE; $originalCl = $env:CL
$temporaryPaths = @()
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
    $temporaryPaths += New-BasedefCompatibilityCopy (Join-Path $codeRoot 'Basedef.cpp')
    $temporaryPaths += New-CNPCGeneCompatibilityCopy (Join-Path $codeRoot 'TMSrv/CNPCGene.cpp')
    $temporaryPaths += New-CastleZakumCompatibilityCopy (Join-Path $codeRoot 'TMSrv/CCastleZakum.cpp')

    foreach ($entry in $projects) {
        $projectPath = New-CompatibilityProjectCopy $entry.Path $entry.Name
        $temporaryPaths += $projectPath
        $outDir = Join-Path $buildRoot "$($entry.Name)/run"
        $intDir = Join-Path $buildRoot "obj/$($entry.Name)"
        New-Item -ItemType Directory -Force -Path $outDir,$intDir | Out-Null
        $arguments = @($projectPath, "/t:$target", "/p:Configuration=$Configuration", '/p:Platform=Win32', "/p:OutDir=$outDir\", "/p:IntDir=$intDir\", '/m', '/nologo', '/verbosity:minimal')
        $buildOutput = @(& $msbuild @arguments 2>&1); $exitCode = $LASTEXITCODE
        $buildOutput | ForEach-Object { Write-Host $_ }
        if ($exitCode -ne 0) { Publish-BuildDiagnostics $entry.Name $buildOutput; throw "MSBuild failed for $($entry.Name) with exit code $exitCode." }
    }
}
finally {
    $env:LIB = $originalLib; $env:INCLUDE = $originalInclude; $env:CL = $originalCl
    foreach ($path in $temporaryPaths) { Remove-Item -Force $path -ErrorAction SilentlyContinue }
}

if ($CompileOnly) { Write-Host 'Legacy compile-only gate completed; link intentionally skipped.' } else { Write-Host 'Legacy build completed.' }
