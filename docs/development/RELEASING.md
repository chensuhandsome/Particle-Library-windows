# Releasing Particle Library

## Bundle identifier

The app uses the reverse-DNS identifier
`io.github.fkguo.particlelibrary`, based on the GitHub Pages namespace.

Update it consistently in:

- `macos/Runner/Configs/AppInfo.xcconfig`
- `ios/Runner.xcodeproj/project.pbxproj` (Runner and RunnerTests)

Changing the bundle identifier creates a new app data container; local notes,
favorites and settings from the old ID are not automatically visible to the new
app. Do this before distributing the first public build, or provide an explicit
data migration.

## PDG snapshot

Do **not** publish the 64 MB `pdgall-2026.0.sqlite` as a GitHub release asset.
The authoritative copy is on the PDG API page:

<https://pdg.lbl.gov/2026/api/index.html>

The app bundles the snapshot for end users. Source builders and CI download it
from:

```text
https://pdg.lbl.gov/2026/api/pdgall-2026.0.sqlite
```

CI uses the repository variable `PDG_SNAPSHOT_URL` (set to that official URL)
and verifies SHA-256
`c82dab0c0a7c5264f23508066cabb8df9eacc1dbfc83c8d20fade6053394ba8a` before
running tests.

Prepare local release assets with:

```bash
tool/release_assets.sh
```

The script verifies the snapshot hash, runs analyze/tests, builds the macOS app,
zips it, and writes checksums. It deliberately does not publish, include the
snapshot, or notarize.

## Signing and notarization

For a public macOS download, use a Developer ID Application certificate,
Hardened Runtime, `notarytool` and `stapler`; verify with `spctl`. The current
local build is ad-hoc/development-signed and is not a public artifact.

## Update channel

Publish a tag `vX.Y.Z` (build number in `pubspec.yaml`'s `+N` suffix) in the
public repository. The updater reads
`https://api.github.com/repos/fkguo/Particle-Library/releases/latest`.
Validate the manual check on a release build before announcing.

## Checklist

- [ ] bundle identifier changed and documented
- [ ] version and build number bumped
- [ ] snapshot asset uploaded, SHA-256 verified, CC BY attribution included
- [ ] `flutter analyze`, `flutter test` green with the snapshot
- [ ] macOS Developer ID + notarization + `spctl` check, or no public macOS binary
- [ ] iOS physical install and trust checked; TestFlight only with a paid team
- [ ] README/requirements and update channel consistent
- [ ] release notes and checksums attached
