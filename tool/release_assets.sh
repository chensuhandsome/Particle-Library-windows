#!/usr/bin/env bash
# Build a local macOS release bundle and the snapshot release assets.
#
# This script does not publish anything and does not sign/notarize the app.
# Review docs/development/RELEASING.md before uploading.
set -euo pipefail
cd "$(dirname "$0")/.."

SNAPSHOT="assets/pdgall-2026.0.sqlite"
EXPECTED="c82dab0c0a7c5264f23508066cabb8df9eacc1dbfc83c8d20fade6053394ba8a"

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
mkdir -p dist/release
rm -rf "dist/release/Particle Library.app"
ditto "build/macos/Build/Products/Release/Particle Library.app" \
      "dist/release/Particle Library.app"
ditto -c -k --sequesterRsrc --keepParent \
  "dist/release/Particle Library.app" \
  "dist/release/Particle-Library-macOS.zip"
cp "$SNAPSHOT" "dist/release/pdgall-2026.0.sqlite"
(
  cd dist/release
  shasum -a 256 "Particle-Library-macOS.zip" "pdgall-2026.0.sqlite" \
    > SHA256SUMS.txt
)
echo "Release assets prepared in dist/release/."
echo "The macOS app is not Developer ID signed/notarized yet; do not publish it as a public download."
