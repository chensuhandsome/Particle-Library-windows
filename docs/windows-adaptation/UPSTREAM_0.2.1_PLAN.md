# Windows adaptation plan: upstream 0.2.1

Reviewed: **2026-10-24 (Asia/Shanghai)**.

Implementation results are recorded in [VERIFICATION_0.2.1.md](VERIFICATION_0.2.1.md).
The text below preserves the original review and plan.

**Status: comparison and implementation plan only.** No application source,
dependency lockfile, runner, packaging script, or Git history has been changed
as part of this review. The commands below are future implementation steps,
not a record of a completed port.

## 1. Verified baselines

| Item | Version / revision |
| --- | --- |
| Windows workspace | `C:\Users\chensu\Documents\Particle-Library-windows` |
| Windows HEAD | `89066b0` (`main`), app `0.1.3+14` |
| New fkguo copy | `C:\Users\chensu\Documents\Particle-Library` |
| New copy HEAD | `9402c5bceab4f9faca9c3e8a19b8a70d4dc6d8c3` (`main`) |
| Common upstream ancestor | `09801633fa564a4e2ae92f7fe1e1d0db7148f5be` (`v0.1.3`) |
| Latest published upstream release | `v0.2.1`, app `0.2.1+19`, release commit `5e9f645` |
| Release publication time | **2026-10-24 02:03:43 +08:00** (GitHub: `2026-10-23T18:03:43Z`) |

Read-only GitHub API and `git ls-remote` checks confirmed that the new local
copy matches the remote main branch at review time. There are eight commits
after the release commit; their aggregate diff changes only the English and
Chinese READMEs, asset README, and build documentation. Use `9402c5b` as the
integration target so the port includes those documentation corrections while
retaining the released runtime code.

Both working trees were clean before this plan was written. The Windows fork
already has an `upstream` remote for fkguo's repository.

### Diff sizes

Relative to the common ancestor:

- Upstream: **51 commits; 196 files; 27,393 insertions / 2,581 deletions**.
- Existing Windows adaptation: **48 files; 1,835 insertions / 162 deletions**.
- **16 paths** changed on both sides. A read-only three-way `git merge-tree`
  comparison produced conflict markers in **eight files** (listed below).
- Only ten existing Windows-modified files are under `lib/`; two of those
  contain comment-only changes. The port does not require rewriting fkguo's
  shared application architecture.

## 2. What changed and what it means for Windows

| Upstream area | Change | Windows approach |
| --- | --- | --- |
| Reviews search | Bundled FTS5 page index; query parsing/ranking; review/page deep links; download progress | Adopt unchanged. Test FTS5 with the Windows SQLite DLL and exercise first-use index staging and exact PDF-page navigation. |
| PDG enrichment | Bundled pdgLive notes/reference sidecar and review links | Adopt the committed sidecar unchanged; package it alongside the main snapshot. Do not regenerate it during a Windows build. |
| PDF reader | Region images, Markdown export, annotation/reading-state fixes, reader UI improvements | Retain the desktop save-dialog path. Verify PNG and Markdown exports, mouse/right-click interactions, and restart persistence. |
| Notes | Evidence/context views, collections, filtering, floating lookup panels, CSV safety, import fixes | Adopt unchanged; test Windows paths, IME/keyboard input, and SQLite cleanup. |
| Backups | Staged streaming restore, member validation, region images, safer export/restore handling | Prefer the complete new implementation; retire the old Windows `decodeBytes` workaround. |
| Shared fixes | Navigation, layout, search/display fidelity, errors, HTTPS update links, Zotero timeouts/loopback token handling | Preserve upstream fixes. No Windows-specific rewrite is justified by the diff. |
| Build/versioning | Generated runtime version, integration-test dependency, new review-index CI job | Preserve upstream generation and CI checks; add equivalent validation to Windows jobs. |

Relevant new assets are:

- `assets/pdg_notes_2026.sqlite` (262,144 bytes).
- `assets/review_index_2026.sqlite` (15,003,648 bytes).
- `assets/review_sources_2026.json`.
- `assets/review_search_rules_v1.json`.

