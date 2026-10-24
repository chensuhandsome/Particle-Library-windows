#!/usr/bin/env bash
# Add a PDFium dSYM to an iOS archive before uploading it.
#
# The PDFium xcframework that pdfrx downloads ships its release binary without
# a dSYM. App Store Connect then warns that the archive has no dSYM for
# PDFium.framework (UUID 4C4C44A5-...). The binary still carries its UUID, so
# dsymutil can produce a dSYM with the matching UUID (it has little or no
# DWARF, so symbolication inside PDFium stays limited, but the archive passes
# validation).
#
# Run it after `flutter build ipa` and upload the *archive* from Xcode
# Organizer (Transporter uploads only the .ipa, without the dSYMs).
set -euo pipefail
cd "$(dirname "$0")/.."

ARCHIVE="${1:-build/ios/archive/Runner.xcarchive}"
FRAMEWORK="$ARCHIVE/Products/Applications/Runner.app/Frameworks/PDFium.framework/PDFium"
if [[ ! -f "$ARCHIVE/Info.plist" ]]; then
  echo "No archive at $ARCHIVE; run flutter build ipa first." >&2
  exit 1
fi
if [[ ! -f "$FRAMEWORK" ]]; then
  echo "No PDFium framework in $ARCHIVE." >&2
  exit 1
fi

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
dsymutil "$FRAMEWORK" -o "$TMP/PDFium.framework.dSYM" 2>&1 | grep -v '^warning:.*unable to open object file' || true
rm -rf "$ARCHIVE/dSYMs/PDFium.framework.dSYM"
cp -R "$TMP/PDFium.framework.dSYM" "$ARCHIVE/dSYMs/PDFium.framework.dSYM"
echo "Added $ARCHIVE/dSYMs/PDFium.framework.dSYM"
dwarfdump --uuid "$ARCHIVE/dSYMs/PDFium.framework.dSYM"
