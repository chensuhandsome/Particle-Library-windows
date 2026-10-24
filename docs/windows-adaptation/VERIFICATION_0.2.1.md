# Windows 0.2.1 implementation and verification

Date: **2026-10-24 (Asia/Shanghai)**.

The Windows integration uses fkguo's pinned `9402c5b` source (`0.2.1+19`).
All Markdown files present in that upstream revision are unchanged. Documentation
updates are confined to Windows-owned files.

## Implementation

- Kept the Windows runner, executable/product/company identity, icon and
  application-support directory naming.
- Kept the Windows font fallback/Consolas helper and the Windows debug-resize
  guard. The complete shared `lib/` delta from upstream is eight files,
  42 added lines and 22 removed lines; it consists of the helper, its font
  substitutions, and the debug guard.
- Took upstream's backup, storage, search, review reader, notes, Zotero and
  update-checker implementations unchanged.
- Preserved every upstream package version. Normalized the lockfile's host
  from the author's mirror to pub.dev and enforced the lockfile. Added only
  a direct test dependency on the already-resolved path-provider interface
  to isolate native tests from real application data.
- Updated Windows packaging to verify all five data assets, generated app
  version, executable version, and generated native-asset manifest. A fresh
  upstream-locked build correctly ships `pdfium.dll` without the newer gate DLL.
- Configured Windows release builds to use this fork's release API through the
  existing build define. The endpoint is present in the release AOT binary.
- Preserved upstream CI jobs and added Windows asset/index verification,
  lock enforcement, release-tool regressions, native tests and packaging checks.
  Replaced the incomplete Inno compile-action step with explicit compiler
  installation (Chocolatey Inno Setup 6.7.1). The local compiler is 6.7.3.
- Made the desktop shortcut a default-selected installer task so isolated
  silent setup tests can suppress shortcuts. Normal installation remains
  per-user with the same application identity.

## Verified locally

| Check | Result |
| --- | --- |
| `flutter pub get --enforce-lockfile` | Passed; upstream package versions preserved |
| `flutter analyze --no-pub` | Passed |
| `flutter test --no-pub` | **538 passed**, no failures/skips |
| Generated version | Passed; `0.2.1+19` / runtime `0.2.1` |
| Main snapshot and review-index/rules/manifest hashes | Passed |
| Upstream review-index verifier and U1-U3 ranking gates | Passed |
| Native `pdf_hybrid_app_test.dart` | Passed on Windows; right-click, annotation move/resize, reader state/reopen |
| Native `windows_smoke_test.dart` | Passed; first-install asset staging, FTS5, actual official PDFs, physical-page navigation, PNG/Markdown export, note reopen |
| Archive lifecycle regression | Passed for valid and rejected ZIPs; immediate rename/deletion, Chinese/spaced paths |
| Actual v0.1.3 source data and backup | Notes, tags, favorites and English locale preserved when opened/restored by v0.2.1 |
| Fresh Windows release build | Passed with an empty Release output directory |
| Release native DLLs | PDFium loads; SQLite 3.52.0 reports FTS5 enabled |
| Release AOT update endpoint | Windows fork endpoint verified in binary |
| Portable ZIP / installer checksums | Passed |
| Fresh isolated installer setup | Passed; all 55 files match portable ZIP |
| Installer over v0.1.3 portable bundle | Passed; version updated, all new files match, unrelated user file preserved |
| Desktop shortcut during sandbox setup | Unchanged |
| Upstream Markdown equality | Passed; no Windows edits to upstream Markdown |

The native search gates loaded the official, manifest-hashed PDF files and
opened these physical pages:

- `CG coefficients`: Clebsch-Gordan review, page **1**.
- `hadronic cross sections`: cross-section plots review, page **5**.
- `average hadron multiplicities`: the same plots review, page **2**.

Host: Windows 11 25H2, build `10.0.26200.8246`, x64; Flutter `3.47.7`, Dart
`3.13.5`; Visual Studio Community 2026 `18.11.0`, MSVC compiler
`19.51.36260.0`, CMake `4.3.1-msvc1`; Windows SDK `10.0.26100.0`.

## Local artifacts

Under `dist/release/` (ignored by Git):

- `Particle-Library-0.2.1-Windows-x64-Setup.exe`.
- `Particle-Library-0.2.1-Windows-x64-Portable.zip`.
- `SHA256SUMS.txt`.

Build/unit/index/old-source upgrade logs and extracted installer verification
bundles are under `dist/verification/` (also ignored). Older 0.1.3 release
artifacts and its archived build were preserved. No release was published and
no changes were pushed.

## Remaining manual coverage before public support sign-off

Windows 10 x64 was not available for this run. Manual checks of physical Chinese
IME input/high-DPI display, native file-dialog cancellation, default-browser
launching and an installed Zotero instance remain unverified. The tests use
isolated user-data directories; they do not exercise the user's personal
Zotero library or migrate the running installed app's real data.

These limits remain explicit in `PORTING_CHECKLIST.md`; the automated Windows
11 results do not certify Windows 10 or a public-release support matrix.