The official `assets/pdgall-2026.0.sqlite` remains an ignored, separately supplied
asset. It is absent from the new source clone but already exists in the Windows
workspace. Its SHA-256 matches the unchanged upstream contract:

```text
c82dab0c0a7c5264f23508066cabb8df9eacc1dbfc83c8d20fade6053394ba8a
```

Merging into this workspace preserves that ignored snapshot. Do not overwrite
it with a placeholder or download another copy unnecessarily. The new index
adds offline text search, not bundled review PDFs; PDFs remain on-demand.

## 3. Conflict-resolution decisions

These are the eight conflicted paths in the read-only comparison. A real merge
must still be reviewed; an automatic merge is not proof of semantic correctness.

| File | Resolution |
| --- | --- |
| `lib/app/full_backup.dart` | Take upstream's complete implementation. It explicitly closes `InputFileStream` in `finally` (`upstream:311-318`), addressing the handle-lifetime concern behind the old Windows workaround. Add Windows lock/cleanup regression coverage rather than restoring whole-archive decoding. |
| `lib/features/common/async_view.dart` | Keep upstream's new error handling/layout; retain `AppFonts.monospaceFamily` instead of the hard-coded `Menlo`. |
| `lib/features/common/raw_fields.dart` | Keep upstream's formatting/layout; retain the same font helper for both raw field labels and `NULL`. |
| `pubspec.lock` | Start from upstream's lockfile, then run `flutter pub get` with the matching SDK. Review any generated changes. Do not concatenate conflict sections or run `pub upgrade`. |
| `README.md` | Keep the new upstream description and add only a short Windows pointer to `README-windows.md`. Do not revert the new review-search/data documentation. |
| `docs/development/BUILDING.md` | Retain upstream's new asset requirements; preserve the Windows build instructions. |
| `docs/development/PLATFORMS.md` | Retain upstream platform information; describe Windows as awaiting 0.2.1 native verification until the checklist passes. |
| `docs/development/RELEASING.md` | Retain upstream release/version checks; keep the separate Windows packaging instructions. |

The CI workflow merges textually but needs deliberate review: it must retain
upstream's read-only permissions and new `review-index` job as well as the
fork's Windows build/package jobs.

## 4. Minimal Windows patch policy

### Retain

- The existing `windows/` runner, icon, executable name, and installer identity.
  Preserve `Runner.rc` `CompanyName` and `ProductName`, as well as executable
  and app IDs, so application-support paths and upgrade behavior do not change.
- `AppFonts` and the Windows Chinese fallback fonts in `lib/app/app_theme.dart`.
  Continue using Segoe UI / YaHei and Consolas only on Windows; leave other
  platforms' typography unchanged.
- Existing `AppFonts.monospaceFamily` call sites. Also cover the remaining
  hard-coded monospace choice in `lib/features/common/page.dart` for consistency.
  Keep this to small style substitutions, not UI redesign.
- The existing Windows guard around `ext.pdg.resize` in
  `lib/app/debug_bridge.dart`; the runner has no macOS `pdg.debug` handler.
- Existing test fixes: slash normalization in
  `test/features/snack_bars_test.dart`, deterministic database closure in
  `test/notes/notes_store_test.dart`, and Windows/macOS font tests.
- Windows-specific files, analyzer exclusions, build ignores, and documentation.

### Drop / do not add

- Drop the old `full_backup.dart` `decodeBytes` substitution: the new upstream
  stream has explicit cleanup, validation, and bounded/staged member handling.
- Do not carry comment-only source edits as a requirement of the port.
- Do not change `appSupportDirectory()`, database schemas, search/ranking logic,
  annotation models, or mobile/macOS code without a reproduced Windows failure.
- Do not hand-edit generated plugin registrants/CMake plugin lists; let Flutter
  regenerate them for the selected dependency graph.
- Do not implement a new Windows image-clipboard channel for this update.
  Upstream already guards `pdg.clipboard` actions to macOS; Windows has Save PNG
  and Export Markdown. Document that distinction rather than exposing a missing
  native method.
