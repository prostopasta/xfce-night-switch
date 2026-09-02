#!/usr/bin/env bash
# tests/run-tests.sh — master test runner
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_DIR"

echo "========================================"
echo "  xfce-night-switch Test Suite"
echo "========================================"
echo ""

# 1. Syntax check
echo "── 1. Checking Bash syntax ─────────────"
for f in scripts/*.sh packaging/bin/* install.sh locales/*.sh tests/*.sh; do
    bash -n "$f"
    echo "  ✓ Syntax OK: $f"
done
echo ""

# 2. Python syntax check
echo "── 2. Checking Python syntax ───────────"
python3 -m py_compile scripts/sunrise-sunset.py
echo "  ✓ Python OK: scripts/sunrise-sunset.py"
echo ""

# 3. Unit & Integration tests
echo "── 3. Running functional tests ─────────"
for test_script in tests/test-*.sh; do
    [ -f "$test_script" ] || continue
    bash "$test_script"
    echo ""
done

echo "========================================"
echo "  All tests passed successfully!"
echo "========================================"
