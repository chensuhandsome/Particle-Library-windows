# Windows 0.2.4 integration and verification

The integration starts from Windows `66be014` and merges fkguo's
[`v0.2.4` release](https://github.com/fkguo/Particle-Library/releases/tag/v0.2.4)
at `95ad509` (`0.2.4+22`). The existing eight-file Windows Dart patch
carries forward unchanged. The port keeps upstream package versions and
hashes and uses the Windows fork's `pub.dev` host convention. The existing
direct path-provider interface dependency supports isolated native tests.

The SQLite build hook replaces the old Flutter plugin. The PDFium hook
supplies the library and its gate DLL. The release script requires manifest
entries and bundled DLLs for all three. The Windows executable identity,
data location, and release feed carry forward from 0.2.1.

## Building when symlink creation is unavailable

Flutter normally creates Windows plugin symlinks. On this machine, package
resolution completed but Flutter lacked permission to create those symlinks.
Run the following from the worktree root after that specific error. It builds
junctions from Flutter's generated package metadata inside this worktree.

```powershell
$linkRoot = Join-Path (Get-Location) 'windows/flutter/ephemeral/.plugin_symlinks'
New-Item -ItemType Directory -Path $linkRoot -Force | Out-Null
$metadata = Get-Content -Raw -LiteralPath '.flutter-plugins-dependencies' | ConvertFrom-Json
foreach ($plugin in $metadata.plugins.windows) {
    $link = Join-Path $linkRoot $plugin.name
    if (-not (Test-Path -LiteralPath $link)) {
        New-Item -ItemType Junction -Path $link -Target $plugin.path | Out-Null
    }
}
flutter pub get --enforce-lockfile
```

Repeat the procedure after a clean build or dependency change if Flutter
reports the same permission error. The junctions live under Flutter's
ignored `ephemeral` directory.

## Windows 11 x64 results

Verified on 2026-11-24 (Asia/Shanghai) with Windows 11 Pro 25H2 build
`26200.9711`, Flutter `3.47.7`, Dart `3.13.5`, and the Visual Studio
Community 2026 C++ toolchain. Logs are under `dist/verification/`.

| Check | Result |
| --- | --- |
| Dependency lock and generated version | Passed with the upstream package versions and `0.2.4+22` |
| PDG snapshot and derived assets | Passed using the verified 2026.0 snapshot and the upstream 0.2.4 sidecar |
| Review-index verifier | All three reference queries reached their expected reviews and pages |
| PowerShell release-tool checks | Passed, including rejection of missing or damaged assets |
| Static analysis | Passed |
| Unit and widget tests | 616 passed, two macOS-only tests skipped |
| Native hybrid PDF test | Passed, including annotation interactions and reader state reopening |
| Native Windows smoke test | Passed first-install staging, FTS5, official PDF page navigation, export, and note persistence |
| Fresh x64 release | Built `ParticleLibrary.exe` with product version `0.2.4+22` |
| Release DLLs | SQLite 3.54.1 ran an FTS5 query. PDFium and its gate loaded and created a test page |
| Windows update endpoint | The release AOT binary contains the Windows fork's GitHub release endpoint |
| Portable and installer artifacts | Built with Inno Setup 6.7.3 and verified both SHA-256 checksums |
| Fresh setup and 0.2.1 upgrade | All 55 runtime and license files matched the portable bundle in each sandbox. Setup preserved the unrelated upgrade fixture file |

The installer and portable ZIP are under `dist/release/` with
`SHA256SUMS.txt`. Keep the portable runtime directory together, including
its DLLs and `data/` folder.

## Release launch isolation

This Windows session had no disposable login or Windows Sandbox. The startup
probe copied the release bundle and changed the copy's executable company
metadata so Windows resolved a new app-data directory. The copy retained the
release version and byte-identical AOT payload. Its window responded, the
staged PDG snapshot matched its expected hash, and the new notes database
passed SQLite's integrity check at schema version 2. The probe removed its
temporary app data and verified the original release hashes.

The hidden window exposed no named controls through Windows UI Automation.
The release startup probe covers boot and data staging. A separate native
Flutter UI probe opened M252 from the catalog, rendered its PDG Live summary,
and used Settings to check the live Windows release feed. The app reported
that it was up to date. The debug probe also reported a Flutter `ListTile`
diagnostic about a decorated background obscuring ink effects.
