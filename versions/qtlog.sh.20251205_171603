#!/usr/bin/env bash
set -euo pipefail

# Root of the qtlog repository
REPO_ROOT="$HOME/qtlog_repo"
cd "$REPO_ROOT"

ENV_FILE="$REPO_ROOT/.qtlog_env"
if [ ! -f "$ENV_FILE" ]; then
  echo "qtlog: env file $ENV_FILE not found"
  exit 1
fi

# Load configuration
# shellcheck disable=SC1090
. "$ENV_FILE"

# Default values if not set
QTLOG_USER="${QTLOG_USER:-$(whoami)}"
QTLOG_DEVICE="${QTLOG_DEVICE:-UnknownDevice}"
QTLOG_LOG_DIR="${QTLOG_LOG_DIR:-$REPO_ROOT/Log}"
QTLOG_TIMESTAMP_FORMAT="${QTLOG_TIMESTAMP_FORMAT:-%Y-%m-%d %H%M}"
QTLOG_AUTO_PUSH="${QTLOG_AUTO_PUSH:-false}"
QTLOG_AUTO_PULL="${QTLOG_AUTO_PULL:-true}"

# --- Auto-pull from origin ---
if [ "$QTLOG_AUTO_PULL" = "true" ]; then
  echo "qtlog: pulling latest changes from origin..."
  git pull --rebase
fi

LOG_DATE="$(date +%Y-%m-%d)"
LOG_TIME="$(date +%H%M)"
LOG_STAMP="$(date +"$QTLOG_TIMESTAMP_FORMAT")"

LOG_TITLE="$*"
if [ -z "$LOG_TITLE" ]; then
  LOG_TITLE="(no message)"
fi

# Device-tagged log entry
ENTRY="[$QTLOG_DEVICE] $LOG_STAMP $LOG_TITLE"

DAY_DIR="$QTLOG_LOG_DIR/$LOG_DATE"
mkdir -p "$DAY_DIR"
LOG_FILE="$DAY_DIR/$LOG_TIME.log"

echo "$ENTRY" >> "$LOG_FILE"

# Snapshot current script version
VERSIONS_DIR="$REPO_ROOT/versions"
mkdir -p "$VERSIONS_DIR"
cp "$REPO_ROOT/qtlog.sh" "$VERSIONS_DIR/qtlog.sh.$(date +%Y%m%d_%H%M%S)"

echo "qtlog: created entry '$ENTRY' under $LOG_FILE"

git add .
git commit -m "$ENTRY"

if [ "$QTLOG_AUTO_PUSH" = "true" ]; then
  git push
fi
