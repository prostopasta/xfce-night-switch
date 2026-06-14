#!/bin/bash

export DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$(id -u)/bus"
export DISPLAY=:0

LIGHT_THEME="ZorinBlue-Light"
DARK_THEME="Mint-Y-Dark-Aqua"

TERM_CONFIG="$HOME/.config/terminator/config"
TERM_LIGHT="$HOME/.config/terminator/config.light"
TERM_DARK="$HOME/.config/terminator/config.dark"

PANEL_LAUNCHER_DIR="$HOME/.config/xfce4/panel/launcher-101"
APP_DESKTOP="$HOME/.local/share/applications/toggle-theme.desktop"
SWITCHER_CONFIG="$HOME/.config/theme-switcher/config"
MANUAL_OVERRIDE="$HOME/.config/theme-switcher/manual_override"

# Читаем иконки из конфига
ICON_DAY="weather-clear"
ICON_NIGHT="$HOME/.local/share/icons/hicolor/scalable/apps/theme-moon.svg"
[ -f "$SWITCHER_CONFIG" ] && source "$SWITCHER_CONFIG"

update_field() {
    local file=$1 field=$2 value=$3
    [ -f "$file" ] || return
    [ -s "$file" ] || return   # не трогаем пустые файлы
    local tmp
    tmp=$(mktemp)
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

apply_theme() {
    local theme_name=$1 mode=$2 term_source=$3 icon=$4 tooltip=$5

    xfconf-query -c xsettings -p /Net/ThemeName -s "$theme_name"
    xfconf-query -c xfwm4 -p /general/theme -s "$theme_name"
    gsettings set org.gnome.desktop.interface color-scheme "$mode" 2>/dev/null
    gsettings set org.gnome.desktop.interface gtk-theme "$theme_name" 2>/dev/null

    if [ -f "$term_source" ]; then
        cp "$term_source" "$TERM_CONFIG"
        sleep 0.1
        touch "$TERM_CONFIG"
    fi

    update_panel_icon "$icon" "$tooltip"
}

CURRENT=$(xfconf-query -c xsettings -p /Net/ThemeName 2>/dev/null)

case "${1:-toggle}" in
    light)
        apply_theme "$LIGHT_THEME" "default" "$TERM_LIGHT" \
            "$ICON_DAY" "Дневной режим (нажми чтобы переключить на ночь)"
        echo "light" > "$MANUAL_OVERRIDE"
        echo "День: $LIGHT_THEME"
        ;;
    dark)
        apply_theme "$DARK_THEME" "prefer-dark" "$TERM_DARK" \
            "$ICON_NIGHT" "Ночной режим (нажми чтобы переключить на день)"
        echo "dark" > "$MANUAL_OVERRIDE"
        echo "Ночь: $DARK_THEME"
        ;;
    toggle)
        if [ "$CURRENT" = "$DARK_THEME" ]; then
            apply_theme "$LIGHT_THEME" "default" "$TERM_LIGHT" \
                "$ICON_DAY" "Дневной режим (нажми чтобы переключить на ночь)"
            echo "light" > "$MANUAL_OVERRIDE"
            echo "День: $LIGHT_THEME"
        else
            apply_theme "$DARK_THEME" "prefer-dark" "$TERM_DARK" \
                "$ICON_NIGHT" "Ночной режим (нажми чтобы переключить на день)"
            echo "dark" > "$MANUAL_OVERRIDE"
            echo "Ночь: $DARK_THEME"
        fi
        ;;
    *)
        echo "Использование: $0 [light|dark|toggle]"
        exit 1
        ;;
esac
