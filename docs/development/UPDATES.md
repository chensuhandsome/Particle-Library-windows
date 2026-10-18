# Update checks

Particle Library has a lightweight update check:

- **Automatic:** once per app start, in the background. A newer version opens a
  dialog with release notes and an “Open download page” action.
- **Manual:** Settings → About → **Check for updates**.

The check never installs anything and never blocks PDF/notes work. A failed
check is silent on startup and reported as “unavailable” for a manual check.

## Endpoint

The default endpoint is the GitHub Releases API:

```text
https://api.github.com/repos/fkguo/Particle-Library/releases/latest
```

While the repository is private, an unauthenticated request returns 404, so no
update is shown. Once the release repository is public, publishing a GitHub
Release with a larger tag is enough.

For a self-hosted or private channel, pass a manifest URL at build time:

```bash
flutter build macos --release \
  --dart-define=UPDATE_MANIFEST_URL=https://example.org/particle-library/latest.json
```

Manifest format:

```json
{
  "version": "0.2.0",
  "url": "https://example.org/particle-library/downloads",
  "notes": "Short release notes shown in the dialog."
}
```

The GitHub Releases API response (`tag_name`, `html_url`, `body`) is also
accepted. Versions are compared numerically with an optional leading `v`.

## Release checklist

1. Bump `version` in `pubspec.yaml` and `appVersion` in
   `lib/app/update_checker.dart` together.
2. Publish a GitHub Release with a tag greater than the current version.
3. Attach installers for the platforms that were actually tested.
4. Verify the manual check on each platform and the automatic dialog on one
   packaged build.
