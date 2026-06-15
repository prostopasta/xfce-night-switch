#!/bin/bash

export DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$(id -u)/bus"
export DISPLAY=:0

LIGHT_THEME="ZorinBlue-Light"
DARK_THEME="Mint-Y-Dark-Aqua"
TERM_PROFILE_LIGHT="AdventureTime"
TERM_PROFILE_DARK="dark-Blitz"
TERM_CONFIG="$HOME/.config/terminator/config"
APP_DESKTOP="$HOME/.local/share/applications/toggle-theme.desktop"
SWITCHER_CONFIG="$HOME/.config/theme-switcher/config"
MANUAL_OVERRIDE="$HOME/.config/theme-switcher/manual_override"

# Load icons from config
ICON_DAY="weather-clear"
ICON_NIGHT="$HOME/.local/share/icons/hicolor/scalable/apps/theme-moon.svg"
[ -f "$SWITCHER_CONFIG" ] && source "$SWITCHER_CONFIG"

# Set after source so XFCE_PLUGIN_ID from config is available
PANEL_LAUNCHER_DIR="$HOME/.config/xfce4/panel/launcher-${XFCE_PLUGIN_ID:-101}"

update_field() {
    local file=$1 field=$2 value=$3
    [ -f "$file" ] || return
    [ -s "$file" ] || return
    local tmp; tmp=$(mktemp)
    sed "s|^${field}=.*|${field}=${value}|" "$file" > "$tmp"
    cat "$tmp" > "$file"
    rm -f "$tmp"
}

update_panel_icon() {
    local icon=$1 tooltip=$2
    if [ -d "$PANEL_LAUNCHER_DIR" ]; then
        for f in "$PANEL_LAUNCHER_DIR"/*.desktop; do
            grep -q "toggle-theme\\|Toggle Theme" "$f" 2>/dev/null || continue
            update_field "$f" "Icon" "$icon"
            update_field "$f" "Comment" "$tooltip"
        done
    fi
    update_field "$APP_DESKTOP" "Icon" "$icon"
    update_field "$APP_DESKTOP" "Comment" "$tooltip"
}

# Switch Terminator profile in all open windows via DBus,
# and update layout profile references for new terminals.
terminator_switch() {
    local profile=$1
    local tmp; tmp=$(mktemp)
    sed "s/^\(\s\+profile = \).*/\1${profile}/" "$TERM_CONFIG" > "$tmp"
    [ -s "$tmp" ] && cat "$tmp" > "$TERM_CONFIG"
    rm -f "$tmp"
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
    xfconf-query -c xsettings -p /Net/ThemeName -s "$theme_name"
    xfconf-query -c xfwm4 -p /general/theme -s "$theme_name"
    gsettings set org.gnome.desktop.interface color-scheme "$mode" 2>/dev/null
    gsettings set org.gnome.desktop.interface gtk-theme "$theme_name" 2>/dev/null
    terminator_switch "$term_profile"
    update_panel_icon "$icon" "$tooltip"
}

CURRENT=$(xfconf-query -c xsettings -p /Net/ThemeName 2>/dev/null)

case "${1:-toggle}" in
    light)
        apply_theme "$LIGHT_THEME" "default" "$TERM_PROFILE_LIGHT" \
            "$ICON_DAY" "Day mode (click to switch to night)"
        echo "light" > "$MANUAL_OVERRIDE"
        echo "Day: $LIGHT_THEME"
        ;;
    dark)
        apply_theme "$DARK_THEME" "prefer-dark" "$TERM_PROFILE_DARK" \
            "$ICON_NIGHT" "Night mode (click to switch to day)"
        echo "dark" > "$MANUAL_OVERRIDE"
        echo "Night: $DARK_THEME"
        ;;
    toggle)
        if [ "$CURRENT" = "$DARK_THEME" ]; then
            apply_theme "$LIGHT_THEME" "default" "$TERM_PROFILE_LIGHT" \
                "$ICON_DAY" "Day mode (click to switch to night)"
            echo "light" > "$MANUAL_OVERRIDE"
            echo "Day: $LIGHT_THEME"
        else
            apply_theme "$DARK_THEME" "prefer-dark" "$TERM_PROFILE_DARK" \
                "$ICON_NIGHT" "Night mode (click to switch to day)"
            echo "dark" > "$MANUAL_OVERRIDE"
            echo "Night: $DARK_THEME"
        fi
        ;;
    *)
        echo "Usage: $0 [light|dark|toggle]"
        exit 1
        ;;
esac
