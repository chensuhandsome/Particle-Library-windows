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
flutter build macos --release
flutter build apk --release --split-per-abi

codesign --force --deep --sign - --timestamp=none \
  "build/macos/Build/Products/Release/Particle Library.app"

rm -rf "$OUT"
mkdir -p "$OUT"
STAGE="$(mktemp -d)"
trap 'rm -rf "$STAGE"' EXIT
ditto "build/macos/Build/Products/Release/Particle Library.app" \
  "$STAGE/Particle Library.app"
ln -s /Applications "$STAGE/Applications"
hdiutil create -volname "Particle Library" -srcfolder "$STAGE" -ov -format UDZO \
  "$OUT/Particle-Library-${VERSION}-macOS-universal.dmg" >/dev/null
ditto -c -k --sequesterRsrc --keepParent \
  "build/macos/Build/Products/Release/Particle Library.app" \
  "$OUT/Particle-Library-${VERSION}-macOS-universal.zip"
cp build/app/outputs/flutter-apk/app-arm64-v8a-release.apk \
  "$OUT/Particle-Library-${VERSION}-Android-arm64-v8a.apk"
cp build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk \
  "$OUT/Particle-Library-${VERSION}-Android-armeabi-v7a.apk"

(
  cd "$OUT"
  shasum -a 256 Particle-Library-"${VERSION}"-* > SHA256SUMS.txt
)
echo "Release assets prepared in $OUT/."
echo "The macOS app is ad-hoc signed and not notarized; label previews accordingly."
