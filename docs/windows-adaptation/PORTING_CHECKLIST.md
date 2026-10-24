# Windows Porting Checklist

## Status

The 0.2.1 integration and automated Windows 11 results are recorded in
[VERIFICATION_0.2.1.md](VERIFICATION_0.2.1.md). Upstream Markdown is unchanged.

The standard Flutter Windows runner is present and named for Particle Library.
The Windows 10/11 x64 release bundle and packaging path are implemented. The
full native smoke-test matrix still needs sign-off before describing Windows
as a verified supported release.

The runner was based on the Windows application template at the Flutter SDK
revision recorded in `.metadata` (Flutter 3.47.7 stable). The Windows app keeps
the existing application identity `io.github.fkguo.particlelibrary` and uses
`ParticleLibrary.exe` as its executable name.

## Platform Checks

| Area | Implementation / expected behavior | Verification |
|---|---|---|
| SQLite | `sqlite3_flutter_libs` resolves a Windows implementation; bundled PDG data opens read-only. | Pending native build and snapshot smoke test |
| PDF viewer | `pdfrx` uses `pdfium_dart`, whose build hook downloads the Windows PDFium DLL. First native build needs network access. | Pending build and PDF/annotation test |
| File selection | `file_selector_windows` supplies open/save dialogs. | Pending import/export dialog test |
| Storage | `path_provider_windows` resolves the app support directory for notes, settings, cached PDFs and snapshot staging. | Pending persistence/restart test |
| External links | `url_launcher_windows` handles links from references and settings. | Pending click-through test |
| Sharing | `share_plus` has a Windows implementation; desktop export flows use save dialogs. | Pending backup/export test |
| Zotero | Existing desktop capability check includes Windows; lookup uses same-machine loopback `127.0.0.1:23119` and is read-only. | Pending with Zotero installed; otherwise record unavailable |
| Native menu | No macOS menu channel is registered by the Windows runner; Help and Settings remain in-app. | Pending UI smoke test |
| Debug resizing | `ext.pdg.resize` is not registered on Windows because it requires the macOS `pdg.debug` channel. | Code-reviewed; runtime smoke test pending |

## Release Artifacts

`tool/windows_release.ps1` validates the snapshot, analyzes/tests, builds the
Windows release, stages the complete runtime bundle and license files, then
creates these artifacts under `dist/release/`:

- `Particle-Library-<version>-Windows-x64-Setup.exe`
- `Particle-Library-<version>-Windows-x64-Portable.zip`
- `SHA256SUMS.txt`

The Inno Setup installer is per-user with Start Menu and desktop shortcuts, no
elevation and no uninstaller entry. The portable ZIP contains the same runtime
folder. Do not distribute `ParticleLibrary.exe` alone.

## Build Acceptance

- [ ] Windows 10 x64 release build succeeds with Flutter 3.47.7 and MSVC/CMake.
- [ ] Windows 11 x64 release build succeeds, or CI's current Windows runner is recorded as the target OS.
- [x] `flutter analyze` succeeds (0.2.1).
- [x] `flutter test` succeeds with the real snapshot and matching SHA-256 (538 tests).
- [x] PDFium native assets are present in the built release bundle and official review PDFs render (native tests and fresh release DLL checks).
- [ ] CI passes on `windows-latest`; compile-only runs without the snapshot are not treated as app verification.

## Manual Smoke Test

- [ ] First launch stages the real snapshot, verifies its hash and opens the database.
- [ ] Search, particle navigation, measurements and math rendering work.
- [ ] A PDG review PDF opens; page navigation and an annotation persist.
- [ ] A note and favorite persist after closing and restarting the app.
- [ ] Notes import/export and full-backup import/export open Windows file dialogs and complete.
- [ ] External reference links open in the default browser.
- [ ] When Zotero is installed and running, local lookup finds an item; otherwise record it as not run.
- [ ] Window resize, keyboard navigation, Help and Settings work without macOS menus.

## Verification Record

Fill this section only after testing an actual Windows build.

- OS edition/build and architecture: **Windows 11 25H2, 10.0.26200.8246, x64**
- Flutter/Dart version: **3.47.7 / 3.13.5**
- Visual Studio/MSVC and CMake versions: **VS Community 2026 18.11.0; MSVC 19.51.36260.0; CMake 4.3.1-msvc1; SDK 10.0.26100.0**
- Snapshot SHA-256: **c82dab0c0a7c5264f23508066cabb8df9eacc1dbfc83c8d20fade6053394ba8a**
- Build/analyze/test results: **Release build and packaging passed; analysis passed; 538 unit/widget tests and both native integration tests passed.**
- Smoke-test notes and conditional Zotero result: **Native PDF/search and isolated fresh-install/upgrade tests passed; manual UI/Zotero checks pending.**
- Tester and date: **Automated Codex validation, 2026-10-24 (Asia/Shanghai).**
