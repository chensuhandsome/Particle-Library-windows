# Releasing Particle Library

## Bundle identifier

The repository currently uses the placeholder `com.example.pdgapp`.
Before a public binary, choose a reverse-DNS ID you control, for example:

```text
com.fkguo.particlelibrary
```

Update it consistently in:

- `macos/Runner/Configs/AppInfo.xcconfig`
- `ios/Runner.xcodeproj/project.pbxproj` (Runner and RunnerTests)

Changing the bundle identifier creates a new app data container; local notes,
favorites and settings from the old ID are not automatically visible to the new
app. Do this before distributing the first public build, or provide an explicit
data migration.

## PDG snapshot as a release asset

Yes: publish the exact `pdgall-2026.0.sqlite` file as a release asset next to
the installers. It is 64 MB, CC BY 4.0, and must carry the PDG attribution.
Include its SHA-256 in the release notes and in `SHA256SUMS.txt`.

Do **not** commit the snapshot to git. CI can fetch the public release asset via
the repository variable `PDG_SNAPSHOT_URL`.

Prepare local assets with:

```bash
tool/release_assets.sh
```

The script verifies the snapshot hash, runs analyze/tests, builds the macOS app,
zips it, copies the snapshot and writes checksums. It deliberately does not
publish or notarize.

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
