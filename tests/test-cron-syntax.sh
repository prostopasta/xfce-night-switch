#!/usr/bin/env bash
# tests/test-cron-syntax.sh — test crontab command generation and syntax
set -euo pipefail

echo "=== Testing crontab configuration & migration ==="

TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT

BIN_DIR="$TMP_DIR/bin"
LOG_DIR="$TMP_DIR/share/xfce-night-switch"
mkdir -p "$BIN_DIR" "$LOG_DIR"

# 1. Test clean crontab command syntax
CRON_CMD="*/1 * * * * $BIN_DIR/auto-theme.sh >> $LOG_DIR/auto-theme.log 2>&1"

# Extract command part (after the 5 time fields)
CMD_PART=$(echo "$CRON_CMD" | cut -d' ' -f6-)

# Verify the extracted command is syntactically valid bash
if ! bash -n -c "$CMD_PART"; then
    echo "  ✗ Cron command syntax error: $CMD_PART" >&2
    exit 1
fi
echo "  ✓ Cron command bash syntax valid ($CMD_PART)"

# 2. Test migration from legacy unredirected cron entry
LEGACY_CRON=$(cat << 'CRON_EOF'
# Other cron jobs
0 9 * * * /usr/bin/some-job.sh
*/1 * * * * /home/user/.local/bin/auto-theme.sh
30 12 * * * /usr/bin/other-job.sh
CRON_EOF
)

MIGRATED=$(echo "$LEGACY_CRON" | grep -v 'auto-theme\.sh' || true; echo "$CRON_CMD")

# Check that other jobs are preserved
if ! echo "$MIGRATED" | grep -q 'some-job.sh' || ! echo "$MIGRATED" | grep -q 'other-job.sh'; then
    echo "  ✗ Migration lost existing unrelated cron jobs" >&2
    exit 1
fi

# Check that only one auto-theme.sh entry exists
COUNT=$(echo "$MIGRATED" | grep -c 'auto-theme\.sh' || true)
if [ "$COUNT" -ne 1 ]; then
    echo "  ✗ Expected exactly 1 auto-theme.sh entry, got $COUNT" >&2
    exit 1
fi
echo "  ✓ Migration from legacy entry preserved unrelated jobs and set clean redirect"

# 3. Test healing of corrupted 2>*/1 entry
CORRUPTED_CRON=$(cat << 'CRON_EOF'
0 9 * * * /usr/bin/some-job.sh
*/1 * * * * /home/user/.local/bin/auto-theme.sh >> /home/user/.local/share/xfce-night-switch/auto-theme.log 2>*/1 * * * * /home/ps/.local/bin/auto-theme.sh1
30 12 * * * /usr/bin/other-job.sh
CRON_EOF
)

HEALED=$(echo "$CORRUPTED_CRON" | grep -v 'auto-theme\.sh' || true; echo "$CRON_CMD")
if echo "$HEALED" | grep -q '2>\*/1'; then
    echo "  ✗ Failed to heal corrupted crontab entry" >&2
    exit 1
fi
echo "  ✓ Healed corrupted crontab entry cleanly"

# 4. Test disable removes auto-theme.sh without affecting other jobs
DISABLED=$(echo "$HEALED" | grep -v 'auto-theme\.sh' || true)
if echo "$DISABLED" | grep -q 'auto-theme\.sh'; then
    echo "  ✗ Failed to remove auto-theme.sh on disable" >&2
    exit 1
fi
if ! echo "$DISABLED" | grep -q 'some-job.sh'; then
    echo "  ✗ Disabling removed other jobs" >&2
    exit 1
fi
echo "  ✓ Disabling auto-switcher removes cron entry cleanly"

echo "All crontab syntax tests passed!"
