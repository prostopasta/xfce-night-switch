#!/bin/bash
# Installs theme-switcher launcher into the primary XFCE panel.
# Idempotent: safe to run multiple times.

export DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$(id -u)/bus"
export DISPLAY=:0

SWITCHER_CONFIG="$HOME/.config/xfce-night-switch/config"

APP_LANG="en"
[ -f "$SWITCHER_CONFIG" ] && source "$SWITCHER_CONFIG"
LOCALE_FILE="$HOME/.config/xfce-night-switch/locales/${APP_LANG}.sh"
[ -f "$LOCALE_FILE" ] || LOCALE_FILE="${XFCE_NIGHT_SWITCH_DIR:-/usr/share/xfce-night-switch}/locales/${APP_LANG}.sh"
[ -f "$LOCALE_FILE" ] && source "$LOCALE_FILE"

TOGGLE_NAME="${S_TOGGLE_NAME:-Toggle Theme}"
SETTINGS_NAME="${S_SETTINGS_NAME:-Theme Settings}"
SETTINGS_COMMENT="${S_SETTINGS_COMMENT:-Configure icons, auto-switcher and language}"

DARK_THEME="${DARK_THEME:-Mint-Y-Dark-Aqua}"
current_theme=$(gsettings get org.gnome.desktop.interface gtk-theme 2>/dev/null | tr -d "'")
if [ "$current_theme" = "$DARK_THEME" ]; then
    TOGGLE_ICON="${ICON_NIGHT:-$HOME/.local/share/icons/hicolor/scalable/apps/theme-moon.svg}"
    TOGGLE_COMMENT="${S_TOGGLE_COMMENT_NIGHT:-Night mode — click to switch to day}"
else
    TOGGLE_ICON="${ICON_DAY:-weather-clear}"
    TOGGLE_COMMENT="${S_TOGGLE_COMMENT_DAY:-Day mode — click to switch to night}"
fi

# Verify xfconf is accessible
if ! xfconf-query -c xfce4-panel -l >/dev/null 2>&1; then
    echo "ERROR: xfce4-panel xfconf not accessible (no XFCE session?)"
    exit 1
fi

# ── Find primary panel (the one containing a clock/datetime plugin) ─────────
_find_primary_panel() {
    local fallback=""
    for panel in $(xfconf-query -c xfce4-panel -l 2>/dev/null \
                   | grep -oE '/panels/panel-[0-9]+/plugin-ids' \
                   | sed 's|/plugin-ids||' | sort); do
        [ -z "$fallback" ] && fallback="${panel##*/panels/}"
        local plugin_ids
        plugin_ids=$(xfconf-query -c xfce4-panel -p "${panel}/plugin-ids" 2>/dev/null)
        while IFS= read -r pid; do
            pid=$(echo "$pid" | tr -d ' \r')
            [[ "$pid" =~ ^[0-9]+$ ]] || continue
            local ptype
            ptype=$(xfconf-query -c xfce4-panel -p "/plugins/plugin-${pid}" 2>/dev/null || true)
            if [[ "$ptype" == "datetime" || "$ptype" == "clock" ]]; then
                echo "${panel##*/panels/}"
                return 0
            fi
        done <<< "$plugin_ids"
    done
    # Fallback: first panel
    echo "${fallback:-panel-0}"
}

# ── Find or reuse plugin ID ─────────────────────────────────────────────────
# Reuse saved ID if xfconf still has it as a launcher and our dir exists.
# Otherwise find the first free ID >= 100.
_get_plugin_id() {
    local saved_id=""
    [ -f "$SWITCHER_CONFIG" ] \
        && saved_id=$(grep '^XFCE_PLUGIN_ID=' "$SWITCHER_CONFIG" 2>/dev/null | cut -d'"' -f2)
    if [ -n "$saved_id" ]; then
        local saved_type
        saved_type=$(xfconf-query -c xfce4-panel -p "/plugins/plugin-${saved_id}" 2>/dev/null || true)
        if [ "$saved_type" = "launcher" ] \
           && [ -d "$HOME/.config/xfce4/panel/launcher-${saved_id}" ]; then
            echo "$saved_id"; return 0
        fi
    fi
    local id=100
    while xfconf-query -c xfce4-panel -p "/plugins/plugin-${id}" >/dev/null 2>&1; do
        id=$((id + 1))
    done
    echo "$id"
}

# Determine target panel:
# 1. positional arg  2. XFCE_TARGET_PANEL env  3. dialog (multi-panel + display)  4. clock detection
_ask_panel_yad() {
    local default=$1
    local rows=() all_panels ordered=()
    all_panels=$(xfconf-query -c xfce4-panel -l 2>/dev/null \
                 | grep -oE '/panels/panel-[0-9]+/plugin-ids' \
                 | sed 's|/plugin-ids||' | sort | sed 's|.*/panels/||')
    # Default panel first so yad pre-selects it
    ordered+=("$default")
    while IFS= read -r p; do [ "$p" != "$default" ] && ordered+=("$p"); done <<< "$all_panels"
    for pname in "${ordered[@]}"; do
        local has_clock="" is_current="" plugin_ids
        plugin_ids=$(xfconf-query -c xfce4-panel -p "/panels/${pname}/plugin-ids" 2>/dev/null)
        while IFS= read -r pid; do
            pid=$(echo "$pid" | tr -d ' \r')
            [[ "$pid" =~ ^[0-9]+$ ]] || continue
            local ptype
            ptype=$(xfconf-query -c xfce4-panel -p "/plugins/plugin-${pid}" 2>/dev/null || true)
            [[ "$ptype" == "datetime" || "$ptype" == "clock" ]] && has_clock="  ★ clock"
            [ -n "${XFCE_PLUGIN_ID:-}" ] && [ "$pid" = "$XFCE_PLUGIN_ID" ] \
                && is_current="  ✓ installed"
        done <<< "$plugin_ids"
        rows+=("$pname" "${pname}${has_clock}${is_current}")
    done
    local sel
    sel=$(yad --title="${S_PANEL_TITLE:-Panel Launcher}" --width=400 --height=260 \
        --list --column=":HD" --column="${S_COL_SETTING:-Panel}" \
        --print-column=1 --no-headers \
        --text="${S_PANEL_CHOOSE:-Select which panel to install the launcher on:}" \
        "${rows[@]}" \
        --button="gtk-ok:0" --button="gtk-cancel:1" 2>/dev/null)
    sel="${sel%|}"
    echo "${sel:-$default}"
}

