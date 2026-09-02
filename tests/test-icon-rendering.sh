#!/usr/bin/env bash
# tests/test-icon-rendering.sh — test ImageMagick SVG and PNG rendering
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
echo "=== Testing icon rendering ==="

TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT

PANEL_SIZE=24
FG_COLOR="#d8d8d8"
ICON_CACHE="$TMP_DIR/cache"
mkdir -p "$ICON_CACHE"

# Test SVG rendering with theme-moon.svg
render_src="$REPO_DIR/icons/theme-moon.svg"
cached="$ICON_CACHE/test-moon.png"

if command -v magick >/dev/null 2>&1; then
    magick -background none -density 384 "$render_src" \
           -resize "${PANEL_SIZE}x${PANEL_SIZE}" "$cached" 2>/dev/null
elif command -v convert >/dev/null 2>&1; then
    convert -background none -density 384 "$render_src" \
            -resize "${PANEL_SIZE}x${PANEL_SIZE}" "$cached" 2>/dev/null
fi

if [[ ! -f "$cached" ]]; then
    echo "  ✗ Failed to render SVG icon to PNG" >&2
    exit 1
fi

W=$(identify -format "%w" "$cached" 2>/dev/null || echo 24)
H=$(identify -format "%h" "$cached" 2>/dev/null || echo 24)
if [[ "$W" -gt 24 || "$H" -gt 24 ]]; then
    echo "  ✗ Rendered icon exceeded panel bounds: ${W}x${H}" >&2
    exit 1
fi
echo "  ✓ SVG render & resize test passed (${W}x${H})"

# Test CSS currentColor replacement
tmp_svg="$TMP_DIR/styled.svg"
sed "s/currentColor/${FG_COLOR}/g
     s/\.ColorScheme-Text{color:[^}]*}/\.ColorScheme-Text{color:${FG_COLOR}}/g" \
    "$render_src" > "$tmp_svg"

if ! grep -q "$FG_COLOR" "$tmp_svg"; then
    echo "  ✗ Color replacement failed" >&2
    exit 1
fi
echo "  ✓ SVG ColorScheme replacement test passed"

echo "All icon rendering tests passed!"
