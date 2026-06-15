#!/usr/bin/env bash
# install.sh — xfce-night-switch git-clone installer
# Use this when installing from source. For Ubuntu/Debian prefer the .deb package.
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN="$HOME/.local/bin"
CFG="$HOME/.config/theme-switcher"
APPS="$HOME/.local/share/applications"
ICONS="$HOME/.local/share/icons/hicolor/scalable/apps"
SYSTEMD="$HOME/.config/systemd/user"

echo "Installing xfce-night-switch..."
echo ""

mkdir -p "$BIN" "$CFG/locales" "$APPS" "$ICONS" "$SYSTEMD"

echo "── Scripts ────────────────────────────────────"
for f in auto-theme.sh toggle-theme.sh theme-settings.sh \
          install-panel-launcher.sh sunrise-sunset.py; do
    cp "$REPO/$f" "$BIN/$f"
    chmod +x "$BIN/$f"
    echo "  installed: ~/.local/bin/$f"
done

echo ""
echo "── Desktop entries ────────────────────────────"
cp "$REPO/toggle-theme.desktop"   "$APPS/toggle-theme.desktop"
cp "$REPO/theme-settings.desktop" "$APPS/theme-settings.desktop"
update-desktop-database "$APPS" 2>/dev/null || true
echo "  installed: ~/.local/share/applications/"

echo ""
echo "── Moon icon ──────────────────────────────────"
cp "$REPO/icons/theme-moon.svg" "$ICONS/theme-moon.svg"
gtk-update-icon-cache -f "$HOME/.local/share/icons/hicolor/" 2>/dev/null || true
echo "  installed: theme-moon.svg"

echo ""
echo "── Locale files ───────────────────────────────"
for f in "$REPO/locales"/*.sh; do
    dst="$CFG/locales/$(basename "$f")"
    [[ -f "$dst" ]] && echo "  skipped (exists): $(basename "$f")" && continue
    cp "$f" "$dst"
    echo "  installed: $(basename "$f")"
done

echo ""
echo "── Config ─────────────────────────────────────"
if [[ ! -f "$CFG/config" ]]; then
    cp "$REPO/theme-switcher-config.default" "$CFG/config"
    echo "  created: ~/.config/theme-switcher/config"
    echo "  NOTE: defaults use Adwaita themes — run 'theme-settings.sh' to pick your themes"
else
    echo "  skipped (exists): ~/.config/theme-switcher/config"
fi

echo ""
echo "── Systemd service ────────────────────────────"
cp "$REPO/auto-theme-startup.service" "$SYSTEMD/auto-theme-startup.service"
if command -v systemctl >/dev/null 2>&1 && systemctl --user show-environment >/dev/null 2>&1; then
    systemctl --user daemon-reload
    systemctl --user enable --now auto-theme-startup.service 2>/dev/null \
        && echo "  enabled: auto-theme-startup.service" \
        || echo "  warning: could not enable (run: systemctl --user enable --now auto-theme-startup.service)"
else
    echo "  installed: auto-theme-startup.service (enable manually after login)"
fi

echo ""
echo "── Cron job ───────────────────────────────────"
if ! crontab -l 2>/dev/null | grep -q 'auto-theme.sh'; then
    (crontab -l 2>/dev/null; echo "*/1 * * * * $BIN/auto-theme.sh") | crontab -
    echo "  added: auto-theme.sh (every minute)"
else
    echo "  skipped (exists): cron auto-theme.sh"
fi

echo ""
echo "── XFCE Panel launcher ────────────────────────"
if command -v xfconf-query >/dev/null 2>&1 && \
   DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$(id -u)/bus" \
   xfconf-query -c xfce4-panel -l >/dev/null 2>&1; then
    bash "$BIN/install-panel-launcher.sh" \
        && echo "  installed: panel launcher" \
        || echo "  warning: panel install failed — run ~/.local/bin/install-panel-launcher.sh manually"
else
    echo "  skipped: no XFCE session — run ~/.local/bin/install-panel-launcher.sh after login"
fi

echo ""
echo "Done! Open Theme Settings from the panel launcher or run:"
echo "  ~/.local/bin/theme-settings.sh"
