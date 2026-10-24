[CmdletBinding()]
param([switch]$SkipValidation, [switch]$SkipBuild, [string]$InnoCompilerPath)
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$repoRoot = Split-Path -Parent $PSScriptRoot
Set-Location -LiteralPath $repoRoot
$assetVerifier = Join-Path $repoRoot 'tool/windows/verify_assets.ps1'
$sourceAssets = Join-Path $repoRoot 'assets'
& $assetVerifier -AssetsDirectory $sourceAssets
$pubspec = Get-Content -LiteralPath (Join-Path $repoRoot 'pubspec.yaml') -Raw -Encoding UTF8
$fullVersion = ([regex]::Match($pubspec, '(?m)^version:\s*(\S+)')).Groups[1].Value
$version = ($fullVersion -split '\+')[0]
if ($version -notmatch '^\d+\.\d+\.\d+$') { throw 'Could not read application version.' }
$python = Get-Command python -ErrorAction SilentlyContinue
if (-not $python) { throw 'Python 3 is required for the generated-version check.' }
& $python.Source -X utf8 (Join-Path $repoRoot 'tool/generate_app_version.py') --check
if ($LASTEXITCODE -ne 0) { throw 'Generated app version is stale.' }
$flutter = Get-Command flutter -ErrorAction SilentlyContinue
if (-not $flutter) { throw 'Flutter is not on PATH.' }
if (-not $SkipValidation) {
    & $flutter.Source pub get --enforce-lockfile
    if ($LASTEXITCODE -ne 0) { throw 'flutter pub get failed.' }
    & $flutter.Source analyze --no-pub
    if ($LASTEXITCODE -ne 0) { throw 'flutter analyze failed.' }
    & $flutter.Source test --no-pub
    if ($LASTEXITCODE -ne 0) { throw 'flutter test failed.' }
}
if (-not $SkipBuild) {
    & $flutter.Source build windows --release --no-pub `
        --dart-define=UPDATE_MANIFEST_URL=https://api.github.com/repos/chensuhandsome/Particle-Library-windows/releases/latest
    if ($LASTEXITCODE -ne 0) { throw 'Windows release build failed.' }
}
$buildDir = Join-Path $repoRoot 'build/windows/x64/runner/Release'
$requiredFiles = @(
    'ParticleLibrary.exe', 'flutter_windows.dll', 'pdfium.dll', 'sqlite3.dll',
    'sqlite3_flutter_libs_plugin.dll', 'data/app.so', 'data/icudtl.dat',
    'data/flutter_assets/NOTICES.Z', 'data/flutter_assets/NativeAssetsManifest.json'
)
foreach ($relativePath in $requiredFiles) {
    if (-not (Test-Path -LiteralPath (Join-Path $buildDir $relativePath) -PathType Leaf)) {
        throw "Missing runtime file: $relativePath"
    }
}
$binaryVersion = (Get-Item -LiteralPath (Join-Path $buildDir 'ParticleLibrary.exe')).VersionInfo.ProductVersion
if ($binaryVersion -ne $fullVersion) { throw "Stale Windows build: $binaryVersion (expected $fullVersion)." }
# Validate the generated native-asset list: 0.3.1 has no gate DLL, while later
# PDFium stacks do. Every packaged native asset must remain relocatable.
$nativeManifest = Get-Content -LiteralPath (Join-Path $buildDir 'data/flutter_assets/NativeAssetsManifest.json') -Raw -Encoding UTF8 | ConvertFrom-Json
foreach ($asset in $nativeManifest.'native-assets'.windows_x64.PSObject.Properties) {
    $record = @($asset.Value)
    if ($record[0] -ne 'absolute') { continue }
    $relative = [string]$record[1]
    if ([System.IO.Path]::IsPathRooted($relative) -or $relative -ne [System.IO.Path]::GetFileName($relative)) {
        throw "Non-relocatable native asset: $relative"
    }
    if (-not (Test-Path -LiteralPath (Join-Path $buildDir $relative) -PathType Leaf)) {
        throw "Missing native asset: $relative"
    }
}
& $assetVerifier -AssetsDirectory (Join-Path $buildDir 'data/flutter_assets/assets') -ReferenceAssetsDirectory $sourceAssets
$distDir = [System.IO.Path]::GetFullPath((Join-Path $repoRoot 'dist/release'))
$stageDir = [System.IO.Path]::GetFullPath((Join-Path $distDir 'Particle-Library-Windows-x64'))
function Assert-SafeStagingPath {
    $expected = [System.IO.Path]::GetFullPath((Join-Path $distDir 'Particle-Library-Windows-x64'))
    $prefix = $distDir.TrimEnd('\', '/') + [System.IO.Path]::DirectorySeparatorChar
    if ($stageDir -ne $expected -or -not $stageDir.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase)) {
        throw "Unsafe staging directory: $stageDir"
    }
    foreach ($path in @((Join-Path $repoRoot 'dist'), $distDir, $stageDir)) {
        if ((Test-Path -LiteralPath $path) -and
            ((Get-Item -LiteralPath $path -Force).Attributes -band [System.IO.FileAttributes]::ReparsePoint)) {
            throw "Refusing to stage through a reparse point: $path"
        }
    }
}
Assert-SafeStagingPath
[System.IO.Directory]::CreateDirectory($distDir) | Out-Null
if (Test-Path -LiteralPath $stageDir) { Remove-Item -LiteralPath $stageDir -Recurse -Force }
[System.IO.Directory]::CreateDirectory($stageDir) | Out-Null
Get-ChildItem -LiteralPath $buildDir | Copy-Item -Destination $stageDir -Recurse -Force
Copy-Item -LiteralPath (Join-Path $repoRoot 'LICENSE') -Destination $stageDir
Copy-Item -LiteralPath (Join-Path $repoRoot 'THIRD_PARTY_NOTICES.md') -Destination $stageDir
Copy-Item -LiteralPath (Join-Path $repoRoot 'tool/windows/README.txt') -Destination (Join-Path $stageDir 'README.txt')
Copy-Item -LiteralPath (Join-Path $repoRoot 'windows/runner/resources/app_icon.ico') -Destination (Join-Path $stageDir 'app_icon.ico')
& $assetVerifier -AssetsDirectory (Join-Path $stageDir 'data/flutter_assets/assets') -ReferenceAssetsDirectory $sourceAssets
$portableZip = Join-Path $distDir "Particle-Library-$version-Windows-x64-Portable.zip"
$installer = Join-Path $distDir "Particle-Library-$version-Windows-x64-Setup.exe"
$checksums = Join-Path $distDir 'SHA256SUMS.txt'
# Preserve older release artifacts. Only replace the files for this version.
foreach ($artifact in @($portableZip, $installer, $checksums)) {
    if (Test-Path -LiteralPath $artifact) { Remove-Item -LiteralPath $artifact -Force }
}
Add-Type -AssemblyName System.IO.Compression.FileSystem
[System.IO.Compression.ZipFile]::CreateFromDirectory($stageDir, $portableZip, [System.IO.Compression.CompressionLevel]::Optimal, $true)
if (-not $InnoCompilerPath) {
    $innoCommand = Get-Command ISCC.exe -ErrorAction SilentlyContinue
    if ($innoCommand) { $InnoCompilerPath = $innoCommand.Source }
}
if (-not $InnoCompilerPath) {
    $innoCandidates = @(
        (Join-Path $env:LOCALAPPDATA 'Programs/Inno Setup 6/ISCC.exe'),
        (Join-Path ${env:ProgramFiles(x86)} 'Inno Setup 6/ISCC.exe'),
        (Join-Path $env:ProgramFiles 'Inno Setup 6/ISCC.exe')
    )
    $InnoCompilerPath = $innoCandidates | Where-Object { Test-Path -LiteralPath $_ -PathType Leaf } | Select-Object -First 1
}
if (-not $InnoCompilerPath) { throw 'Inno Setup 6 compiler was not found.' }
$installerScript = Join-Path $repoRoot 'tool/windows/installer.iss'
& $InnoCompilerPath "/DStagingDir=$stageDir" "/DOutputDir=$distDir" "/DAppVersion=$version" $installerScript
if ($LASTEXITCODE -ne 0) { throw 'Inno Setup failed.' }
if (-not (Test-Path -LiteralPath $installer -PathType Leaf)) { throw 'Installer was not created.' }
$hashLines = @()
foreach ($artifact in @($portableZip, $installer)) {
    $hash = (Get-FileHash -LiteralPath $artifact -Algorithm SHA256).Hash.ToLowerInvariant()
    $hashLines += ($hash + '  ' + [System.IO.Path]::GetFileName($artifact))
}
Set-Content -LiteralPath $checksums -Value $hashLines -Encoding ascii
Assert-SafeStagingPath
if (Test-Path -LiteralPath $stageDir) { Remove-Item -LiteralPath $stageDir -Recurse -Force }
Write-Host "Packaged Particle Library $fullVersion in $distDir"
