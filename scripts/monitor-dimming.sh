#!/usr/bin/env bash
# monitor-dimming.sh — apply monitor brightness when the XFCE theme changes.
#
# Usage: monitor-dimming.sh [light|dark]
#   light / dark  — target theme (passed by toggle-theme.sh / auto-theme.sh)
#   (no argument) — reads current theme from xfconf as fallback
#
# Brightness values are read from ~/.config/xfce-night-switch/config.
# Built-in display (eDP-*): hardware backlight via /sys/class/backlight.
# External monitors: ddcutil (DDC/CI hardware) or xrandr (software), see
# DIMMING_EXT_METHOD in config.

SWITCHER_CONFIG="${HOME}/.config/xfce-night-switch/config"
[ -f "$SWITCHER_CONFIG" ] && source "$SWITCHER_CONFIG"

# ── Resolve target theme ──────────────────────────────────────────────────────
if [[ "$1" == "light" || "$1" == "dark" ]]; then
    TARGET="$1"
else
    _cur=$(xfconf-query -c xsettings -p /Net/ThemeName 2>/dev/null)
    [[ "$_cur" == "${DARK_THEME:-Adwaita-dark}" ]] && TARGET="dark" || TARGET="light"
fi

# ── Resolve brightness values ─────────────────────────────────────────────────
if [[ "$TARGET" == "dark" ]]; then
    EDPI_PCTG="${DIMMING_EDPI_DARK:-70}"
    EXT_PCTG="${DIMMING_EXT_DARK:-50}"
else
    EDPI_PCTG="${DIMMING_EDPI_LIGHT:-100}"
    EXT_PCTG="${DIMMING_EXT_LIGHT:-100}"
fi

# ── Built-in display (eDP-*): hardware backlight ──────────────────────────────
_apply_edpi() {
    local pctg="$1"
    local bl_dir
    # Pick the first available backlight device
    bl_dir=$(ls /sys/class/backlight/ 2>/dev/null | head -1)
    [[ -z "$bl_dir" ]] && return

    local max val
    max=$(cat "/sys/class/backlight/${bl_dir}/max_brightness" 2>/dev/null) || return
    val=$(( max * pctg / 100 ))

    # Try direct write first (user in 'video' group); fall back to sudo
    if ! tee "/sys/class/backlight/${bl_dir}/brightness" <<< "$val" >/dev/null 2>&1; then
        sudo tee "/sys/class/backlight/${bl_dir}/brightness" <<< "$val" >/dev/null 2>&1 || true
    fi
}

# ── External monitors ─────────────────────────────────────────────────────────
_apply_external() {
    local pctg="$1"
    local method="${DIMMING_EXT_METHOD:-ddcutil}"

    # Enumerate connected outputs, skip built-in eDP displays
    while read -r output; do
        [[ "$output" == eDP* ]] && continue

        if [[ "$method" == "ddcutil" ]]; then
            ddcutil --display "$output" setvcp 10 "$pctg" 2>/dev/null || true
        else
            # xrandr software brightness: map 0–100 % → 0.00–1.00
            local flt
            flt=$(awk "BEGIN{printf \"%.2f\", $pctg/100}")
            xrandr --output "$output" --brightness "$flt" 2>/dev/null || true
        fi
    done < <(xrandr --query 2>/dev/null | awk '/^[^ ]+ connected [^(]/{print $1}')
}

_apply_edpi    "$EDPI_PCTG"
_apply_external "$EXT_PCTG"