- Do not port macOS Zotero activation. Upstream already guards those native
  calls and includes Windows profile discovery and loopback API support.

## 5. Windows build and packaging adjustments

### Important dependency/native-asset difference

The dependency declarations are largely unchanged, but the committed lockfiles
resolve different PDF stacks:

| Package | Existing Windows lock | New upstream lock |
| --- | --- | --- |
| `pdfrx` | `2.8.0` | `2.6.5` |
| `pdfrx_engine` | `0.7.1` | `0.6.1` |
| `pdfium_dart` / `pdfium_flutter` | `0.4.0` | `0.3.1` |

Prefer the author's tested upstream resolution first. A dependency upgrade is
not part of a minimal platform adaptation unless an actual incompatibility is
reproduced.

`tool/windows_release.ps1:28` currently requires `pdfrx_pdfium_gate.dll`.
The official `pdfium_dart 0.3.1` package's build hook downloads `pdfium.dll` but
does not build that gate DLL; the `0.4.0` hook does. Consequently, the old
packaging check is incompatible with a fresh upstream-locked build. Do not
upgrade the PDF stack merely to satisfy that stale check.

Make small changes in Windows-owned build files:

1. Update runtime validation for the native assets actually required by the
   resolved PDF stack. Do not unconditionally require the newer gate DLL.
   Continue shipping the complete Flutter runtime directory, not only the EXE.
2. Require all assets declared by the new `pubspec.yaml` in the built/staged
   bundle. Verify the main snapshot and the review-index/rules/manifest contract.
3. Add `python -X utf8 tool/generate_app_version.py --check` to Windows CI/release
   validation. Keep `pubspec.yaml` at `0.2.1+19` and use upstream's committed
   generated version; no separate hard-coded Windows app version is needed.
4. Use the existing `UPDATE_MANIFEST_URL` build define for published Windows
   binaries, pointing to this fork's release endpoint. The default upstream
   endpoint has no Windows assets. Do not globally rewrite upstream URLs or
   modify the shared update checker. Keep development builds' default behavior.
5. Preserve upstream CI jobs and add Windows review-search/live-index tests even
   when the optional main-snapshot CI variable is absent. A placeholder may be
   used only for explicitly labeled compile/isolated-index checks. Packaging
   must fail unless the real snapshot and all new assets are valid.
6. Use a fresh native build after changing the PDF dependency graph, so old
   `0.4.0` DLLs cannot make a broken packaging check appear to pass.
7. Keep existing per-user installer/portable behavior. Before recursive staging
   cleanup, verify the resolved staging path is a child of the intended
   `dist/release` directory. Preserve license/notice files and author attribution.

The update override is a build-time setting, for example:

```powershell
--dart-define=UPDATE_MANIFEST_URL=https://api.github.com/repos/chensuhandsome/Particle-Library-windows/releases/latest
```

## 6. Implementation sequence

1. **Preserve user data and create an integration branch.** Export a full backup
   from the existing installed app and record its data paths. Do not test
   destructive restore scenarios against the user's real data.
2. **Merge the pinned upstream revision.** Preserve history rather than copying
   the new source folder over this one. Fetch upstream, create a branch such as
   `windows/upstream-0.2.1`, and merge `9402c5b` with review before committing.
3. **Resolve the eight conflicts using section 3.** Review all 16 overlapping
   files, especially the textually clean theme, settings, notes, and CI merges.
4. **Reapply only the minimal patch in section 4.** Confirm new app-path, review,
   backup, and Zotero implementations otherwise remain byte-for-byte upstream.
5. **Resolve packages and update Windows-only validation/packaging.** Start with
   upstream's lockfile, avoid upgrades, regenerate native plugin wiring with
   Flutter, and account for the different PDF DLL set.
6. **Run automated validation and a fresh Windows release build.** Fix only
   reproduced platform issues, adding a focused regression test for each.
7. **Complete native smoke/upgrade tests and package.** Record actual results in
   `PORTING_CHECKLIST.md`, update `README-windows.md` for the new search/assets,
   and publish only after the native acceptance matrix passes.

