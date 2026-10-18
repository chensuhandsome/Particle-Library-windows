# assets/

The PDG snapshot is **not stored in this repository** (64 MiB, CC BY 4.0).
Place it here before building:

```bash
cp /path/to/pdgall-2026.0.sqlite assets/pdgall-2026.0.sqlite
```

Download it from the official PDG API page:

```text
https://pdg.lbl.gov/2026/api/index.html
```

The direct file is:

```text
https://pdg.lbl.gov/2026/api/pdgall-2026.0.sqlite
```

It is excluded by `.gitignore`. Its SHA-256 must match
`c82dab0c0a7c5264f23508066cabb8df9eacc1dbfc83c8d20fade6053394ba8a`;
the app verifies this before opening the database.

At runtime the app stages the asset into its own application-support container,
verifies it, and then opens it read-only. If the file is missing, Flutter
reports an asset-packaging error during `flutter run`, `flutter test` or a
platform build.

`brand/` contains the shared owl/Quark artwork used by the macOS Dock, app
header, favicon-style marks and idle animation.
