# -----------------------------------------------------------------------------
# GOVERNANCE & DISCIPLINE
#
# This script is governed by:
#   - docs/QT-Coding-SOP.md   (execution rules, change control, proof requirements)
#   - CHANGELOG.md            (auditable history of all functional changes)
#
# Execution Gating:
#   - Preview Mode is default
#   - NO code change or git action occurs without the explicit word: Execute
#   - Every executed step MUST produce unconditional output as proof
#
# If behavior here conflicts with the SOP or CHANGELOG, THIS FILE IS WRONG.
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# CHANGE CONTROL (MANDATORY)
#
# This file is governed by CHANGELOG.md
#
# Rules:
# - Any functional change MUST be reflected in CHANGELOG.md
# - Before editing: review CHANGELOG.md for regression risk
# - Recovery is normal; undocumented recovery is NOT
#
# This header exists to prevent silent regression of:
# - Notion logging behavior
# - Git data-room hardening
# - CLI/runtime switches
# -----------------------------------------------------------------------------

# -------------------------------------------------------------------
# GOVERNANCE NOTICE — EXECUTABLE SCRIPT


# This script is an operational control artifact.
#
# • It is listed and governed under:
#   docs/SOFTWARE_INVENTORY.md
#
# • Any modification to this file:
#   - MUST preserve its governance intent
#   - MUST be reflected in SOFTWARE_INVENTORY.md
#   - SHOULD be reviewed for disclosure, compliance, and audit impact
#
# • This script exists to reduce human error and memory dependence.
#
# • Accidental deletion, bypass, or silent modification may result in:
#   - Loss of audit integrity
#   - Disclosure control failure
#   - Operational regression
#
# Treat as infrastructure, not convenience code.

confirm_commit() {
  echo
  read -r -p "Commit log entry to git? [y/N]: " response
  case "$response" in
    [yY][eE][sS]|[yY]) return 0 ;;
    *) echo "qtlog: commit skipped"; return 1 ;;
  esac
}

# -------------------------------------------------------------------
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
TODO_MODE=0
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

Execution Mode Hierarchy:

qtlog.sh
├── --help
│   └── Display command usage and execution model
├── --log "<message>" (default)
│   ├── local      → filesystem log only
│   ├── notion     → Notion Log page only
│   └── both       → filesystem + Notion Log
├── --todo "<item>"
│   └── Write to Notion ToDo page only
├── --dry-run
│   └── Preview execution without side effects
├── --reconcile
│   └── Time reconciliation / audit mode
└── --offline / --no-git
    └── Disable git operations

EOF
}

# --- CLI parsing --------------------------------------------------

# Execution Mode Hierarchy (Operator-Facing)
# qtlog.sh
# ├── --help
# ├── --log (default)
# │   ├── local | notion | both
# ├── --todo
# ├── --dry-run
# ├── --reconcile
# └── --offline / --no-git
#
# NOTE: This hierarchy is duplicated in --help output intentionally.
# Any change here MUST be reflected in help and CHANGELOG.

NO_GIT="$QTLOG_DISABLE_GIT"
WANT_COMMIT=0
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
    --todo)
      TODO_MODE=1
      ;;
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
  --notion)
    LOG_MODE=notion
    shift
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
  --export-check)
    EXPORT_CHECK=1
    shift
    ;;

    -*)
        echo "qtlog: Unknown option $1" &>2
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

# --- Export check helper (must run before message-required guard) ---
if [ "${EXPORT_CHECK:-0}" -eq 1 ]; then
  echo "Export check: scanning for non-/public references...";
  BAD=$(git grep -n -I -E "(^|[^A-Za-z0-9])(~\/|\/home\/|\/data\/|\/storage\/|\/sdcard\/|\/projects\/|api\.notion\.com)" -- "public/**" "README.md" 2>/dev/null || true);
  if [ -n "$BAD" ]; then
    echo "Export blocked: references outside /public detected:";
    echo "$BAD";
    exit 1;
  fi
  echo "Export check passed: only /public content referenced.";
  exit 0;
