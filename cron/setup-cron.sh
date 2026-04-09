#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# setup-cron.sh
# Installs (or updates) ALL Ora FacePass automation cron jobs.
#
# Jobs installed:
#
#   1. Lead Aging Alert          — 9:00 PM MT daily
#   2. Demo Follow-Up Drafter    — 12:00 PM MT daily
#
# Cron entries use TZ=America/Denver so they fire at the correct local time
# year-round, regardless of DST. No dual UTC entries needed.
# A lockfile inside demo-followup-drafter.js provides an additional guard
# against accidental duplicate runs within a 4-hour window.
#
# Usage:
#   chmod +x cron/setup-cron.sh
#   ./cron/setup-cron.sh
# ─────────────────────────────────────────────────────────────────────────────

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
NODE_BIN="$(command -v node || echo '/usr/bin/node')"

# Ensure log directory exists
mkdir -p "$PROJECT_DIR/logs"

# ── 1. Lead Aging Alert (9 PM MT) ─────────────────────────────────────────────
AGING_SCRIPT="$PROJECT_DIR/scripts/lead-aging-alert.js"
AGING_LOG="$PROJECT_DIR/logs/lead-aging-alert.log"
AGING_TAG="# ora-facepass-lead-aging-alert"
AGING_JOB="TZ=America/Denver 0 21 * * * cd '$PROJECT_DIR' && '$NODE_BIN' '$AGING_SCRIPT' >> '$AGING_LOG' 2>&1 $AGING_TAG"

# ── 2. Demo Follow-Up Drafter (12 PM MT) ──────────────────────────────────────
DEMO_SCRIPT="$PROJECT_DIR/scripts/demo-followup-drafter.js"
DEMO_LOG="$PROJECT_DIR/logs/demo-followup-drafter.log"
DEMO_TAG="# ora-facepass-demo-followup"
DEMO_JOB="TZ=America/Denver 0 12 * * * cd '$PROJECT_DIR' && '$NODE_BIN' '$DEMO_SCRIPT' >> '$DEMO_LOG' 2>&1 $DEMO_TAG"

echo "Installing Ora FacePass cron jobs..."
echo "  Project: $PROJECT_DIR"
echo "  Node:    $NODE_BIN"
echo ""

# Load existing crontab (ignore error if empty)
CURRENT_CRON="$(crontab -l 2>/dev/null || true)"

# Remove any previously installed versions of both jobs
CLEAN_CRON="$(echo "$CURRENT_CRON" | grep -v "$AGING_TAG" | grep -v "$DEMO_TAG" || true)"

# Append the new jobs
NEW_CRON="${CLEAN_CRON}
${AGING_JOB}
${DEMO_JOB}"

# Install
echo "$NEW_CRON" | crontab -

echo "✓ Cron jobs installed:"
echo ""
crontab -l | grep -E "$AGING_TAG|$DEMO_TAG"
echo ""
echo "Lead Aging Alert:       9:00 PM MT  (TZ=America/Denver)"
echo "Demo Follow-Up Drafter: 12:00 PM MT (TZ=America/Denver)"
echo ""
echo "Logs:"
echo "  $AGING_LOG"
echo "  $DEMO_LOG"
