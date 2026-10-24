[CmdletBinding()]
param([string]$PreviousPortableZip)
$ErrorActionPreference='Stop'
Set-StrictMode -Version Latest
$repoRoot=Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$pubspec=Get-Content -LiteralPath (Join-Path $repoRoot 'pubspec.yaml') -Raw -Encoding UTF8
$version=([regex]::Match($pubspec,'(?m)^version:\s*([0-9]+\.[0-9]+\.[0-9]+)')).Groups[1].Value
$release=Join-Path $repoRoot 'dist/release'
$installer=Join-Path $release "Particle-Library-$version-Windows-x64-Setup.exe"
$portable=Join-Path $release "Particle-Library-$version-Windows-x64-Portable.zip"
$root=Join-Path $repoRoot ('dist/verification/installer-' + [guid]::NewGuid().ToString('N'))
[System.IO.Directory]::CreateDirectory($root) | Out-Null
Add-Type -AssemblyName System.IO.Compression.FileSystem
[System.IO.Compression.ZipFile]::ExtractToDirectory($portable,(Join-Path $root 'portable'))
$expected=Join-Path $root 'portable/Particle-Library-Windows-x64'
$desktopShortcut=Join-Path ([Environment]::GetFolderPath('Desktop')) 'Particle Library.lnk'
function ShortcutHash {
    if (Test-Path -LiteralPath $desktopShortcut) { return (Get-FileHash -LiteralPath $desktopShortcut).Hash }
    return ''
}
$originalShortcut=ShortcutHash
function Install-InSandbox([string]$Directory,[string]$LogName) {
    $arguments=@('/VERYSILENT','/SUPPRESSMSGBOXES','/NORESTART','/SP-','/NOICONS','/TASKS=""',
        ('/DIR="' + $Directory + '"'),('/LOG="' + (Join-Path $root $LogName) + '"'))
    $process=Start-Process -FilePath $installer -ArgumentList $arguments -WindowStyle Hidden -PassThru
    if (-not $process.WaitForExit(45000)) { throw "Installer still running (PID $($process.Id)); inspect its log before retrying." }
    if ($process.ExitCode -ne 0) { throw "Installer failed: $($process.ExitCode)" }
    if ((ShortcutHash) -ne $originalShortcut) { throw 'Sandbox setup changed the desktop shortcut.' }
}
function Assert-InstalledBundle([string]$Directory) {
    $count=0
    foreach ($file in Get-ChildItem -LiteralPath $expected -File -Recurse) {
        $relative=$file.FullName.Substring($expected.Length).TrimStart('\','/')
        $installed=Join-Path $Directory $relative
        if (-not (Test-Path -LiteralPath $installed -PathType Leaf)) { throw "Missing installed file: $relative" }
        if ((Get-FileHash -LiteralPath $installed).Hash -ne (Get-FileHash -LiteralPath $file.FullName).Hash) {
            throw "Installed file differs from portable bundle: $relative"
        }
        $count++
    }
    & (Join-Path $PSScriptRoot 'verify_assets.ps1') -AssetsDirectory (Join-Path $Directory 'data/flutter_assets/assets') -ReferenceAssetsDirectory (Join-Path $repoRoot 'assets')
    Write-Host "Verified $count installed runtime/license files: $Directory"
}
$fresh=Join-Path $root 'fresh with spaces'
Install-InSandbox $fresh 'fresh.log'
Assert-InstalledBundle $fresh
if ($PreviousPortableZip) {
    [System.IO.Compression.ZipFile]::ExtractToDirectory($PreviousPortableZip,(Join-Path $root 'upgrade'))
    $upgrade=Join-Path $root 'upgrade/Particle-Library-Windows-x64'
    $oldVersion=(Get-Item -LiteralPath (Join-Path $upgrade 'ParticleLibrary.exe')).VersionInfo.ProductVersion
    Set-Content -LiteralPath (Join-Path $upgrade 'preserve-user-file.txt') -Value 'preserve on update' -Encoding UTF8
    Install-InSandbox $upgrade 'upgrade.log'
    Assert-InstalledBundle $upgrade
    if ((Get-Content -LiteralPath (Join-Path $upgrade 'preserve-user-file.txt') -Raw).Trim() -ne 'preserve on update') {
        throw 'Update removed an unrelated existing file.'
    }
    Write-Host "Upgrade from $oldVersion passed."
}
Write-Host "Installer and portable verification passed. Logs and extracted bundles: $root"
