#!/bin/bash

export DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$(id -u)/bus"
export DISPLAY=:0

PID=$(pgrep -u "$LOGNAME" xfce4-session | head -n 1)
[ -z "$PID" ] && { echo "Сессия не найдена."; exit 1; }

LIGHT_THEME="ZorinBlue-Light"
DARK_THEME="Mint-Y-Dark-Aqua"
TERM_CONFIG="$HOME/.config/terminator/config"
TERM_LIGHT="$HOME/.config/terminator/config.light"
TERM_DARK="$HOME/.config/terminator/config.dark"
PANEL_LAUNCHER_DIR="$HOME/.config/xfce4/panel/launcher-101"
APP_DESKTOP="$HOME/.local/share/applications/toggle-theme.desktop"
SWITCHER_CONFIG="$HOME/.config/theme-switcher/config"

# Дефолты
ICON_DAY="weather-clear"
ICON_NIGHT="$HOME/.local/share/icons/hicolor/scalable/apps/theme-moon.svg"
AUTO_SWITCHER="enabled"
AUTO_MODE="time"
DAY_START="07:00"
DAY_END="18:00"
LATITUDE=""
LONGITUDE=""
[ -f "$SWITCHER_CONFIG" ] && source "$SWITCHER_CONFIG"

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

apply_theme() {
    local theme_name=$1 mode=$2 term_source=$3 icon=$4 tooltip=$5
    echo ">>> $mode ($theme_name)"
    xfconf-query -c xsettings -p /Net/ThemeName -s "$theme_name"
    xfconf-query -c xfwm4 -p /general/theme -s "$theme_name"
    gsettings set org.gnome.desktop.interface color-scheme "$mode" 2>/dev/null
    gsettings set org.gnome.desktop.interface gtk-theme "$theme_name" 2>/dev/null
    if [ -f "$term_source" ]; then
        cp "$term_source" "$TERM_CONFIG"; sleep 0.1; touch "$TERM_CONFIG"
    fi
    update_panel_icon "$icon" "$tooltip"
}

# --- Определяем границы дня ---
if [ "$AUTO_MODE" = "location" ] && [ -n "$LATITUDE" ] && [ -n "$LONGITUDE" ]; then
    times=$(python3 "$HOME/.local/bin/sunrise-sunset.py" "$LATITUDE" "$LONGITUDE" both 2>/dev/null)
    if [ -n "$times" ]; then
        DAY_START=$(echo "$times" | cut -d' ' -f1)
        DAY_END=$(echo "$times"   | cut -d' ' -f2)
        echo ">>> Локация: рассвет $DAY_START, закат $DAY_END"
    fi
fi

NOW=$(date +%H:%M)
CURRENT=$(xfconf-query -c xsettings -p /Net/ThemeName 2>/dev/null)

if [[ "$NOW" > "$DAY_START" || "$NOW" == "$DAY_START" ]] && [[ "$NOW" < "$DAY_END" ]]; then
    [ "$CURRENT" != "$LIGHT_THEME" ] && \
        apply_theme "$LIGHT_THEME" "default" "$TERM_LIGHT" \
            "$ICON_DAY" "Дневной режим (нажми чтобы переключить на ночь)"
else
    [ "$CURRENT" != "$DARK_THEME" ] && \
        apply_theme "$DARK_THEME" "prefer-dark" "$TERM_DARK" \
            "$ICON_NIGHT" "Ночной режим (нажми чтобы переключить на день)"
fi
