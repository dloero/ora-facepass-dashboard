#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# setup-cron.sh
# Installs (or updates) the Ora FacePass Lead Aging Alert cron job.
#
# Schedule: 9:00 PM Mountain Time daily
#   • MDT (UTC−6, Mar–Nov):  cron runs at 03:00 UTC  → "0 3 * * *"
#   • MST (UTC−7, Nov–Mar):  cron runs at 04:00 UTC  → "0 4 * * *"
#
# To handle the DST shift automatically we run at BOTH 03:00 and 04:00 UTC
# but guard with a TZ-aware check inside the script itself so it only fires
# once per day at the correct local time.
#
# Usage:
#   chmod +x cron/setup-cron.sh
#   ./cron/setup-cron.sh
# ─────────────────────────────────────────────────────────────────────────────

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
SCRIPT_PATH="$PROJECT_DIR/scripts/lead-aging-alert.js"
LOG_PATH="$PROJECT_DIR/logs/lead-aging-alert.log"
NODE_BIN="$(command -v node || echo '/usr/bin/node')"

# Ensure log directory exists
mkdir -p "$PROJECT_DIR/logs"

# Cron job line (tagged so we can identify / replace it)
CRON_TAG="# ora-facepass-lead-aging-alert"
CRON_JOB_MDT="0 3 * * * cd '$PROJECT_DIR' && '$NODE_BIN' '$SCRIPT_PATH' >> '$LOG_PATH' 2>&1 $CRON_TAG-mdt"
CRON_JOB_MST="0 4 * * * cd '$PROJECT_DIR' && '$NODE_BIN' '$SCRIPT_PATH' >> '$LOG_PATH' 2>&1 $CRON_TAG-mst"

echo "Installing Ora FacePass Lead Aging Alert cron jobs..."
echo "  Project: $PROJECT_DIR"
echo "  Script:  $SCRIPT_PATH"
echo "  Log:     $LOG_PATH"
echo "  Node:    $NODE_BIN"
echo ""

# Load existing crontab (ignore error if empty)
CURRENT_CRON="$(crontab -l 2>/dev/null || true)"

# Remove any previously installed versions of this job
CLEAN_CRON="$(echo "$CURRENT_CRON" | grep -v "$CRON_TAG" || true)"

# Append the new jobs
NEW_CRON="${CLEAN_CRON}
${CRON_JOB_MDT}
${CRON_JOB_MST}"

# Install
echo "$NEW_CRON" | crontab -

echo "✓ Cron jobs installed:"
echo ""
crontab -l | grep "$CRON_TAG"
echo ""
echo "The alert will fire every day at 9:00 PM MT (3:00 AM UTC in summer / 4:00 AM UTC in winter)."
echo "Logs → $LOG_PATH"
