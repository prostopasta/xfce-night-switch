#!/bin/bash
# Daemon: слушает смену GTK-темы и синхронизирует иконку panel launcher.

export DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$(id -u)/bus"
export DISPLAY=:0

DARK_THEME="Mint-Y-Dark-Aqua"
PANEL_LAUNCHER_DIR="$HOME/.config/xfce4/panel/launcher-101"
APP_DESKTOP="$HOME/.local/share/applications/toggle-theme.desktop"
SWITCHER_CONFIG="$HOME/.config/theme-switcher/config"

load_config() {
    ICON_DAY="weather-clear"
    ICON_NIGHT="$HOME/.local/share/icons/hicolor/scalable/apps/theme-moon.svg"
    [ -f "$SWITCHER_CONFIG" ] && source "$SWITCHER_CONFIG"
}

# Atomic обновление поля: пишем в tmp, потом mv (меняет inode, но панель
# отслеживает путь а не inode — для daemon это нормально)
# Для .desktop файлов панели используем inode-preserving вариант.
update_field_inplace() {
    local file=$1 field=$2 value=$3
    [ -f "$file" ] || return
    local tmp
    tmp=$(mktemp)
    # sed пишет в tmp; если файл пустой или поле не найдено — tmp тоже может быть пустым
    sed "s|^${field}=.*|${field}=${value}|" "$file" > "$tmp"
    # Проверяем что tmp непустой перед записью
    if [ -s "$tmp" ]; then
        cat "$tmp" > "$file"
    fi
    rm -f "$tmp"
}

update_icon() {
    local icon=$1 tooltip=$2
    for f in "$PANEL_LAUNCHER_DIR"/*.desktop; do
        [ -f "$f" ] || continue
        # Обновляем только файл переключателя, не settings
        grep -q "toggle-theme\|Toggle Theme" "$f" 2>/dev/null || continue
        update_field_inplace "$f" "Icon" "$icon"
        update_field_inplace "$f" "Comment" "$tooltip"
    done
    update_field_inplace "$APP_DESKTOP" "Icon" "$icon"
    update_field_inplace "$APP_DESKTOP" "Comment" "$tooltip"
}

sync_icon() {
    load_config
    local current
    current=$(gsettings get org.gnome.desktop.interface gtk-theme 2>/dev/null | tr -d "'")
    if [ "$current" = "$DARK_THEME" ]; then
        update_icon "$ICON_NIGHT" "Ночной режим (нажми чтобы переключить на день)"
    else
        update_icon "$ICON_DAY" "Дневной режим (нажми чтобы переключить на ночь)"
    fi
}

sync_icon

# Только gsettings monitor — убран inotify subshell (вызывал race condition)
gsettings monitor org.gnome.desktop.interface 2>/dev/null | \
    grep --line-buffered "gtk-theme" | \
    while read -r _; do
        sync_icon
    done
