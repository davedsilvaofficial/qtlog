#!/bin/bash
export TZ=America/Toronto
VERSION="1.2.2"
set -euo pipefail

# --- Defaults -----------------------------------------------------
QTLOG_REPO_DIR_DEFAULT="$HOME/qtlog_repo"
QTLOG_LOG_SUBDIR_DEFAULT="Log"
QTLOG_TIMESTAMP_FORMAT_DEFAULT="%Y-%m-%d %H%M %Z"
QTLOG_DEVICE_DEFAULT="Fold7"

# --- Optional env override (~/.qtlog_env) -------------------------
# You can set any of:
#   QTLOG_REPO_DIR
#   QTLOG_LOG_SUBDIR
#   QTLOG_TIMESTAMP_FORMAT
#   QTLOG_DEVICE
#   QTLOG_DISABLE_GIT  (1 = disable git entirely)
if [ -f "$HOME/.qtlog_env" ]; then
  # shellcheck source=/dev/null
  . "$HOME/.qtlog_env"
fi

LOG_MODE="local"
# --- Effective settings -------------------------------------------
QTLOG_REPO_DIR="${QTLOG_REPO_DIR:-$QTLOG_REPO_DIR_DEFAULT}"
QTLOG_LOG_SUBDIR="${QTLOG_LOG_SUBDIR:-$QTLOG_LOG_SUBDIR_DEFAULT}"
QTLOG_TIMESTAMP_FORMAT="${QTLOG_TIMESTAMP_FORMAT:-$QTLOG_TIMESTAMP_FORMAT_DEFAULT}"
QTLOG_DEVICE="${QTLOG_DEVICE:-$QTLOG_DEVICE_DEFAULT}"
QTLOG_DISABLE_GIT="${QTLOG_DISABLE_GIT:-0}"

QTLOG_LOG_DIR="$QTLOG_REPO_DIR/$QTLOG_LOG_SUBDIR"

# --- CLI help -----------------------------------------------------
print_help() {
  cat <<EOF
qtlog v${VERSION}
Usage: qtlog.sh [OPTIONS] "message"

Options:
  --device NAME   Override device tag (default: $QTLOG_DEVICE)
  --no-git        Skip git operations for this run
  --offline       Alias for --no-git
  --dry-run       Show what would happen, but don't modify files or git
  --stamp-now        Print authoritative current time (ET) and exit
  --reconcile        Print timestamp reconciliation (system/qtlog/git)

  -h, --help      Show this help
EOF
}

# --- CLI parsing --------------------------------------------------
NO_GIT="$QTLOG_DISABLE_GIT"
DRY_RUN=0
OVERRIDE_DEVICE=""
STAMP_NOW=0
RECONCILE=0


ARGS=()
while [ $# -gt 0 ]; do
  case "$1" in
    --device)
      shift
      if [ $# -eq 0 ]; then
        echo "qtlog: --device requires a NAME" >&2
        exit 1
      fi
      OVERRIDE_DEVICE="$1"
      shift
      ;;
    --no-git|--offline)
        NO_GIT=1
        shift
        ;;
    --mode)
        shift
        if [ $# -eq 0 ]; then
            echo "qtlog: --mode requires one of: local|git|both" >&2
            exit 1
        fi
        LOG_MODE="$1"
        shift
        ;;
    --stamp-now)
        STAMP_NOW=1
        shift
        ;;
    --reconcile)
        RECONCILE=1
        shift
        ;;

    --dry-run)
      DRY_RUN=1
      shift
      ;;
    -h|--help)
      print_help
      exit 0
      ;;
    --)
      shift
      ARGS+=("$@")
      break
      ;;
    -*)
      echo "qtlog: Unknown option $1" >&2
      exit 1
      ;;
    *)
      ARGS+=("$1")
      shift
      ;;
  esac
done

# --- Early helpers short-circuit ---
if [ "$STAMP_NOW" -eq 1 ]; then
  echo "STAMP_NOW: $(TZ=America/Toronto date '+%Y-%m-%d %H:%M:%S %Z' )";
  [ "$RECONCILE" -eq 0 ] && exit 0;
fi

if [ "$RECONCILE" -eq 1 ] && [ "$DRY_RUN" -eq 0 ]; then
  SYS_NOW="$(TZ=America/Toronto date '+%Y-%m-%d %H:%M:%S %Z' )";
  echo "RECONCILE:";
  echo "  System now : $SYS_NOW";
  exit 0;
fi

if [ "${#ARGS[@]}" -eq 0 ]; then
  echo "qtlog: message is required" >&2
  echo "Try: qtlog.sh --help" >&2
  exit 1
fi
# --- Apply LOG_MODE ---
case "$LOG_MODE" in
  local) NO_GIT=1 ;;
  git|both) NO_GIT=0 ;;
esac


MESSAGE="${ARGS[*]}"

# --- Derived values -----------------------------------------------
TODAY="$(date +%Y-%m-%d)"
NOW_FMT="$(date +"$QTLOG_TIMESTAMP_FORMAT")"
DEVICE="${OVERRIDE_DEVICE:-$QTLOG_DEVICE}"

LOG_FILE="$QTLOG_LOG_DIR/$TODAY.log"

# --- Dry-run short-circuit ----------------------------------------
if [ "$DRY_RUN" -ne 0 ]; then
  echo "qtlog DRY-RUN"
  echo "  Repo dir  : $QTLOG_REPO_DIR"
  echo "  Log dir   : $QTLOG_LOG_DIR"
  echo "  Log file  : $LOG_FILE"
  echo "  Device    : $DEVICE"
  echo "  Timestamp : $NOW_FMT"
  echo "  Message   : $MESSAGE"
  echo "  Git       : $( [ "$NO_GIT" -ne 0 ] && echo 'disabled' || echo 'enabled' )"
  exit 0
fi

# --- Ensure log directory exists ---------------------------------
if ! mkdir -p "$QTLOG_LOG_DIR"; then
  echo "qtlog: failed to create log directory: $QTLOG_LOG_DIR" >&2
  exit 1
fi

# --- Write log entry ----------------------------------------------
ENTRY="[$DEVICE] $NOW_FMT $MESSAGE"
echo "$ENTRY" >> "$LOG_FILE"

# --- Git sync -----------------------------------------------------
cd "$QTLOG_REPO_DIR"

if [ "$NO_GIT" -ne 0 ]; then
  echo "qtlog: git disabled (NO_GIT=1, --no-git, or --offline)"
  echo "qtlog: logged '$ENTRY' to $LOG_FILE (no git actions)"
  exit 0
fi

echo "qtlog: pulling latest changes..."
if ! git pull --rebase; then
  echo "qtlog: warning: pull failed; continuing with local copy"
fi

git add "$LOG_FILE"
COMMIT_MSG="[$DEVICE] $TODAY $NOW_FMT $MESSAGE"
git commit -m "$COMMIT_MSG" >/dev/null 2>&1 || echo "qtlog: nothing to commit (maybe duplicate message?)"

echo "qtlog: pushing..."
if ! git push; then
  echo "qtlog: warning: push failed; local log only"
fi

echo "qtlog: logged '$COMMIT_MSG' to $LOG_FILE"
