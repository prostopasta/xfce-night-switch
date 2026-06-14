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
MANUAL_OVERRIDE="$HOME/.config/theme-switcher/manual_override"

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

# Определяем нужный режим
if [[ "$NOW" > "$DAY_START" || "$NOW" == "$DAY_START" ]] && [[ "$NOW" < "$DAY_END" ]]; then
    WANT_THEME="$LIGHT_THEME"
    WANT_MODE="default"
    WANT_TERM="$TERM_LIGHT"
    WANT_ICON="$ICON_DAY"
    WANT_TOOLTIP="Дневной режим (нажми чтобы переключить на ночь)"
else
    WANT_THEME="$DARK_THEME"
    WANT_MODE="prefer-dark"
    WANT_TERM="$TERM_DARK"
    WANT_ICON="$ICON_NIGHT"
    WANT_TOOLTIP="Ночной режим (нажми чтобы переключить на день)"
fi

# Проверяем ручное переключение
if [ -f "$MANUAL_OVERRIDE" ]; then
    OVERRIDE=$(cat "$MANUAL_OVERRIDE")
    [ "$WANT_THEME" = "$LIGHT_THEME" ] && WANT_NAME="light" || WANT_NAME="dark"
    if [ "$OVERRIDE" != "$WANT_NAME" ]; then
        # Пользователь вручную переключил — расписание не совпадает, ждём
        exit 0
    else
        # Расписание совпало с ручным — очищаем флаг
        rm -f "$MANUAL_OVERRIDE"
    fi
fi

# GTK тема: применяем только если изменилась
if [ "$CURRENT" != "$WANT_THEME" ]; then
    apply_theme "$WANT_THEME" "$WANT_MODE" "$WANT_TERM" "$WANT_ICON" "$WANT_TOOLTIP"
else
    # GTK тема правильная, но Terminator мог перезаписать свой конфиг
    # (при закрытии окна / сохранении раскладки) — синхронизируем всегда
    if [ -f "$WANT_TERM" ]; then
        TERM_BG=$(grep -m1 "background_color" "$TERM_CONFIG" 2>/dev/null | tr -d ' ')
        WANT_BG=$(grep -m1 "background_color" "$WANT_TERM" 2>/dev/null | tr -d ' ')
        if [ "$TERM_BG" != "$WANT_BG" ]; then
            cp "$WANT_TERM" "$TERM_CONFIG"; sleep 0.1; touch "$TERM_CONFIG"
        fi
    fi
fi
