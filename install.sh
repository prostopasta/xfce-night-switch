#!/usr/bin/env bash
# xfce-night-switch installer.
#
# Auto-detects context:
#   • Run from a git clone  →  installs from local source files
#   • Run remotely (curl/wget pipe)  →  downloads and installs latest .deb
#
# Usage:
#   git clone https://github.com/prostopasta/xfce-night-switch.git && bash xfce-night-switch/install.sh
#   bash <(curl -fsSL https://github.com/prostopasta/xfce-night-switch/releases/latest/download/install.sh)
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd || true)"
REMOTE_REPO="prostopasta/xfce-night-switch"

# ── Mode detection ──────────────────────────────────────────────────────────
if [[ -f "$REPO/scripts/auto-theme.sh" ]]; then
    MODE="source"
else
    MODE="deb"
fi

# ── .deb install (remote / curl pipe) ──────────────────────────────────────
_install_deb() {
    echo "=== xfce-night-switch installer (deb) ==="
    echo ""

    # Check and install missing prerequisites
    MISSING=()
    for pkg in curl wget yad python3 python3-dbus; do
        dpkg -l "$pkg" >/dev/null 2>&1 || MISSING+=("$pkg")
    done
    if [[ ${#MISSING[@]} -gt 0 ]]; then
        echo "Installing missing prerequisites: ${MISSING[*]}"
        sudo apt-get install -y "${MISSING[@]}"
        echo ""
    fi

    echo "Fetching latest release..."
    API_JSON=$(curl -fsSL "https://api.github.com/repos/${REMOTE_REPO}/releases/latest")
    DEB_URL=$(echo "$API_JSON" | grep '"browser_download_url"' | grep '\.deb"' \
              | cut -d'"' -f4 | head -1)
    VERSION=$(echo "$API_JSON" | grep '"tag_name"' | cut -d'"' -f4)

    [[ -z "$DEB_URL" ]] && { echo "Error: no .deb found in latest release." >&2; exit 1; }

    TMP=$(mktemp -d); trap 'rm -rf "$TMP"' EXIT
    echo "Downloading xfce-night-switch ${VERSION}..."
    wget -q --show-progress -O "$TMP/xfce-night-switch.deb" "$DEB_URL"

    echo ""
    echo "Installing (requires sudo)..."
    sudo dpkg -i "$TMP/xfce-night-switch.deb"

    echo ""
    echo "Run the following to complete setup for your user:"
    echo "  xfce-night-switch-setup"
}

# ── Source install (git clone) ──────────────────────────────────────────────
_install_source() {
    BIN="$HOME/.local/bin"
    CFG="$HOME/.config/xfce-night-switch"
    APPS="$HOME/.local/share/applications"
    ICONS="$HOME/.local/share/icons/hicolor/scalable/apps"
    SYSTEMD="$HOME/.config/systemd/user"

    echo "=== xfce-night-switch installer (source) ==="
    echo ""

    mkdir -p "$BIN" "$CFG/locales" "$APPS" "$ICONS" "$SYSTEMD"

    echo "── Scripts ────────────────────────────────────"
    for f in auto-theme.sh toggle-theme.sh theme-settings.sh \
              install-panel-launcher.sh sunrise-sunset.py auto-update.sh; do
        cp "$REPO/scripts/$f" "$BIN/$f"
        chmod +x "$BIN/$f"
        echo "  installed: ~/.local/bin/$f"
    done

    echo ""
    echo "── Desktop entries ────────────────────────────"
    cp "$REPO/desktop/toggle-theme.desktop"   "$APPS/toggle-theme.desktop"
    cp "$REPO/desktop/theme-settings.desktop" "$APPS/theme-settings.desktop"
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
        cp "$REPO/packaging/config.default" "$CFG/config"
        echo "  created: ~/.config/xfce-night-switch/config"
        echo "  NOTE: defaults use Adwaita themes — run 'theme-settings.sh' to pick your themes"
    else
        echo "  skipped (exists): ~/.config/xfce-night-switch/config"
    fi

    echo ""
    echo "── Systemd services ───────────────────────────"
    cp "$REPO/systemd/xfce-night-switch-startup.service" "$SYSTEMD/xfce-night-switch-startup.service"
    cp "$REPO/systemd/xfce-night-switch-update.service"        "$SYSTEMD/xfce-night-switch-update.service"
    if command -v systemctl >/dev/null 2>&1 && systemctl --user show-environment >/dev/null 2>&1; then
        systemctl --user daemon-reload
        systemctl --user enable --now xfce-night-switch-startup.service 2>/dev/null \
            && echo "  enabled: xfce-night-switch-startup.service" \
            || echo "  warning: run: systemctl --user enable --now xfce-night-switch-startup.service"
        systemctl --user enable xfce-night-switch-update.service 2>/dev/null \
            && echo "  enabled: xfce-night-switch-update.service" \
            || echo "  warning: could not enable xfce-night-switch-update.service"
    else
        echo "  installed: services (enable manually after login)"
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
}

# ── Dispatch ────────────────────────────────────────────────────────────────
if [[ "$MODE" == "source" ]]; then
    _install_source
else
    _install_deb
fi
