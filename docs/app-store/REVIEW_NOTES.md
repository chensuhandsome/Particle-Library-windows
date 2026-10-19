# App Review notes

## App summary

Particle Library is an offline reader for the Particle Data Group (PDG) Review
of Particle Physics. It is an independent open-source app, not an official PDG
product. No account or login is required.

## What the reviewer should try

1. Launch the app. The bundled PDG 2026 snapshot opens with no network.
2. Search for `D0`, open the particle page, and inspect properties/decays.
3. Open Notes → New, create a note, add a tag, and attach a PDG anchor.
4. Open Reviews from the top bar, download one review PDF, select text and
   create a highlight; tap the highlight to show range handles.
5. Open Settings → About and coverage → Check for updates. On iOS this reports
   that updates are delivered by the App Store and does not open GitHub.

A network connection is required only for downloading PDG review PDFs and
optional Crossref/INSPIRE lookups. Core PDG data, notes and search work
offline.

## Privacy

The app has no account, analytics, advertising or developer-operated server.
See the privacy policy URL supplied in App Store Connect. User notes and
highlights are stored locally. There are no plans to add analytics or account
services.

## Attribution and naming

- PDG data are used under CC BY 4.0 with attribution in the app.
- The app name is “Particle Library”; it does not use “PDG” as its name.
- The app is not affiliated with or endorsed by the Particle Data Group.
- Source code: <https://github.com/fkguo/Particle-Library> (MPL-2.0).

## Notes for the reviewer

- App Store builds must be compiled with
  `--dart-define=APP_STORE_APP_ID=<Apple ID>`; without it the App Store button
  is hidden, but the app still reports that iOS updates are managed by the App
  Store.
- The iOS build does not link users to GitHub for updates.