primary=$(_find_primary_panel)
if [ -n "${1:-}" ]; then
    TARGET_PANEL="$1"
elif [ -n "${XFCE_TARGET_PANEL:-}" ]; then
    TARGET_PANEL="$XFCE_TARGET_PANEL"
else
    panel_count=$(xfconf-query -c xfce4-panel -l 2>/dev/null \
                  | grep -cE '/panels/panel-[0-9]+/plugin-ids' || true)
    if [ "${panel_count:-1}" -gt 1 ] && [ -n "${DISPLAY:-}" ] && command -v yad >/dev/null 2>&1; then
        TARGET_PANEL=$(_ask_panel_yad "$primary")
    else
        TARGET_PANEL="$primary"
    fi
fi

PLUGIN_ID=$(_get_plugin_id)
LAUNCHER_DIR="$HOME/.config/xfce4/panel/launcher-${PLUGIN_ID}"

# If the plugin slot is already registered as a launcher this is an upgrade —
# the panel has it loaded already, no restart needed. Restart only on fresh install.
_existing_type=$(xfconf-query -c xfce4-panel \
    -p "/plugins/plugin-${PLUGIN_ID}" 2>/dev/null || true)
_NEED_PANEL_RESTART=true
[ "$_existing_type" = "launcher" ] && _NEED_PANEL_RESTART=false

echo "Primary panel : $TARGET_PANEL"
echo "Plugin ID     : $PLUGIN_ID"

mkdir -p "$LAUNCHER_DIR"

# ── Create .desktop files ───────────────────────────────────────────────────
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

# ── Register plugin in xfconf ───────────────────────────────────────────────
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

# ── Remove plugin from a panel ──────────────────────────────────────────────
_remove_from_panel() {
    local panel_path=$1
    local raw
    raw=$(xfconf-query -c xfce4-panel -p "${panel_path}/plugin-ids" 2>/dev/null)
    [ -z "$raw" ] && return
    local ids=()
    while IFS= read -r id; do
        id=$(echo "$id" | tr -d ' \r')
        [[ "$id" =~ ^[0-9]+$ ]] || continue
        [ "$id" = "$PLUGIN_ID" ] || ids+=(-t int -s "$id")
    done <<< "$raw"
    [ ${#ids[@]} -gt 0 ] && \
        xfconf-query -c xfce4-panel -p "${panel_path}/plugin-ids" \
            --force-array "${ids[@]}" 2>/dev/null || true
}

# ── Add plugin to target panel ──────────────────────────────────────────────
_update_panel() {
    local panel_path=$1
    local raw
    raw=$(xfconf-query -c xfce4-panel -p "${panel_path}/plugin-ids" 2>/dev/null)
    [ -z "$raw" ] && return 1

    local ids=() found=false
    while IFS= read -r id; do
        id=$(echo "$id" | tr -d ' \r')
        [[ "$id" =~ ^[0-9]+$ ]] || continue
        if [ "$id" = "$PLUGIN_ID" ]; then
            ids+=(-t int -s "$id"); found=true
        else
            ids+=(-t int -s "$id")
        fi
    done <<< "$raw"
    $found || ids+=(-t int -s "$PLUGIN_ID")

    xfconf-query -c xfce4-panel -p "${panel_path}/plugin-ids" \
        --force-array "${ids[@]}" 2>/dev/null
}

# Remove from old panels first (when switching panels)
OLD_PANELS="${XFCE_LAUNCHER_PANELS:-}"
for old_panel in $OLD_PANELS; do
    [ "$old_panel" != "$TARGET_PANEL" ] && _remove_from_panel "/panels/$old_panel"
done

_update_panel "/panels/${TARGET_PANEL}"

# ── Save install metadata to config ─────────────────────────────────────────
_cfg_set() {
    local key=$1 val=$2
    if grep -q "^${key}=" "$SWITCHER_CONFIG" 2>/dev/null; then
        sed -i "s|^${key}=.*|${key}=\"${val}\"|" "$SWITCHER_CONFIG"
    else
        echo "${key}=\"${val}\"" >> "$SWITCHER_CONFIG"
    fi
}

if [ -f "$SWITCHER_CONFIG" ]; then
    _cfg_set "XFCE_PLUGIN_ID"       "$PLUGIN_ID"
    _cfg_set "XFCE_LAUNCHER_PANELS" "$TARGET_PANEL"
fi

echo "OK: plugin-${PLUGIN_ID} / launcher-${PLUGIN_ID} installed on ${TARGET_PANEL}"
if $_NEED_PANEL_RESTART; then
    # Kill panel → modify xfconf is already done → start fresh from xfconf.
    # We intentionally avoid --restart because it saves in-memory state first,
    # which would overwrite the xfconf changes we just made.
    pkill -x xfce4-panel 2>/dev/null || true
    sleep 0.4
    xfce4-panel 2>/dev/null &
else
    echo "  plugin already registered — panel restart skipped (upgrade)"
fi
