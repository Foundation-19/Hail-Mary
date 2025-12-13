#!/bin/bash
set -euo pipefail

# dependencies.sh should define BYOND_MAJOR and BYOND_MINOR
source dependencies.sh

BYOND_ROOT="$HOME/BYOND"
BYOND_VERSION="${BYOND_MAJOR}.${BYOND_MINOR}"
BYOND_URL="https://github.com/YOURORG/YOURREPO/releases/download/byond/515.1633_byond_linux.zip"

# Check if BYOND is already installed
if [ -f "$BYOND_ROOT/byond/bin/dm" ]; then
    echo "Using cached BYOND $BYOND_VERSION."
    exit 0
fi

echo "Installing BYOND $BYOND_VERSION..."

# Clean old BYOND folder
rm -rf "$BYOND_ROOT"
mkdir -p "$BYOND_ROOT"

cd "$BYOND_ROOT"

# Download the BYOND zip
if ! curl -fL "$BYOND_URL" -o byond.zip; then
    echo "BYOND download failed! Check that the URL exists and is accessible."
    exit 1
fi

# Verify zip
if ! unzip -t byond.zip >/dev/null; then
    echo "BYOND zip is corrupt"
    exit 1
fi

# Extract zip
unzip byond.zip
rm byond.zip

# Run BYOND setup (if required by Linux BYOND package)
cd byond
make here || { echo "BYOND setup failed"; exit 1; }
cd ~

echo "BYOND $BYOND_VERSION installed successfully."

