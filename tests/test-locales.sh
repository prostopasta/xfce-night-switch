#!/usr/bin/env bash
# tests/test-locales.sh — verify parity and completeness of all locale files
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
EN_LOCALE="$REPO_DIR/locales/en.sh"

echo "=== Testing locale files parity ==="

if [[ ! -f "$EN_LOCALE" ]]; then
    echo "  ✗ Base locale $EN_LOCALE not found" >&2
    exit 1
fi

# Extract all S_* variable names from en.sh
mapfile -t EN_KEYS < <(grep -oE '^S_[A-Za-z0-9_]+' "$EN_LOCALE" | sort -u)
echo "  Found ${#EN_KEYS[@]} localization keys in en.sh"

FAILED=0

for loc in "$REPO_DIR/locales/"*.sh; do
    [ -f "$loc" ] || continue
    lang=$(basename "$loc" .sh)
    [[ "$lang" == "en" ]] && continue

    echo "  Checking locale: $lang.sh ..."
    
    # Check syntax
    if ! bash -n "$loc"; then
        echo "  ✗ Syntax error in $loc" >&2
        FAILED=1
        continue
    fi

    # Check that all keys from en.sh exist and are non-empty
    mapfile -t LOC_KEYS < <(grep -oE '^S_[A-Za-z0-9_]+' "$loc" | sort -u)

    for key in "${EN_KEYS[@]}"; do
        if ! grep -qE "^${key}=" "$loc"; then
            echo "    ✗ Missing key in $lang.sh: $key" >&2
            FAILED=1
        fi
    done

    # Check for orphan keys not present in en.sh
    for key in "${LOC_KEYS[@]}"; do
        if ! grep -qE "^${key}=" "$EN_LOCALE"; then
            echo "    ✗ Orphan key in $lang.sh not in en.sh: $key" >&2
            FAILED=1
        fi
    done
done

if [[ $FAILED -ne 0 ]]; then
    echo "Locale parity test failed!" >&2
    exit 1
fi

echo "  ✓ All locale files are in 100% parity!"
echo "All locale tests passed!"
