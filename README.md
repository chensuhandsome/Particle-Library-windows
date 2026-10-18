# Particle Library

Particle Library is a desktop and mobile browser for the **Particle Data Group
(PDG)** review of particle physics. It is built for offline scientific use: the
PDG snapshot stays read-only and local, while notes, collections, favorites and
PDF annotations are stored separately from the data.

The app is written in Flutter and currently targets **macOS (Apple Silicon)** and
**iPhone/iPad**. A shared responsive layout is used for both.

## What is included

- **Offline PDG data** — read-only SQLite snapshot with SHA-256 integrity checks,
  first-launch staging, schema validation and lossless raw-field views.
- **Search and navigation** — particle names and aliases, Greek/LaTeX forms,
  MC numbers, PDG identifiers, topics, decays, references and free text.
- **Entity pages** — particles, topics, decay modes, series/properties and
  references, with summaries, all measurements, measurement values, footnotes,
  history, references and source records.
- **Scientific data semantics** — `PDG Average` / `PDG Fit` are treated as
  distinct summary kinds; limits, ranges, confidence levels, scale factors and
  "used in average/fit" flags remain visible instead of being normalised away.
- **Math typesetting** — inline PDG ASCII expressions, particle symbols,
  decay equations and units are rendered as mathematics where the source is
  unambiguous; otherwise the original text is preserved.
- **History and trends** — edition-by-edition summary values and a trend chart
  with asymmetric errors.
- **Notes** — local Markdown notes with anchors, backlinks, collections, tags,
  search, export/import, conflict protection, and a picker shared by every
  "add to note" action.
- **Tags** — filter, browse, rename and delete tags across all notes.
- **Literature** — local reference metadata plus optional Crossref title
  lookup, INSPIRE search, BibTeX/cite-key lookup and a Zotero local bridge.
- **Zotero index** — an explicit, manually refreshed local cache of the Zotero
  library makes INSPIRE result matching fast and avoids one lookup per row.
- **PDG reviews** — on-demand PDF cache, selective cache cleanup, PDF text
  highlights, notes and a filterable annotation sidebar.
- **Desktop workspace** — independently collapsible left outlines and context
  sidebars, draggable dividers, resizable panes and a compact mobile layout.
- **Bilingual UI** — Chinese and English interface with system/light/dark themes.

## Requirements

- macOS 15 or later (Apple Silicon recommended).
- Flutter **3.47.7** / Dart **3.13.5** (stable channel).
- Xcode **26.3** for macOS/iOS builds, with the iOS platform component installed.
- CocoaPods when a plugin requires it.

The project currently uses Flutter's Swift Package Manager integration for its
Apple dependencies.

### PDG snapshot

The PDG database is **not committed** to this repository: it is large and is
distributed under CC BY 4.0. Place the PDG 2026 snapshot at:

```text
assets/pdgall-2026.0.sqlite
```

Expected snapshot:

- Edition: **PDG 2026**, schema **0.3**
- SHA-256:
  `c82dab0c0a7c5264f23508066cabb8df9eacc1dbfc83c8d20fade6053394ba8a`
- The app verifies this hash before using the data.

The Flutter asset entry in `pubspec.yaml` requires this file to be present
before `flutter test`, `flutter run` or a platform build. A production/App
Store build must bundle the snapshot as an asset.


## Build and run: macOS

```bash
flutter pub get
flutter analyze
flutter test

# development
flutter run -d macos

# release
flutter build macos --release
open "build/macos/Build/Products/Release/Particle Library.app"
```

To make a Finder-friendly release copy:

```bash
rm -rf "dist/Particle Library.app"
mkdir -p dist
ditto "build/macos/Build/Products/Release/Particle Library.app" \
      "dist/Particle Library.app"
```

The internal bundle identifier is currently `com.example.pdgapp`. Keep it
stable if you want to preserve the local data container; change it before
distribution if you need your own identity.

## Build and install on iPhone

Physical-device installation needs **your own Apple signing identity**. The
repository deliberately contains no certificates, provisioning profiles or
team identifiers.

### 1. Prepare Xcode

1. Install the iOS platform in **Xcode → Settings → Components**.
2. Connect the iPhone and enable **Developer Mode** on it.
3. Open `ios/Runner.xcworkspace` in Xcode.
4. Select the `Runner` target → **Signing & Capabilities**:
   - choose your Apple ID team;
   - replace `com.example.pdgapp` with a bundle identifier unique to you
     (for example `com.yourname.particlelibrary`);
   - keep **Automatically manage signing** enabled.
5. Run once from Xcode on the phone and trust the developer certificate in
   **Settings → General → VPN & Device Management**.

A free Apple ID works for local testing, but its provisioning expires after
seven days; a paid developer team is needed for longer/TestFlight distribution.

### 2. Build

```bash
flutter pub get
flutter build ios --release
```

Or build and run directly on a connected phone:

```bash
flutter devices
flutter run -d <iphone-device-id> --release
```

For a distributable signed archive:

```bash
flutter build ipa
```

Install the resulting `.ipa` through Xcode → **Window → Devices and
Simulators**, Apple Configurator, or TestFlight after uploading with Xcode
Organizer.

### Simulator

```bash
open -a Simulator
flutter run -d <simulator-device-id>
```

An unsigned build can be checked with:

```bash
flutter build ios --release --no-codesign
```

It cannot be installed on a physical iPhone without signing. On the machine
used to prepare this repository, the iOS 26.2 platform and a signing identity
were not installed, so an installable phone build could not be produced here.

## Tests

```bash
flutter analyze
flutter test
```

The test suite covers the snapshot contract, display semantics, math parsing,
notes/tags, PDF annotation coordinates and persistence, Zotero cache parsing,
and UI helpers. Tests do not require network access unless a test explicitly
opts into a live service.

## Local data and privacy

- The PDG snapshot is read-only and checksum-verified.
- Notes and user settings live in a separate SQLite database.
- Favorites, recent searches and the Zotero index live in the app support
  directory.
- Review PDFs are downloaded from the PDG website on demand and are not part of
  this repository.
- Zotero is accessed read-only through its local API at
  `http://127.0.0.1:23119`; the Zotero index is updated only when you press the
  button in Settings.
- No telemetry is sent by the app.

## Repository layout

```text
lib/            Flutter application
test/           unit and widget tests
assets/         icons/theme assets; the PDG snapshot is supplied separately
macos/          macOS runner
ios/            iOS runner
docs/           design and data documentation
```

## Documentation

- [Design](docs/PDG_App_Design.md)
- [Data atlas](docs/PDGall_Data_Atlas.md)
- [Math conversion rules](docs/Math_Conversion.md)
- [Decay structure design](docs/Decay_Structure_Design.md)
- [Toolchain record](docs/Toolchain_Record.md)

## License

- **Application code:** MIT License; see [LICENSE](LICENSE).
- **PDG data snapshot:** CC BY 4.0, with attribution to the Particle Data
  Group. The MIT license does **not** cover the data.
- **PDG review PDFs:** not bundled; downloaded from the PDG and subject to
  PDG's terms.
- **Third-party packages:** see [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).

This is an independent application, not an official PDG product.
