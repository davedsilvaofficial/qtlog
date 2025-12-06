#!/data/data/com.termux/files/usr/bin/bash
# qtlog - simple Git-backed daily log for QT (Fold7)

set -e

# --- Repo + environment config ------------------------------

REPO_DIR="$HOME/qtlog_repo"
ENV_FILE="$REPO_DIR/.qtlog_env"

if [ ! -f "$ENV_FILE" ]; then
  echo "qtlog: missing config: $ENV_FILE"
  exit 1
fi

# shellcheck source=/dev/null
. "$ENV_FILE"

# --- Required + default variables ---------------------------

: "${QTLOG_USER:?QTLOG_USER must be set in .qtlog_env}"

# Default log directory if not set in env
QTLOG_LOG_DIR="${QTLOG_LOG_DIR:-$REPO_DIR/Log}"

# Default timestamp format: TIME + TIMEZONE (no date here)
# Example: "0822 ET"
QTLOG_TIMESTAMP_FORMAT="${QTLOG_TIMESTAMP_FORMAT:-%H%M %Z}"

# Auto pull / push toggles
QTLOG_AUTO_PULL="${QTLOG_AUTO_PULL:-true}"
QTLOG_AUTO_PUSH="${QTLOG_AUTO_PUSH:-true}"

# --- Device tag: manual override > auto-detect ---------------

# If QTLOG_DEVICE is unset or set to "auto", try to auto-detect.
if [ -z "${QTLOG_DEVICE:-}" ] || [ "$QTLOG_DEVICE" = "auto" ]; then
  MODEL=""
  if command -v getprop >/dev/null 2>&1; then
    MODEL="$(getprop ro.product.model 2>/dev/null || echo "")"
  fi

  HOSTNAME_VAL="$(hostname 2>/dev/null | tr ' ' '_' || echo "")"

  if [ -n "$MODEL" ]; then
    QTLOG_DEVICE="$MODEL"
  elif [ -n "$HOSTNAME_VAL" ]; then
    QTLOG_DEVICE="$HOSTNAME_VAL"
  else
    QTLOG_DEVICE="device"
  fi
fi

: "${QTLOG_DEVICE:?QTLOG_DEVICE could not be determined}"

# --- Compute timestamps + paths ------------------------------

# Date for the log file name and entry
LOG_DATE="$(date +%Y-%m-%d)"

# Time + timezone (format can be overridden in .qtlog_env)
LOG_TIMESTAMP="$(date +"$QTLOG_TIMESTAMP_FORMAT")"

LOG_DIR="$QTLOG_LOG_DIR"
VERSIONS_DIR="$REPO_DIR/versions"

mkdir -p "$LOG_DIR" "$VERSIONS_DIR"

LOG_FILE="$LOG_DIR/$LOG_DATE.log"

# --- Accept log message from CLI -----------------------------

if [ "$#" -eq 0 ]; then
  echo "Usage: ./qtlog.sh \"log message\""
  exit 1
fi

LOG_MESSAGE="$*"

# Final entry format:
# [DEVICE] YYYY-MM-DD HHMM TZ Message...
LOG_TITLE="[$QTLOG_DEVICE] $LOG_DATE $LOG_TIMESTAMP $LOG_MESSAGE"
ENTRY_LINE="$LOG_TITLE"

# --- Safe auto-pull from GitHub ------------------------------

if [ "$QTLOG_AUTO_PULL" = "true" ]; then
  echo "qtlog: pulling latest changes from origin (safe)…"
  if ! git -C "$REPO_DIR" pull --rebase; then
    echo "qtlog: warning: pull failed; continuing with local copy."
  fi
fi

# --- Append to log file --------------------------------------

echo "$ENTRY_LINE" >> "$LOG_FILE"

# --- Stage updated log + script snapshot ---------------------

SNAPSHOT_TIME="$(date +%Y%m%d_%H%M%S)"
SCRIPT_NAME="$(basename "$0")"
SNAPSHOT_PATH="$VERSIONS_DIR/$SCRIPT_NAME.$SNAPSHOT_TIME"

cp "$0" "$SNAPSHOT_PATH"
chmod 755 "$SNAPSHOT_PATH"

git -C "$REPO_DIR" add "$LOG_FILE" "$SNAPSHOT_PATH"

# --- Commit & optional push ----------------------------------

git -C "$REPO_DIR" commit -m "$LOG_TITLE" || true

if [ "$QTLOG_AUTO_PUSH" = "true" ]; then
  echo "qtlog: pushing to origin…"
  git -C "$REPO_DIR" push || true
fi

echo "qtlog: created entry '$ENTRY_LINE' under $LOG_FILE"
