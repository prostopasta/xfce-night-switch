#!/bin/bash
# Устанавливает theme-switcher launcher в XFCE panel.
# Использует plugin-101 / launcher-101 (не конфликтует с системными < 100).
# Идемпотентно: безопасно запускать повторно.

export DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$(id -u)/bus"
export DISPLAY=:0

PLUGIN_ID=101
LAUNCHER_DIR="$HOME/.config/xfce4/panel/launcher-${PLUGIN_ID}"
OLD_LAUNCHER_DIR="$HOME/.config/xfce4/panel/launcher-23"
SWITCHER_CONFIG="$HOME/.config/theme-switcher/config"

APP_LANG="en"
[ -f "$SWITCHER_CONFIG" ] && source "$SWITCHER_CONFIG"
LOCALE_FILE="$HOME/.config/theme-switcher/locales/${APP_LANG}.sh"
[ -f "$LOCALE_FILE" ] && source "$LOCALE_FILE"

TOGGLE_NAME="${S_TOGGLE_NAME:-Toggle Theme}"
SETTINGS_NAME="${S_SETTINGS_NAME:-Theme Settings}"
SETTINGS_COMMENT="${S_SETTINGS_COMMENT:-Configure icons, auto-switcher and language}"

DARK_THEME="Mint-Y-Dark-Aqua"
current_theme=$(gsettings get org.gnome.desktop.interface gtk-theme 2>/dev/null | tr -d "'")
if [ "$current_theme" = "$DARK_THEME" ]; then
    TOGGLE_ICON="${ICON_NIGHT:-/home/ps/.local/share/icons/hicolor/scalable/apps/theme-moon.svg}"
    TOGGLE_COMMENT="${S_TOGGLE_COMMENT_NIGHT:-Night mode — click to switch to day}"
else
    TOGGLE_ICON="${ICON_DAY:-weather-clear}"
    TOGGLE_COMMENT="${S_TOGGLE_COMMENT_DAY:-Day mode — click to switch to night}"
fi

# Проверяем xfconf доступность
if ! xfconf-query -c xfce4-panel -l >/dev/null 2>&1; then
    echo "ERROR: xfce4-panel xfconf not accessible (no XFCE session?)"
    exit 1
fi

mkdir -p "$LAUNCHER_DIR"

# ── Создаём .desktop файлы ─────────────────────────────────────────────────
cat > "$LAUNCHER_DIR/toggle-theme.desktop" << EOF
[Desktop Entry]
Name=${TOGGLE_NAME}
Comment=${TOGGLE_COMMENT}
Exec=$HOME/.local/bin/toggle-theme.sh
Icon=${TOGGLE_ICON}
Terminal=false
Type=Application
Categories=Settings;DesktopSettings;
EOF

cat > "$LAUNCHER_DIR/theme-settings.desktop" << EOF
[Desktop Entry]
Name=${SETTINGS_NAME}
Comment=${SETTINGS_COMMENT}
Exec=$HOME/.local/bin/theme-settings.sh
Icon=preferences-desktop-theme
Terminal=false
Type=Application
Categories=Settings;DesktopSettings;
EOF

# ── Регистрируем plugin-101 в xfconf ──────────────────────────────────────
xfconf-query -c xfce4-panel \
    -p /plugins/plugin-${PLUGIN_ID} \
    -n -t string -s "launcher" 2>/dev/null || \
xfconf-query -c xfce4-panel \
    -p /plugins/plugin-${PLUGIN_ID} \
    -t string -s "launcher" 2>/dev/null

xfconf-query -c xfce4-panel \
    -p /plugins/plugin-${PLUGIN_ID}/items \
    --force-array \
    -n -t string -s "toggle-theme.desktop" \
    -t string -s "theme-settings.desktop" 2>/dev/null

# ── Обновляем plugin-ids панелей: заменяем 23 на 101, или добавляем 101 ───
_update_panel() {
    local panel=$1
    local raw
    raw=$(xfconf-query -c xfce4-panel -p "${panel}/plugin-ids" 2>/dev/null)
    [ -z "$raw" ] && return 1

    local ids=() found_new=false found_old=false
    while IFS= read -r id; do
        id=$(echo "$id" | tr -d ' \r')    # убираем пробелы из заголовков xfconf-query
        [[ "$id" =~ ^[0-9]+$ ]] || continue
        if [ "$id" = "23" ]; then
            # Заменяем старый ID на новый
            ids+=(-t int -s "$PLUGIN_ID")
            found_new=true; found_old=true
        elif [ "$id" = "$PLUGIN_ID" ]; then
            ids+=(-t int -s "$id")
            found_new=true
        else
            ids+=(-t int -s "$id")
        fi
    done <<< "$raw"

    # Если 101 ещё нет — добавляем в конец
    $found_new || ids+=(-t int -s "$PLUGIN_ID")

    xfconf-query -c xfce4-panel -p "${panel}/plugin-ids" \
        --force-array "${ids[@]}" 2>/dev/null
    return 0
}

panel_updated=false
for panel in $(xfconf-query -c xfce4-panel -l 2>/dev/null \
               | grep -oE '/panels/panel-[0-9]+/plugin-ids' \
               | sed 's|/plugin-ids||' | sort); do
    _update_panel "$panel" && panel_updated=true
done

# ── Удаляем старый plugin-23 из xfconf ────────────────────────────────────
if xfconf-query -c xfce4-panel -p /plugins/plugin-23 >/dev/null 2>&1; then
    xfconf-query -c xfce4-panel -p /plugins/plugin-23 -r -R 2>/dev/null
    echo "Удалён plugin-23 из xfconf"
fi

# Архивируем старую директорию launcher-23 если есть
if [ -d "$OLD_LAUNCHER_DIR" ] && [ "$OLD_LAUNCHER_DIR" != "$LAUNCHER_DIR" ]; then
    mv "$OLD_LAUNCHER_DIR" "${OLD_LAUNCHER_DIR}.bak" 2>/dev/null
    echo "launcher-23 → launcher-23.bak"
fi

echo "OK: plugin-${PLUGIN_ID} / launcher-${PLUGIN_ID} установлен"
# НЕ запускаем xfce4-panel --save: он перезапишет xfconf из in-memory состояния
# Панель сама подхватит изменения xfconf через inotify/dbus
