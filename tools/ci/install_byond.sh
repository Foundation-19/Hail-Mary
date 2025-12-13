#!/bin/bash
set -euo pipefail

BYOND_ROOT="$HOME/BYOND"
BYOND_VERSION="515.1633"
BYOND_URL="https://github.com/YOURORG/YOURREPO/releases/download/byond/${BYOND_VERSION}_byond_linux.zip"

# Use cached version if available
if [ -d "$BYOND_ROOT/byond/bin" ] && grep -Fxq "$BYOND_VERSION" "$BYOND_ROOT/version.txt"; then
    echo "Using cached BYOND $BYOND_VERSION."
    exit 0
fi

echo "Installing BYOND $BYOND_VERSION..."
rm -rf "$BYOND_ROOT"
mkdir -p "$BYOND_ROOT"
cd "$BYOND_ROOT"

# download and verify
curl -fL "$BYOND_URL" -o byond.zip
if [ ! -s byond.zip ]; then
    echo "BYOND zip download failed!"
    exit 1
fi
unzip -t byond.zip >/dev/null || { echo "BYOND zip is corrupt"; exit 1; }

# extract
unzip -q byond.zip
rm byond.zip

cd byond
make here
echo "$BYOND_VERSION" > "$BYOND_ROOT/version.txt"
cd ~/
