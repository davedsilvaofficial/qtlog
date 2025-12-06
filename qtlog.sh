# --- Device tag: manual override > auto-detect ---
# If QTLOG_DEVICE is set (and not "auto"), we respect it as a manual override.
# Otherwise we try to auto-detect a reasonable device name.
if [ -z "${QTLOG_DEVICE:-}" ] || [ "$QTLOG_DEVICE" = "auto" ]; then
  MODEL=""
  # Try Android model name (Termux)
  if command -v getprop >/dev/null 2>&1; then
    MODEL="$(getprop ro.product.model 2>/dev/null | tr ' ' '_' | tr -d '\r')"
  fi
  HOSTNAME_VAL="$(hostname 2>/dev/null | tr ' ' '_' | tr -d '\r')"

  if [ -n "$MODEL" ]; then
    QTLOG_DEVICE="$MODEL"
  elif [ -n "$HOSTNAME_VAL" ]; then
    QTLOG_DEVICE="$HOSTNAME_VAL"
  else
    QTLOG_DEVICE="device"
  fi
fi
#!/data/data/com.termux/files/usr/bin/bash
# qtlog - simple Git-backed daily log for QT

set -e

# --- Repo + environment config ---
REPO_DIR="$HOME/qtlog_repo"
ENV_FILE="$REPO_DIR/.qtlog_env"

# Load environment
if [ ! -f "$ENV_FILE" ]; then
  echo "qtlog: missing config: $ENV_FILE"
  exit 1
fi

# shellcheck source=/dev/null
. "$ENV_FILE"

# Required + default variables
: "${QTLOG_USER:?QTLOG_USER must be set in .qtlog_env}"
: "${QTLOG_DEVICE:?QTLOG_DEVICE must be set in .qtlog_env}"
: "${QTLOG_TIMESTAMP_FORMAT:=%Y-%m-%d_%H%M}"
: "${QTLOG_LOG_DIR:=$REPO_DIR/Log}"
: "${QTLOG_AUTO_PULL:=true}"
: "${QTLOG_AUTO_PUSH:=true}"

# --- Compute timestamps + paths ---
LOG_DATE=$(date +%Y-%m-%d)
LOG_TIMESTAMP=$(date +"$QTLOG_TIMESTAMP_FORMAT")

LOG_DIR="$QTLOG_LOG_DIR"
VERSIONS_DIR="$REPO_DIR/versions"

mkdir -p "$LOG_DIR" "$VERSIONS_DIR"

LOG_FILE="$LOG_DIR/$LOG_DATE.log"

# --- Accept log message from CLI ---
if [ $# -eq 0 ]; then
  echo "Usage: ./qtlog.sh \"log message\""
  exit 1
fi

LOG_MESSAGE="$*"
LOG_TITLE="[$QTLOG_DEVICE] $LOG_DATE $LOG_TIMESTAMP $LOG_MESSAGE"
ENTRY_LINE="$LOG_TITLE"

# --- Append to log file ---
echo "$ENTRY_LINE" >> "$LOG_FILE"

# --- Snapshot script version ---
SNAPSHOT_TIME=$(date +%Y%m%d_%H%M%S)
SCRIPT_SNAPSHOT="$VERSIONS_DIR/qtlog.sh.$SNAPSHOT_TIME"
cp "$REPO_DIR/qtlog.sh" "$SCRIPT_SNAPSHOT"

# --- Safe auto-pull from GitHub ---
if [ "$QTLOG_AUTO_PULL" = "true" ]; then
  echo "qtlog: pulling latest changes from origin (safe)…"
  if ! git -C "$REPO_DIR" pull --rebase; then
    echo "qtlog: warning: pull failed; continuing with local copy."
  fi
fi

# --- Stage updated log + script snapshot ---
cd "$REPO_DIR" || exit 1
git add "$LOG_FILE" "$SCRIPT_SNAPSHOT"

# --- Commit if changes exist ---
if ! git diff --cached --quiet; then
  git commit -m "$LOG_TITLE"

  # --- Auto-push to GitHub ---
  if [ "$QTLOG_AUTO_PUSH" = "true" ]; then
    echo "qtlog: pushing to origin…"
    git push
  fi
else
  echo "qtlog: nothing to commit."
fi

# --- Success message ---
echo "qtlog: created entry '$ENTRY_LINE' under $LOG_FILE"
