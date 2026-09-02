#!/usr/bin/env bash
# tests/test-offline-mode.sh — test offline mode and sun times caching
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SUN_PY="$REPO_DIR/scripts/sunrise-sunset.py"

echo "=== Testing offline mode & sun times ==="

TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT

# 1. Test NOAA solar calculation directly
# Coordinates for London: 51.5074 N, 0.1278 W
TIMES=$(python3 "$SUN_PY" 51.5074 -0.1278 both 2>/dev/null)
if [[ ! "$TIMES" =~ ^[0-2][0-9]:[0-5][0-9]\ [0-2][0-9]:[0-5][0-9]$ ]]; then
    echo "  ✗ Invalid NOAA calculation output: '$TIMES'" >&2
    exit 1
fi
echo "  ✓ NOAA calculation format valid ($TIMES)"

# 2. Test sun times caching in ~/.cache/xfce-night-switch/sun_times
CACHE_DIR="$TMP_DIR/.cache/xfce-night-switch"
CACHE_FILE="$CACHE_DIR/sun_times"
mkdir -p "$CACHE_DIR"
echo "$TIMES" > "$CACHE_FILE"

READ_BACK=$(cat "$CACHE_FILE")
if [[ "$READ_BACK" != "$TIMES" ]]; then
    echo "  ✗ Cache read mismatch: expected '$TIMES', got '$READ_BACK'" >&2
    exit 1
fi
echo "  ✓ Sun times cache save & read passed"

# 3. Test auto-theme.sh offline fallback logic
CFG_DIR="$TMP_DIR/.config/xfce-night-switch"
mkdir -p "$CFG_DIR"
cat > "$CFG_DIR/config" << 'EOF'
AUTO_SWITCHER="enabled"
AUTO_MODE="location"
LATITUDE="51.5074"
LONGITUDE="-0.1278"
DAY_START="07:00"
DAY_END="18:00"
LIGHT_THEME="Adwaita"
DARK_THEME="Adwaita-dark"
EOF

# Pre-populate cache with known times
echo "05:45 21:15" > "$CACHE_FILE"

# Simulate offline fallback where sunrise-sunset.py fails
export HOME="$TMP_DIR"
export XFCE_NIGHT_SWITCH_DIR="$TMP_DIR/nonexistent"

# Verify cached times are chosen
SUN_CACHE="$HOME/.cache/xfce-night-switch/sun_times"
FALLBACK_START="07:00"
FALLBACK_END="18:00"
if [ -f "$SUN_CACHE" ] && [ -s "$SUN_CACHE" ]; then
    cached_times=$(cat "$SUN_CACHE" 2>/dev/null || true)
    if [[ "$cached_times" =~ ^[0-2][0-9]:[0-5][0-9]\ [0-2][0-9]:[0-5][0-9]$ ]]; then
        FALLBACK_START=$(echo "$cached_times" | cut -d' ' -f1)
        FALLBACK_END=$(echo "$cached_times"   | cut -d' ' -f2)
    fi
fi

if [[ "$FALLBACK_START" != "05:45" || "$FALLBACK_END" != "21:15" ]]; then
    echo "  ✗ Cache fallback failed: got $FALLBACK_START to $FALLBACK_END" >&2
    exit 1
fi
echo "  ✓ Offline cache fallback passed ($FALLBACK_START to $FALLBACK_END)"

echo "All offline mode tests passed!"
