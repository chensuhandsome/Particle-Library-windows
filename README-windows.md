# Particle Library on Windows

## Availability

The Windows target builds for Windows 10/11 x64. The packaging script creates
an Inno Setup installer and a complete portable ZIP. No public Windows release
is announced until the native smoke-test checklist passes. Never separate
`ParticleLibrary.exe` from its DLL files and `data` directory.

## Requirements

- Windows 10 or 11, x64.
- Flutter 3.47.7 stable (Dart 3.13.5), matching `pubspec.yaml`.
- Visual Studio 2022 or newer with **Desktop development with C++**, MSVC,
  CMake tools for Windows, and a Windows 10/11 SDK. VS Code alone is not
  sufficient.
- Python 3 for the generated-version check and review-index validation.
- Inno Setup 6 for the installer.
- Network access for Flutter packages and the PDFium Windows DLL downloaded
  by `pdfium_dart` during the first native build.
- Windows uses Segoe UI with `Microsoft YaHei UI` and `Microsoft YaHei` as
  Chinese fallbacks. These are system fonts; no fonts are bundled.

Check the installation with:

```powershell
flutter doctor -v
```

## PDG Snapshot

The 64 MiB PDG database is not in Git. Download the official PDG 2026 snapshot
to `assets/pdgall-2026.0.sqlite`, then verify its SHA-256 before building:

```powershell
Invoke-WebRequest `
  -Uri 'https://pdg.lbl.gov/2026/api/pdgall-2026.0.sqlite' `
  -OutFile 'assets/pdgall-2026.0.sqlite'

$expected = 'c82dab0c0a7c5264f23508066cabb8df9eacc1dbfc83c8d20fade6053394ba8a'
$actual = (Get-FileHash 'assets/pdgall-2026.0.sqlite' -Algorithm SHA256).Hash.ToLowerInvariant()
if ($actual -ne $expected) { throw 'Snapshot hash mismatch.' }
```

Do not substitute an empty placeholder for the real snapshot when running the
app or its tests. The app checks the snapshot identity and schema at startup.

The 0.2.1 source also includes four derived assets: the PDG notes sidecar,
the review text index, its source manifest and its search rules. Keep these
files exactly as supplied by upstream; a Windows build does not regenerate them.
Validate all five data assets before building:

```powershell
.\tool\windows\verify_assets.ps1
python -X utf8 tool/generate_app_version.py --check
```

## Smoke Test

On a Windows 10/11 x64 machine, record the OS build, Flutter version, Visual
Studio/MSVC version and results in
[`docs/windows-adaptation/PORTING_CHECKLIST.md`](docs/windows-adaptation/PORTING_CHECKLIST.md).
Check startup and snapshot verification, search and math display, PDF loading
and annotations, note/favorite persistence after restart, backup and note file
dialogs, external links, and Zotero lookup when Zotero is installed. The
platform is not supported until the release build and these checks pass.

## Build and Run

From the repository root:

```powershell
flutter pub get --enforce-lockfile
flutter analyze
flutter test
flutter run -d windows
```

The native regression tests isolate their data from your installed app. The
Windows smoke test downloads two official review PDFs and checks the three
review-search results against their physical pages:

```powershell
flutter test integration_test/pdf_hybrid_app_test.dart -d windows
flutter test integration_test/windows_smoke_test.dart -d windows
```

Build a release executable bundle with:

```powershell
flutter build windows --release `
  --dart-define=UPDATE_MANIFEST_URL=https://api.github.com/repos/chensuhandsome/Particle-Library-windows/releases/latest

# Validate and package the installer plus portable ZIP:
powershell -ExecutionPolicy Bypass -File .\tool\windows_release.ps1
```

The raw build output is under `build/windows/x64/runner/Release/`. Packaged
artifacts are written to `dist/release/`:

- `Particle-Library-<version>-Windows-x64-Setup.exe`
- `Particle-Library-<version>-Windows-x64-Portable.zip`
- `SHA256SUMS.txt`

The installer is a per-user, portable-style installation with Start Menu and
desktop shortcuts and no uninstaller entry. The portable ZIP must be extracted
as a complete directory. Do not distribute only `ParticleLibrary.exe`.

The packaging script validates the generated version, the native-asset manifest,
and all bundled data files. It preserves older release files and uses this
Windows fork's update endpoint. The installer keeps the existing per-user
identity and defaults to creating a desktop shortcut; it can be disabled in
Setup. Image clipboard copying remains macOS-only; Windows supports PNG save
and Markdown/image export.
