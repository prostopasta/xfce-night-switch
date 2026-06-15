#!/bin/bash
# Quick installer for xfce-night-switch.
# Downloads and installs the latest .deb release.
#
# Usage:
#   bash <(curl -fsSL https://github.com/prostopasta/xfce-night-switch/releases/latest/download/install-latest.sh)
#   bash <(wget -qO- https://github.com/prostopasta/xfce-night-switch/releases/latest/download/install-latest.sh)
set -euo pipefail

REPO="prostopasta/xfce-night-switch"
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

echo "=== xfce-night-switch installer ==="
echo ""

# Install prerequisites if missing
MISSING=()
for pkg in curl wget yad python3 python3-dbus; do
    dpkg -l "$pkg" >/dev/null 2>&1 || MISSING+=("$pkg")
done
if [ ${#MISSING[@]} -gt 0 ]; then
    echo "Installing missing prerequisites: ${MISSING[*]}"
    sudo apt-get install -y "${MISSING[@]}"
    echo ""
fi

# Fetch latest release info
echo "Fetching latest release..."
API_JSON=$(curl -fsSL "https://api.github.com/repos/${REPO}/releases/latest")
DEB_URL=$(echo "$API_JSON" | grep '"browser_download_url"' | grep '\.deb"' \
          | cut -d'"' -f4 | head -1)
VERSION=$(echo "$API_JSON" | grep '"tag_name"' | cut -d'"' -f4)

if [ -z "$DEB_URL" ]; then
    echo "Error: could not find .deb asset in latest release." >&2
    exit 1
fi

echo "Downloading xfce-night-switch ${VERSION}..."
wget -q --show-progress -O "$TMP/xfce-night-switch.deb" "$DEB_URL"

echo ""
echo "Installing (requires sudo)..."
sudo dpkg -i "$TMP/xfce-night-switch.deb"

echo ""
echo "Run the following to complete setup for your user:"
echo "  xfce-night-switch-setup"
