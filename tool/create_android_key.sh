#!/usr/bin/env bash
# Create the Android release signing key, outside the repository.
#
# Run it in a terminal you type into: it asks for the passphrase itself, so the
# passphrase is never on a command line, in shell history, or in this
# repository. It writes
#   ~/.android-keys/particle-library/particle-library-release.jks
#   ~/.android-keys/particle-library/key.properties
# which the Gradle build finds on its own. Set PARTICLE_LIBRARY_KEY_DIR to use
# another folder (then point PARTICLE_LIBRARY_KEY_PROPERTIES at its
# key.properties when building).
#
# Back up both files and keep the passphrase somewhere separate. A lost key
# means no later APK can update an installed copy of the app. The script never
# overwrites an existing key for that reason.
set -euo pipefail

DIR="${PARTICLE_LIBRARY_KEY_DIR:-$HOME/.android-keys/particle-library}"
KEYSTORE="$DIR/particle-library-release.jks"
PROPS="$DIR/key.properties"
ALIAS="particle-library"

if [[ -e "$KEYSTORE" || -e "$PROPS" ]]; then
  echo "A key already exists in $DIR; not touching it." >&2
  exit 1
fi

KEYTOOL=""
for candidate in \
  "${JAVA_HOME:+$JAVA_HOME/bin/keytool}" \
  "$HOME/Library/Java/JavaVirtualMachines/temurin-17.jdk/Contents/Home/bin/keytool" \
  "$(command -v keytool || true)"; do
  if [[ -n "$candidate" && -x "$candidate" ]] && "$candidate" -help >/dev/null 2>&1; then
    KEYTOOL="$candidate"
    break
  fi
done
if [[ -z "$KEYTOOL" ]]; then
  echo "keytool (part of a JDK) not found; install JDK 17 or set JAVA_HOME." >&2
  exit 1
fi

# PARTICLE_LIBRARY_STOREPASS lets a script supply the passphrase; by hand, leave
# it unset and type it when asked.
if [[ -n "${PARTICLE_LIBRARY_STOREPASS:-}" ]]; then
  PASSPHRASE="$PARTICLE_LIBRARY_STOREPASS"
else
  read -rsp "Choose a passphrase for the key (not echoed): " PASSPHRASE
  echo
  read -rsp "Type it again: " AGAIN
  echo
  if [[ "$PASSPHRASE" != "$AGAIN" ]]; then
    echo "The two entries differ; nothing was created." >&2
    exit 1
  fi
fi
# key.properties is read as ISO-8859-1 by Gradle, so keep to plain ASCII.
if [[ ${#PASSPHRASE} -lt 8 ]]; then
  echo "Use at least 8 characters; nothing was created." >&2
  exit 1
fi
if printf '%s' "$PASSPHRASE" | LC_ALL=C grep -q '[^ -~]'; then
  echo "Use printable ASCII characters only; nothing was created." >&2
  exit 1
fi
if [[ "$PASSPHRASE" != "${PASSPHRASE# }" || "$PASSPHRASE" != "${PASSPHRASE% }" ]]; then
  echo "Do not start or end the passphrase with a space; nothing was created." >&2
  exit 1
fi

umask 077
mkdir -p "$DIR"
WORK="$(mktemp -d "$DIR/.new.XXXXXX")"
trap 'rm -rf "$WORK"' EXIT
export PARTICLE_LIBRARY_PASSPHRASE="$PASSPHRASE"

"$KEYTOOL" -genkeypair \
  -keystore "$WORK/key.jks" -storetype PKCS12 \
  -alias "$ALIAS" -keyalg RSA -keysize 4096 -validity 10000 \
  -dname "CN=Particle Library" \
  -storepass:env PARTICLE_LIBRARY_PASSPHRASE \
  -keypass:env PARTICLE_LIBRARY_PASSPHRASE

# .properties files treat a backslash as an escape.
escape() { printf '%s' "${1//\\/\\\\}"; }
{
  printf 'storeFile=%s\n' "$(escape "$KEYSTORE")"
  printf 'storePassword=%s\n' "$(escape "$PASSPHRASE")"
  printf 'keyAlias=%s\n' "$ALIAS"
  printf 'keyPassword=%s\n' "$(escape "$PASSPHRASE")"
} >"$WORK/key.properties"

mv "$WORK/key.jks" "$KEYSTORE"
mv "$WORK/key.properties" "$PROPS"
chmod 600 "$KEYSTORE" "$PROPS"

echo
echo "Created $KEYSTORE"
echo "Created $PROPS"
echo "Certificate fingerprint (public; compare it with the one in a built APK):"
"$KEYTOOL" -list -keystore "$KEYSTORE" -alias "$ALIAS" \
  -storepass:env PARTICLE_LIBRARY_PASSPHRASE | grep -i 'SHA-\?256\|SHA256' || true
echo
echo "Now back up the folder $DIR and store the passphrase separately"
echo "(for example in a password manager). Neither can be recovered if lost."