Suggested reviewable commits: upstream integration/conflict resolutions;
minimal Windows compatibility and regression tests; Windows packaging/CI and
documentation. Keep unrelated refactoring out of all three.

## 7. Validation gates

In an isolated Python validation environment with the pinned dependency from
`tool/requirements-review-index.txt` available, run after integration:

```powershell
flutter pub get
python -X utf8 tool/generate_app_version.py --check
python -X utf8 tool/build_review_index.py verify `
  --db assets/review_index_2026.sqlite `
  --contract lib/core/review_index_contract.dart `
  --rules assets/review_search_rules_v1.json `
  --manifest assets/review_sources_2026.json
flutter analyze
flutter test
flutter test test/search test/data/review_index_live_test.dart
flutter test integration_test/pdf_hybrid_app_test.dart -d windows
flutter build windows --release `
  --dart-define=UPDATE_MANIFEST_URL=https://api.github.com/repos/chensuhandsome/Particle-Library-windows/releases/latest
```

The Python verifier checks integrity/hashes and these exact first-result gates;
the Dart live-index tests must also pass using Windows native SQLite:

- `CG coefficients` -> Clebsch-Gordan review, physical PDF page **1**.
- `hadronic cross sections` -> Cross-section plots review, page **5**.
- `average hadron multiplicities` -> The same plots review, page **2**.

Native acceptance must cover:

- First launch with real assets; first review-search index copy; subsequent
  offline search; PDF download progress/cancellation and cached offline opening.
- All three review-search results opening the expected physical PDF pages.
- Mouse/right-click selection, text/region annotations, PNG save, Markdown plus
  adjacent image export, and persistence after restart.
- Ctrl-based shortcuts, ordinary typing/Chinese IME, narrow/wide layouts, high
  DPI, and English/Chinese text/math rendering.
- Notes/favorites/settings preserved through a 0.1.3 -> 0.2.1 update without
  changing app-support paths; old backups and notes-only JSON remain importable.
- Backup overwrite/cancellation, import followed immediately by source archive
  deletion/renaming, scratch cleanup, and database shutdown. Include paths with
  spaces, Chinese characters, backslashes, and exports on another drive.
- External links and Windows update destination. Test Zotero lookup if installed;
  optional plugin writes/picker behavior require an explicitly controlled test
  library and must not mutate the user's library during this review.
- Both installer and complete portable ZIP, fresh install and in-place update,
  native DLL presence, all five data assets, and checksums.
- Windows 11 native verification and a separately recorded Windows 10 x64 result;
  do not claim Windows 10 was tested merely because the runner targets it.

## 8. Checks completed during this review

- Git histories, file diffs, full existing Windows source patch, overlap/conflict
  simulation, asset contracts, native-channel guards, CI and release scripts.
- GitHub latest release and remote main verification (read-only).
- Installed **Flutter 3.47.7 / Dart 3.13.5** and **Visual Studio Community 2026
  18.11.0**, Windows SDK `10.0.26100.0`; Windows toolchain checks passed.
  The missing Android SDK is irrelevant to this Windows plan.
- Existing Windows fork: `flutter analyze --no-pub` passed and the full
  `flutter test --no-pub` suite passed. These are baseline results, not results
  for the unmerged 0.2.1 code.
- Existing main snapshot SHA-256 passed. New enrichment sidecar integrity passed
  (299 notes, 209 references, 266 citation links, 67 review links).
- New review index/rules/manifest hashes passed; index integrity passed with
  **121 reviews / 2,163 pages**. Upstream's own verifier and all three ranking
  self-test gates passed using a temporary pinned `pypdf 4.3.1` wheel, without
  installing anything into the global Python environment.
- Upstream generated-version check passed.
- Existing built Windows `sqlite3.dll` reports SQLite `3.52.0` with FTS5 enabled.
  This is encouraging evidence only; the new build must still run the live tests.
- Official package-source inspection confirmed the `pdfium_dart 0.3.1` versus
  `0.4.0` native-asset difference.

**Not yet done:** actual merge, tests of merged Dart code, fresh 0.2.1 native
build, Windows integration test, packaged-app smoke tests, or release publication.
