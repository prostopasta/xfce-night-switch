#!/usr/bin/env bash
# shellcheck disable=SC1090,SC2155
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

export DISPLAY="${DISPLAY:-:0}"
export DBUS_SESSION_BUS_ADDRESS="${DBUS_SESSION_BUS_ADDRESS:-unix:path=/run/user/$(id -u)/bus}"

SWITCHER_CONFIG="${HOME}/.config/xfce-night-switch/config"
[ -f "$SWITCHER_CONFIG" ] && source "$SWITCHER_CONFIG"

[[ "${MONITOR_DIMMING:-disabled}" != "enabled" ]] && exit 0

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

# ── Built-in / internal displays: hardware backlight ─────────────────────────
_apply_backlight() {
    local pctg="$1"

    # Iterate through all available backlight devices (Intel, AMD, ACPI, Nvidia)
    for bl in /sys/class/backlight/*; do
        [ -d "$bl" ] || continue
        local max val
        max=$(cat "${bl}/max_brightness" 2>/dev/null || true)
        [[ -z "$max" || "$max" -le 0 ]] && continue

        val=$(( max * pctg / 100 ))
        # Try direct write first (user in 'video' group); fall back to sudo
        if ! tee "${bl}/brightness" <<< "$val" >/dev/null 2>&1; then
            sudo tee "${bl}/brightness" <<< "$val" >/dev/null 2>&1 || true
        fi
    done
}

# ── External / other connected displays ───────────────────────────────────────
_apply_external() {
    local pctg="$1"
    local method="${DIMMING_EXT_METHOD:-ddcutil}"
    local ddc_success=false

    if [[ "$method" == "ddcutil" ]] && command -v ddcutil >/dev/null 2>&1; then
        local disps
        disps=$(ddcutil detect --terse 2>/dev/null | awk '/^Display /{print $2}')
        if [ -n "$disps" ]; then
            for d in $disps; do
                if ddcutil --display "$d" setvcp 10 "$pctg" 2>/dev/null; then
                    ddc_success=true
                fi
            done
        else
            if ddcutil setvcp 10 "$pctg" 2>/dev/null; then
                ddc_success=true
            fi
        fi
    fi

    # Fall back to xrandr software brightness if method is xrandr or ddcutil failed/unavailable
    if [[ "$method" == "xrandr" ]] || ! $ddc_success; then
        while read -r output; do
            # Skip internal laptop panels if backlight device exists
            if [ -d /sys/class/backlight ] && [ -n "$(ls -A /sys/class/backlight 2>/dev/null)" ]; then
                [[ "$output" =~ ^(eDP|LVDS|DSI) ]] && continue
            fi

            local flt
            flt=$(awk "BEGIN{printf \"%.2f\", $pctg/100}")
            xrandr --output "$output" --brightness "$flt" 2>/dev/null || true
        done < <(xrandr --query 2>/dev/null | awk '/^[^ ]+ connected/{print $1}')
    fi
}

_apply_backlight "$EDPI_PCTG"
_apply_external  "$EXT_PCTG"
