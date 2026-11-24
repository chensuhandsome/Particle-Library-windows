# Particle Library for Windows

Build on Windows x64 with Flutter 3.47.7 and Visual Studio's Desktop
development with C++ workload, including CMake and a Windows SDK. Flutter
needs permission to create plugin symlinks. The first build and the native
PDF smoke test require network access. Packaging needs Python 3 and Inno Setup 6.

Place the [official PDG 2026.0 snapshot](https://pdg.lbl.gov/2026/api/pdgall-2026.0.sqlite)
at `assets/pdgall-2026.0.sqlite`. Verify it and the bundled assets before
building. The Windows lockfile uses pub.dev with upstream's pinned versions
and hashes.

```powershell
powershell -ExecutionPolicy Bypass -File .\tool\windows\verify_assets.ps1
flutter pub get --enforce-lockfile
flutter analyze --no-pub lib test integration_test
flutter test --no-pub
flutter test integration_test/pdf_hybrid_app_test.dart -d windows --no-pub
flutter test integration_test/windows_smoke_test.dart -d windows --no-pub
powershell -ExecutionPolicy Bypass -File .\tool\windows\test_release_tools.ps1
```

If package resolution succeeds but Flutter reports a symlink permission
error, create junctions in the generated plugin directory and retry.

```powershell
$linkRoot = Join-Path (Get-Location) 'windows/flutter/ephemeral/.plugin_symlinks'
New-Item -ItemType Directory -Path $linkRoot -Force | Out-Null
$metadata = Get-Content -Raw '.flutter-plugins-dependencies' | ConvertFrom-Json
foreach ($plugin in $metadata.plugins.windows) {
    $link = Join-Path $linkRoot $plugin.name
    if (-not (Test-Path -LiteralPath $link)) {
        New-Item -ItemType Junction -Path $link -Target $plugin.path | Out-Null
    }
}
flutter pub get --enforce-lockfile
```

Build the release, installer, and portable ZIP with
`powershell -ExecutionPolicy Bypass -File .\tool\windows_release.ps1`.
Pass `-InnoCompilerPath` for a portable Inno Setup installation. The runtime
bundle is under `build/windows/x64/runner/Release/`. Run
`ParticleLibrary.exe` from that complete directory. The installer, ZIP,
and checksums are under `dist/release/`.
