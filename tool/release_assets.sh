#!/usr/bin/env bash
# Build local macOS + Android release assets. Does not publish or notarize.
set -euo pipefail
cd "$(dirname "$0")/.."

SNAPSHOT="assets/pdgall-2026.0.sqlite"
EXPECTED="c82dab0c0a7c5264f23508066cabb8df9eacc1dbfc83c8d20fade6053394ba8a"
VERSION="$(awk '/^version:/ {print $2}' pubspec.yaml | cut -d+ -f1)"
OUT="dist/release"

if [[ ! -f "$SNAPSHOT" ]]; then
  echo "missing $SNAPSHOT" >&2
  exit 1
fi
ACTUAL="$(shasum -a 256 "$SNAPSHOT" | awk '{print $1}')"
if [[ "$ACTUAL" != "$EXPECTED" ]]; then
  echo "snapshot SHA-256 mismatch: $ACTUAL" >&2
  exit 1
fi

flutter analyze
flutter test
# Android first: it stops at once when the signing key is missing (see
# docs/development/ANDROID.md), before the slower macOS build.
# arm64-v8a only; 32-bit devices are not supported. --split-per-abi is kept so the
# build number stays above the 0.1.x arm64 APKs (it adds 2000 to the version code).
flutter build apk --release --split-per-abi --target-platform android-arm64
flutter build macos --release

APP="build/macos/Build/Products/Release/Particle Library.app"
# Re-signing replaces the signature, and without --preserve-metadata the
# entitlements flutter embedded (App Sandbox, network, file access) are dropped:
# the shipped app would run unsandboxed and keep its data in a different folder
# from the sandboxed builds.
codesign --force --deep --sign - --preserve-metadata=entitlements \
  --timestamp=none "$APP"
if ! codesign -d --entitlements - "$APP" 2>&1 | grep -q 'com.apple.security.app-sandbox'; then
  echo "the signed app lost its App Sandbox entitlement" >&2
  exit 1
fi

rm -rf "$OUT"
mkdir -p "$OUT"
STAGE="$(mktemp -d)"
trap 'rm -rf "$STAGE"' EXIT
ditto "$APP" "$STAGE/Particle Library.app"
ln -s /Applications "$STAGE/Applications"
hdiutil create -volname "Particle Library" -srcfolder "$STAGE" -ov -format UDZO \
  "$OUT/Particle-Library-${VERSION}-macOS-universal.dmg" >/dev/null
ditto -c -k --sequesterRsrc --keepParent \
  "$APP" \
  "$OUT/Particle-Library-${VERSION}-macOS-universal.zip"
cp build/app/outputs/flutter-apk/app-arm64-v8a-release.apk \
  "$OUT/Particle-Library-${VERSION}-Android-arm64-v8a.apk"

# Show who signed the APKs; the digest must equal the one recorded in
# docs/development/ANDROID.md, or installed copies cannot be updated.
APKSIGNER="$(ls -d "${ANDROID_HOME:-$HOME/Library/Android/sdk}"/build-tools/*/apksigner 2>/dev/null | sort -V | tail -1 || true)"
if [[ -n "$APKSIGNER" ]]; then
  for apk in "$OUT"/*.apk; do
    echo "$(basename "$apk"):"
    "$APKSIGNER" verify --print-certs "$apk" | grep 'certificate SHA-256 digest'
  done
else
  echo "apksigner not found; check the APK signer by hand before publishing." >&2
fi

(
  cd "$OUT"
  shasum -a 256 Particle-Library-"${VERSION}"-* > SHA256SUMS.txt
)
echo "Release assets prepared in $OUT/."
echo "The macOS app is ad-hoc signed and not notarized; label previews accordingly."
