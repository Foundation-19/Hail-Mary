#!/usr/bin/env bash
set -euo pipefail

source dependencies.sh

mkdir -p ~/.byond/bin
# retry on transient network/TLS handshake failures against the GitHub release CDN
wget -nv --tries=8 --waitretry=10 --retry-connrefused --retry-on-host-error --retry-on-http-error=429,500,502,503,504 -O ~/.byond/bin/librust_g.so "https://github.com/tgstation/rust-g/releases/download/$RUST_G_VERSION/librust_g.so"
chmod +x ~/.byond/bin/librust_g.so
ldd ~/.byond/bin/librust_g.so
