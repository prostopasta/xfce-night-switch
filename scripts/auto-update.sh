#!/bin/bash
# Checks for a new xfce-night-switch release once per day.
# If a newer .deb is found, downloads it and offers installation via pkexec.

export DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$(id -u)/bus"
export DISPLAY=:0

SHARE="${XFCE_NIGHT_SWITCH_DIR:-/usr/share/xfce-night-switch}"
SWITCHER_CONFIG="$HOME/.config/theme-switcher/config"
CHECK_STAMP="$HOME/.cache/theme-switcher/last-update-check"
REPO="prostopasta/xfce-night-switch"

APP_LANG="en"
[ -f "$SWITCHER_CONFIG" ] && source "$SWITCHER_CONFIG"

# Load locale strings
S_UPDATE_TITLE="xfce-night-switch update"
S_UPDATE_TEXT="New version <b>v%s</b> available (current: v%s).\n\nInstall now?"
S_UPDATE_BTN_INSTALL="Install"
S_UPDATE_BTN_LATER="Later"
S_UPDATE_DONE="Updated to v%s successfully.\nRestart your session to apply changes."
S_UPDATE_ERR="Update failed. Install manually:\n  sudo dpkg -i /tmp/xfce-night-switch.deb"
_locale="${HOME}/.config/theme-switcher/locales/${APP_LANG:-en}.sh"
[ ! -f "$_locale" ] && _locale="${SHARE}/locales/${APP_LANG:-en}.sh"
# shellcheck source=/dev/null
[ -f "$_locale" ] && source "$_locale"

# Throttle: skip if checked within the last 24 hours
NOW=$(date +%s)
if [ -f "$CHECK_STAMP" ]; then
    LAST=$(cat "$CHECK_STAMP" 2>/dev/null || echo 0)
    [ $(( NOW - LAST )) -lt 86400 ] && exit 0
fi
mkdir -p "$(dirname "$CHECK_STAMP")"
echo "$NOW" > "$CHECK_STAMP"

# Current version: VERSION file (deb install) or dpkg
CURRENT=$(cat "$SHARE/VERSION" 2>/dev/null | tr -d 'v \n')
if [ -z "$CURRENT" ]; then
    CURRENT=$(dpkg -l xfce-night-switch 2>/dev/null | awk '/^ii/{print $3}' | head -1)
fi
[ -z "$CURRENT" ] && exit 0

# Fetch latest release info from GitHub
API_JSON=$(curl -sf --max-time 10 \
    "https://api.github.com/repos/${REPO}/releases/latest" 2>/dev/null)
[ -z "$API_JSON" ] && exit 0

LATEST=$(echo "$API_JSON" | grep '"tag_name"' | cut -d'"' -f4 | sed 's/^v//')
[ -z "$LATEST" ] && exit 0

# Already up to date?
NEWER=$(printf '%s\n%s' "$CURRENT" "$LATEST" | sort -V | tail -1)
[ "$NEWER" = "$CURRENT" ] && exit 0

# Find .deb download URL
DEB_URL=$(echo "$API_JSON" | grep '"browser_download_url"' | grep '\.deb"' \
          | cut -d'"' -f4 | head -1)
[ -z "$DEB_URL" ] && exit 0

# Download .deb (reuse if already downloaded for this version)
DEB_FILE="/tmp/xfce-night-switch-${LATEST}.deb"
if [ ! -f "$DEB_FILE" ]; then
    wget -q -O "$DEB_FILE" "$DEB_URL" 2>/dev/null \
        || { rm -f "$DEB_FILE"; exit 0; }
fi

# Ask user
TEXT=$(printf "$S_UPDATE_TEXT" "$LATEST" "$CURRENT")
yad --question \
    --title="$S_UPDATE_TITLE" \
    --text="$TEXT" \
    --image=system-software-update \
    --width=420 \
    --button="${S_UPDATE_BTN_INSTALL}:0" \
    --button="${S_UPDATE_BTN_LATER}:1" \
    2>/dev/null || exit 0

# Install via pkexec (PolicyKit GUI password prompt)
if pkexec dpkg -i "$DEB_FILE" 2>/dev/null; then
    rm -f "$DEB_FILE"
    # Re-run per-user setup: updates symlinks, locale files, services
    xfce-night-switch-setup 2>/dev/null || true
    MSG=$(printf "$S_UPDATE_DONE" "$LATEST")
    yad --info --title="$S_UPDATE_TITLE" --text="$MSG" \
        --image=dialog-information \
        --timeout=6 --no-buttons --width=400 2>/dev/null &
else
    yad --error --title="$S_UPDATE_TITLE" --text="$S_UPDATE_ERR" \
        --width=420 2>/dev/null &
fi
