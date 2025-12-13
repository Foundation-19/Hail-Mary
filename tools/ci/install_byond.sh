#!/bin/bash
set -euo pipefail

source dependencies.sh

BYOND_ROOT="$HOME/BYOND"
BYOND_VERSION="${BYOND_MAJOR}.${BYOND_MINOR}"
BYOND_URL="https://github.com/YOURORG/YOURREPO/releases/download/byond/${BYOND_VERSION}_byond_linux.zip"

if [ -d "$BYOND_ROOT/byond/bin" ] && grep -Fxq "$BYOND_VERSION" "$BYOND_ROOT/version.txt"; then
    echo "Using cached BYOND."
    exit 0
fi

echo "Installing BYOND $BYOND_VERSION"
rm -rf "$BYOND_ROOT"
mkdir -p "$BYOND_ROOT"
cd "$BYOND_ROOT"

curl -fL "$BYOND_URL" -o byond.zip
unzip -q byond.zip
rm byond.zip

cd byond
make here

echo "$BYOND_VERSION" > "$BYOND_ROOT/version.txt"
