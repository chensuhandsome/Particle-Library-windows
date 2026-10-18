<p align="center">
  <img src="docs/assets/quark-idle.gif" alt="Particle Library Quark" width="150">
</p>

# Particle Library

**English** | [简体中文](README.zh-CN.md)

Particle Library is a desktop and mobile browser for the **Particle Data Group
(PDG)** review of particle physics. It is built for offline scientific use: the
PDG snapshot stays read-only and local, while notes, collections, favorites and
PDF annotations are stored separately from the data.

Built by **Feng-Kun Guo** over a weekend using **DeepSeek Harness** and
**DeepSeek-V4.1-Flash-1017**.

The app is written in Flutter and currently targets **macOS (universal)** and
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
- **Zotero index (macOS desktop only)** — an explicit, manually refreshed local cache of the Zotero
  library makes INSPIRE result matching fast and avoids one lookup per row.
- **PDG reviews** — on-demand PDF cache, selective cache cleanup, PDF text
  highlights stored as local notes with review anchors, and an annotation
  sidebar. Highlights are searchable, taggable and included in note export.
- **Desktop workspace** — independently collapsible left outlines and context
  sidebars, draggable dividers, resizable panes and a compact mobile layout.
- **Bilingual UI** — Chinese and English interface with system/light/dark themes.
- **Update check** — a background release check plus a manual
  **Check for updates** action in Settings → About; it opens the download page.
- **PDF highlights are notes** — each highlight creates a normal local note
  anchored to the review, so search, tags, backlinks, export and the recycle
  bin apply without a second annotation database.

## Requirements

- macOS 12 or later (universal; verified on macOS 15.6 Apple Silicon).
- iOS/iPadOS 15 or later.

A released build bundles the PDG snapshot. Building from source additionally
requires Flutter/Xcode and the snapshot; those are **contributor** requirements,
documented in [BUILDING.md](docs/development/BUILDING.md).

## Install

There is no public binary release yet. When a [GitHub Release](https://github.com/fkguo/Particle-Library/releases) provides
`.dmg`/`.zip`, `.ipa`/TestFlight or other installers, use those; end users do
not need Flutter, Xcode or the source tree.

Until then, the macOS app can be built from source. An iOS simulator build and a signed Debug install on an iPhone have been
smoke-tested; Release/TestFlight still needs your Apple signing team. Android, Windows and Linux are not yet supported by this checkout.

## Build from source

Build instructions are kept separate from the end-user README so unverified
builds are not presented as supported downloads:

- [Building Particle Library](docs/development/BUILDING.md)
- [Platform support matrix](docs/development/PLATFORMS.md)

The short macOS path (verified):

```bash
# Put pdgall-2026.0.sqlite in assets/ first; see assets/README.md.
flutter pub get
flutter test
flutter build macos --release
open "build/macos/Build/Products/Release/Particle Library.app"
```

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

- [Documentation index](docs/README.md)
- [Product design](docs/design/PDG_App_Design.md)
- [Data atlas](docs/design/PDGall_Data_Atlas.md)
- [Math conversion rules](docs/design/Math_Conversion.md)
- [Decay structure design](docs/design/Decay_Structure_Design.md)
- [Toolchain record](docs/development/Toolchain_Record.md)
- [Roadmap and platform work](docs/development/ROADMAP.md)
- [Licensing notes](docs/development/LICENSING.md)
- [Update checks](docs/development/UPDATES.md)
- [Releasing](docs/development/RELEASING.md)

## License

- **Application code:** Mozilla Public License 2.0 (MPL-2.0); see [LICENSE](LICENSE).
  Source: <https://github.com/fkguo/Particle-Library>.
  Copyright 2026 Particle Library contributors.
- **PDG data snapshot:** CC BY 4.0, with attribution to the Particle Data
  Group. The MPL-2.0 license does **not** cover the data.
- **PDG review PDFs:** not bundled; downloaded from the PDG and subject to
  PDG's terms.
- **Third-party packages:** see [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).

This is an independent application, not an official PDG product.
