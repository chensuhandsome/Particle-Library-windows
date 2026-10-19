# Android

Particle Library now has an Android platform project in `android/`.

## Requirements

- Android SDK Platform 36 and Build Tools 36
- JDK 17
- Flutter 3.47.7
- A device or emulator with Android 7.0+ (API 24)

## Build

```bash
export JAVA_HOME="$HOME/Library/Java/JavaVirtualMachines/temurin-17.jdk/Contents/Home"
export ANDROID_HOME="$HOME/Library/Android/sdk"
flutter pub get
flutter build apk --release --split-per-abi
```

Outputs:

```text
build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk
```

Most modern phones need `arm64-v8a`; the armeabi-v7a APK is for older 32-bit
devices. x86_64 is a local emulator build and is not published.

## Signing

`android/key.properties` and `android/particle-library-release.jks` are local and
gitignored. **Back up both files.** Losing the signing key means future APKs
cannot update an installed copy.

Keep the release keystore and passwords backed up. Do not
commit the keystore or passwords.

## Snapshot

The APK bundles `assets/pdgall-2026.0.sqlite` (about 64 MB). The app copies it
to private storage on first run and verifies SHA-256. The official snapshot is
downloaded from:

```text
https://pdg.lbl.gov/2026/api/pdgall-2026.0.sqlite
```

## Tests performed

- Release APK installs and launches on an Android 15 (API 35) arm64 emulator;
- Search and math rendering work (`pi0` tested);
- Snapshot staging and database counts work;
- Package id `io.github.fkguo.particlelibrary`;
- APK signed with the local release key.
