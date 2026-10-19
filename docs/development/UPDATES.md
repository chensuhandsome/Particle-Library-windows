# Update checks

Particle Library has a lightweight update check:

- **Automatic:** once per app start, in the background. A newer version opens a
  dialog with release notes and an “Open download page” action.
- **Manual:** Settings → About and coverage → **Check for updates**.

On **iOS App Store builds**, no GitHub endpoint is contacted. Settings reports
that updates are delivered by the App Store, and an “Open the App Store” action
is shown when the build was compiled with
`--dart-define=APP_STORE_APP_ID=<numeric Apple ID>`. This keeps the iOS binary
within App Store update rules.

The check never installs anything and never blocks PDF/notes work. A failed
check is silent on startup and reported as “unavailable” for a manual check.

## Endpoint

The default check tries three endpoints in order:

1. `https://cdn.jsdelivr.net/gh/fkguo/Particle-Library@main/update.json`
2. `https://raw.githubusercontent.com/fkguo/Particle-Library/main/update.json`
3. `https://api.github.com/repos/fkguo/Particle-Library/releases/latest`

The static manifest is checked first so the check works where the GitHub API is
blocked or rate-limited. jsDelivr may cache `@main` for a while; always bump
`update.json` in the release commit. A tag alone is **not** enough.

Update checks contact jsDelivr, raw.githubusercontent.com and api.github.com;
they send no telemetry and never auto-install.

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
