#!/bin/bash
set -euo pipefail

source dependencies.sh

if [ -d "$HOME/BYOND/byond/bin" ] && grep -Fxq "${BYOND_MAJOR}.${BYOND_MINOR}" $HOME/BYOND/version.txt; then
	echo "Using cached directory."
else
	echo "Setting up BYOND."
	rm -rf "$HOME/BYOND"
	mkdir -p "$HOME/BYOND"
	cd "$HOME/BYOND"

	# download
	curl -L "https://secure.byond.com/download/build/${BYOND_MAJOR}/${BYOND_MAJOR}.${BYOND_MINOR}_byond_linux.zip" -o byond.zip

	# verify
	if [ ! -s byond.zip ]; then
		echo "BYOND zip download failed!"
		exit 1
	fi
	unzip -t byond.zip >/dev/null || { echo "BYOND zip is corrupt"; exit 1; }

	# extract
	unzip byond.zip
	rm byond.zip

	cd byond
	make here
	echo "$BYOND_MAJOR.$BYOND_MINOR" > "$HOME/BYOND/version.txt"
	cd ~/
fi
