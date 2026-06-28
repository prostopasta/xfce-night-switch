#!/bin/bash

export DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$(id -u)/bus"
export DISPLAY=:0

PID=$(pgrep -u "$LOGNAME" xfce4-session | head -n 1)
[ -z "$PID" ] && { echo "No XFCE session."; exit 1; }

LIGHT_THEME="Adwaita"
DARK_THEME="Adwaita-dark"
TERM_PROFILE_LIGHT="default"
TERM_PROFILE_DARK="default"
TERM_CONFIG="$HOME/.config/terminator/config"
APP_DESKTOP="$HOME/.local/share/applications/toggle-theme.desktop"
SWITCHER_CONFIG="$HOME/.config/xfce-night-switch/config"
MANUAL_OVERRIDE="$HOME/.config/xfce-night-switch/manual_override"

# Defaults
ICON_DAY="weather-clear"
ICON_NIGHT="$HOME/.local/share/icons/hicolor/scalable/apps/theme-moon.svg"
AUTO_SWITCHER="enabled"
AUTO_MODE="time"
DAY_START="07:00"
DAY_END="18:00"
LATITUDE=""
LONGITUDE=""
[ -f "$SWITCHER_CONFIG" ] && source "$SWITCHER_CONFIG"

# Set after source so XFCE_PLUGIN_ID from config is available
PANEL_LAUNCHER_DIR="$HOME/.config/xfce4/panel/launcher-${XFCE_PLUGIN_ID:-101}"

# Load locale strings for localized tooltips
S_TOOLTIP_DAY="Day mode (click to switch to night)"
S_TOOLTIP_NIGHT="Night mode (click to switch to day)"
_locale="${HOME}/.config/xfce-night-switch/locales/${APP_LANG:-en}.sh"
[ ! -f "$_locale" ] && _locale="${XFCE_NIGHT_SWITCH_DIR:-/usr/share/xfce-night-switch}/locales/${APP_LANG:-en}.sh"
# shellcheck source=/dev/null
[ -f "$_locale" ] && source "$_locale"

[ "$AUTO_SWITCHER" != "enabled" ] && exit 0

update_field() {
    local file=$1 field=$2 value=$3
    [ -f "$file" ] && [ -s "$file" ] || return
    local tmp; tmp=$(mktemp)
    sed "s|^${field}=.*|${field}=${value}|" "$file" > "$tmp"
    [ -s "$tmp" ] && cat "$tmp" > "$file"
    rm -f "$tmp"
}

update_panel_icon() {
    local icon=$1 tooltip=$2
    for f in "$PANEL_LAUNCHER_DIR"/*.desktop; do
        [ -f "$f" ] || continue
        grep -q "toggle-theme\|Toggle Theme" "$f" 2>/dev/null || continue
        update_field "$f" "Icon" "$icon"
        update_field "$f" "Comment" "$tooltip"
    done
    update_field "$APP_DESKTOP" "Icon" "$icon"
    update_field "$APP_DESKTOP" "Comment" "$tooltip"
}

# Switch Terminator profile in all open windows via DBus,
# and update layout profile references for new terminals.
terminator_switch() {
    local profile=$1
    # Update layout profile = ... in config (for new terminals)
    local tmp; tmp=$(mktemp)
    sed "s/^\(\s\+profile = \).*/\1${profile}/" "$TERM_CONFIG" > "$tmp"
    [ -s "$tmp" ] && cat "$tmp" > "$TERM_CONFIG"
    rm -f "$tmp"
    # Switch all open Terminator windows via DBus
    python3 -c "
import dbus, os, sys
os.environ['DBUS_SESSION_BUS_ADDRESS'] = 'unix:path=/run/user/' + str(os.getuid()) + '/bus'
try:
    bus = dbus.SessionBus()
    name = next((str(n) for n in bus.list_names() if 'tenshu.Terminator' in str(n)), None)
    if name:
        proxy = bus.get_object(name, '/net/tenshu/Terminator2')
        dbus.Interface(proxy, name).switch_profile_all({'profile': sys.argv[1]})
except Exception: pass
" "$profile" 2>/dev/null || true
}

apply_theme() {
    local theme_name=$1 mode=$2 term_profile=$3 icon=$4 tooltip=$5
    echo ">>> $mode ($theme_name)"
    xfconf-query -c xsettings -p /Net/ThemeName -s "$theme_name"
    xfconf-query -c xfwm4 -p /general/theme -s "$theme_name"
    gsettings set org.gnome.desktop.interface color-scheme "$mode" 2>/dev/null
    gsettings set org.gnome.desktop.interface gtk-theme "$theme_name" 2>/dev/null
    terminator_switch "$term_profile"
    update_panel_icon "$icon" "$tooltip"
}

# --- Compute day boundaries ---
if [ "$AUTO_MODE" = "location" ] && [ -n "$LATITUDE" ] && [ -n "$LONGITUDE" ]; then
    times=$(python3 "${XFCE_NIGHT_SWITCH_DIR:-$HOME/.local/bin}/sunrise-sunset.py" "$LATITUDE" "$LONGITUDE" both 2>/dev/null)
    if [ -n "$times" ]; then
        DAY_START=$(echo "$times" | cut -d' ' -f1)
        DAY_END=$(echo "$times"   | cut -d' ' -f2)
    fi
fi

NOW=$(date +%H:%M)
CURRENT=$(xfconf-query -c xsettings -p /Net/ThemeName 2>/dev/null)

# Determine target mode
if [[ "$NOW" > "$DAY_START" || "$NOW" == "$DAY_START" ]] && [[ "$NOW" < "$DAY_END" ]]; then
    WANT_THEME="$LIGHT_THEME"
    WANT_MODE="default"
    WANT_TERM_PROFILE="$TERM_PROFILE_LIGHT"
    WANT_ICON="$ICON_DAY"
    WANT_TOOLTIP="$S_TOOLTIP_DAY"
else
    WANT_THEME="$DARK_THEME"
    WANT_MODE="prefer-dark"
    WANT_TERM_PROFILE="$TERM_PROFILE_DARK"
    WANT_ICON="$ICON_NIGHT"
    WANT_TOOLTIP="$S_TOOLTIP_NIGHT"
fi

# Respect manual override: skip until schedule agrees
if [ -f "$MANUAL_OVERRIDE" ]; then
    OVERRIDE=$(cat "$MANUAL_OVERRIDE")
    [ "$WANT_THEME" = "$LIGHT_THEME" ] && WANT_NAME="light" || WANT_NAME="dark"
    if [ "$OVERRIDE" != "$WANT_NAME" ]; then
        exit 0
    else
        rm -f "$MANUAL_OVERRIDE"
    fi
fi

# Apply GTK theme only if changed; always sync Terminator profile
[ "$WANT_THEME" = "$LIGHT_THEME" ] && WANT_NAME="light" || WANT_NAME="dark"
if [ "$CURRENT" != "$WANT_THEME" ]; then
    apply_theme "$WANT_THEME" "$WANT_MODE" "$WANT_TERM_PROFILE" "$WANT_ICON" "$WANT_TOOLTIP"
    if [ "${MONITOR_DIMMING:-disabled}" = "enabled" ]; then
        _script="${XFCE_NIGHT_SWITCH_DIR:-$HOME/.local/bin}/monitor-dimming.sh"
        [ -x "$_script" ] && "$_script" "$WANT_NAME" &
    fi
else
    terminator_switch "$WANT_TERM_PROFILE"
fi
