#!/bin/bash
VERSION="1.2.1"
set -euo pipefail

QTLOG_REPO_DIR_DEFAULT="$HOME/qtlog_repo"
QTLOG_LOG_SUBDIR_DEFAULT="Log"
QTLOG_TIMESTAMP_FORMAT_DEFAULT="%Y-%m-%d %H%M %Z"
QTLOG_DEVICE_DEFAULT="Fold7"

if [ -f "$HOME/.qtlog_env" ]; then
  . "$HOME/.qtlog_env"
fi

QTLOG_REPO_DIR="${QTLOG_REPO_DIR:-$QTLOG_REPO_DIR_DEFAULT}"
QTLOG_LOG_SUBDIR="${QTLOG_LOG_SUBDIR:-$QTLOG_LOG_SUBDIR_DEFAULT}"
QTLOG_TIMESTAMP_FORMAT="${QTLOG_TIMESTAMP_FORMAT:-$QTLOG_TIMESTAMP_FORMAT_DEFAULT}"
QTLOG_DEVICE="${QTLOG_DEVICE:-$QTLOG_DEVICE_DEFAULT}"
QTLOG_DISABLE_GIT="${QTLOG_DISABLE_GIT:-0}"

QTLOG_LOG_DIR="$QTLOG_REPO_DIR/$QTLOG_LOG_SUBDIR"

print_help() {
  cat <<EOF
qtlog v${VERSION}
Usage: qtlog.sh [OPTIONS] "message"
Options:
  --device NAME     Override device tag
  --no-git          Skip git operations
  --offline         Alias for --no-git
  --dry-run         Show what would happen
  -h, --help        Show this help
EOF
}

NO_GIT="$QTLOG_DISABLE_GIT"
DRY_RUN=0
OVERRIDE_DEVICE=""

ARGS=()
while [ $# -gt 0 ]; do
  case "$1" in
    --device) shift; OVERRIDE_DEVICE="$1";;
    --no-git|--offline) NO_GIT=1;;
    --dry-run) DRY_RUN=1;;
    -h|--help) print_help; exit 0;;
    --) shift; ARGS+=("$@"); break;;
    -*) echo "Unknown option $1"; exit 1;;
    *) ARGS+=("$1");;
  esac
  shift
done

if [ ${#ARGS[@]} -eq 0 ]; then
  echo "Usage: qtlog.sh \"message\""
  exit 1
fi

MESSAGE="${ARGS[*]}"

if [ -n "$OVERRIDE_DEVICE" ]; then DEVICE="$OVERRIDE_DEVICE"; else DEVICE="$QTLOG_DEVICE"; fi

mkdir -p "$QTLOG_LOG_DIR"
TODAY="$(date +%Y-%m-%d)"
NOW_FMT="$(date +"$QTLOG_TIMESTAMP_FORMAT")"
LOG_FILE="$QTLOG_LOG_DIR/$TODAY.log"
ENTRY="[$DEVICE] $TODAY $NOW_FMT $MESSAGE"

if [ "$DRY_RUN" -eq 1 ]; then
  echo "Would append to $LOG_FILE: $ENTRY"
  [ "$NO_GIT" -ne 0 ] && echo "(git disabled)" || echo "(would git add/commit/push)"
  exit 0
fi

echo "$ENTRY" >> "$LOG_FILE"

cd "$QTLOG_REPO_DIR"

if [ "$NO_GIT" -ne 0 ]; then
  echo "qtlog: git disabled (NO_GIT=1 or --no-git)"
  exit 0
fi

echo "qtlog: pulling latest changes..."
if ! git pull --rebase; then
  echo "qtlog: warning: pull failed; continuing local"
fi

git add "$LOG_FILE"
COMMIT_MSG="[$DEVICE] $TODAY $NOW_FMT $MESSAGE"
git commit -m "$COMMIT_MSG" >/dev/null 2>&1 || echo "qtlog: nothing new to commit"
echo "qtlog: pushing..."
if ! git push; then
  echo "qtlog: warning: push failed; local only"
fi

echo "qtlog: logged '$COMMIT_MSG' to $LOG_FILE"
