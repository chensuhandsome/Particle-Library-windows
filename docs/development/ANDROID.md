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
flutter build apk --release --split-per-abi --target-platform android-arm64
```

Output:

```text
build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
```

Only `arm64-v8a` is built and published; 32-bit devices (`armeabi-v7a`) are not
supported from 0.2.0 on. `--split-per-abi` is kept on purpose: it adds 2000 to
the version code, which keeps new builds above the arm64 APKs of 0.1.x. An
x86_64 emulator build is local only and is not published.

## Signing

Release APKs are signed with a key kept **outside the repository**. The release
build refuses to run without it: Gradle stops with an explanatory message, so
an unsigned APK (which no device installs) or one signed with the wrong key
cannot be produced by accident. Debug builds do not need a key.

Create the key once, in a terminal you type into:

```bash
tool/create_android_key.sh
```

The script asks for a passphrase (not echoed, never put on a command line) and
writes

```text
~/.android-keys/particle-library/particle-library-release.jks
~/.android-keys/particle-library/key.properties   (store path, alias, passphrase)
```

with owner-only permissions. It never overwrites an existing key. Gradle reads
the signing details from the first of these that exists:

1. the file named by the environment variable `PARTICLE_LIBRARY_KEY_PROPERTIES`
   (an error if it is set but missing);
2. `android/key.properties` (gitignored);
3. `~/.android-keys/particle-library/key.properties`.

### The key must be kept

Android installs an update over an existing app only when the new APK is
signed with the same key. Without the key, no later version can update an
installed copy: every user would have to uninstall (losing local data) and
reinstall. That already happened once, see the history below.

Whoever cleans up the project later — a person, a script, or an automated
agent removing stale code — must follow these rules:

- **Never delete, move, regenerate or overwrite** `~/.android-keys/` (the
  keystore and its `key.properties`), `android/key.properties`, or any
  `*.jks` / `*.keystore` file. This holds when removing obsolete code, running
  `git clean -x` or similar commands that delete ignored files, clearing build
  output, discarding old checkouts or worktrees, and migrating to a new machine
  (copy the key folder across instead).
- **Keep the signing code**: the `release` signing configuration and the
  key-presence check in `android/app/build.gradle.kts`, and
  `tool/create_android_key.sh`. They look unused in a debug-only workflow but
  are what protects the next release.
- The key is deliberately not inside the repository, because ignored files in
  the working tree are exactly what cleanup commands remove.
- Keep a backup of the whole key folder and, separately from it, the
  passphrase (for example in a password manager). Neither can be recovered.
- After building a release, confirm the signer with
  `apksigner verify --print-certs <apk>`: the SHA-256 digest must equal the
  value recorded below.

### History

- 0.1.0 – 0.1.3 were signed with a key whose keystore was later lost and
  cannot be recreated. Its certificate SHA-256 digest, as shown by
  `apksigner verify --print-certs` on the 0.1.3 APK, is
  `d4c5d099b3cc9f0485518bce4958b4967767a4a0e2f61df5f54361772ea2c778`.
- From 0.2.0 on, releases are signed with a new key (see the digest recorded
  below). Android refuses to install an APK over an installed app that was
  signed with a different key, so **0.1.x installs cannot be updated to 0.2.0
  in place**. Users must first run Settings → Export full backup in the old
  version, uninstall it, install 0.2.0 and import the backup. Automatic
  backup is off (`allowBackup="false"`), so uninstalling deletes the local
  data; say this in the 0.2.0 release notes.

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