fi

if [ "${#ARGS[@]}" -eq 0 ]; then
  echo "qtlog: message is required" >&2
  echo "Try: qtlog.sh --help" >&2
  exit 1
fi
# --- Apply LOG_MODE ---
case "$LOG_MODE" in
  local)  NO_GIT=1 ;;
  git)    NO_GIT=0 ;;
  notion) NO_GIT=1 ;;
  both)   NO_GIT=0 ;;
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

if [ "$LOG_MODE" = "notion" ] || [ "$LOG_MODE" = "both" ]; then

write_notion_todo() {
  [ -z "${NOTION_API_KEY:-}" ] && return 0
  [ -z "${NOTION_TODO_PAGE_ID:-}" ] && return 0  # multi-page routing (Todo page)

  local content="$1"

  curl -s https://api.notion.com/v1/blocks/${NOTION_TODO_PAGE_ID}/children \
    -H "Authorization: Bearer $NOTION_API_KEY" \
    -H "Notion-Version: 2022-06-28" \
    -H "Content-Type: application/json" \
    -d "{\"children\": [{\"object\": \"block\", \"type\": \"paragraph\", \"paragraph\": {\"rich_text\": [{\"type\": \"text\", \"text\": {\"content\": \"$content\"}}]}}]}" \
    > /dev/null
}

write_notion() {

if [ "$TODO_MODE" -eq 1 ]; then
  write_notion_todo "$ENTRY"
fi

  [ -z "${NOTION_API_KEY:-}" ] && return 0
  [ -z "${NOTION_LOG_PAGE_ID:-}" ] && return 0  # multi-page routing (Log page)

  local content="$ENTRY"

  curl -s https://api.notion.com/v1/blocks/${NOTION_LOG_PAGE_ID}/children \
    -H "Authorization: Bearer $NOTION_API_KEY" \
    -H "Notion-Version: 2022-06-28" \
    -H "Content-Type: application/json" \
    -d "{
      \"children\": [{
        \"object\": \"block\",
        \"type\": \"paragraph\",
        \"paragraph\": {
          \"rich_text\": [{
            \"type\": \"text\",
            \"text\": { \"content\": \"$content\" }
          }]
        }
      }]
    }" >/dev/null
}
  write_notion
fi

# --- Git sync -----------------------------------------------------
cd "$QTLOG_REPO_DIR"

if [ "$NO_GIT" -ne 0 ]; then
  echo "qtlog: git disabled (NO_GIT=1, --no-git, or --offline)"

echo "qtlog: pulling latest changes..."
if ! git pull --rebase; then
  echo "qtlog: warning: pull failed; continuing with local copy"
fi

git add "$LOG_FILE"
COMMIT_MSG="[$DEVICE] $TODAY $NOW_FMT $MESSAGE"
confirm_commit || exit 0
    git commit -m "$COMMIT_MSG" >/dev/null 2>&1 || echo "qtlog: nothing to commit (maybe duplicate message?)"

echo "qtlog: pushing..."
if ! git push; then
  echo "qtlog: warning: push failed; local log only"
fi

echo "qtlog: logged '$COMMIT_MSG' to $LOG_FILE"

# --- Public export guard ---
if [[ "${EXPORT_CHECK:-0}" == "1" ]]; then
  echo "Export check: scanning for non-/public references..."
  BAD=$(git grep -n -I -E "(^|[^A-Za-z0-9])(~\/|\/home\/|\/data\/|\/storage\/|\/sdcard\/|\/projects\/|api\.notion\.com)" -- "public/**" "README.md" 2>/dev/null || true);
  if [[ -n "$BAD" ]]; then
    echo "❌ Export blocked: references outside /public detected:"
    echo "$BAD"
    exit 1
  fi
  echo "✅ Export check passed: only /public content referenced."
  exit 0
fi
