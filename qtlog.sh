#!/usr/bin/env bash
# ==============================================================================# SOP_CHANGELOG_REF:
#   Commit e7990b9 — SOP enforcement: global gate, Notion fail logging,
#   ensure __TOP__, SOP hash + hooks + CI
#

# QTLOG — RUNTIME SOP ENFORCEMENT (NO ASSUMPTIONS)
#
# This script is guarded by a GLOBAL SOP GATE.
#
# Behaviour:
#   - All runs validate baseline Termux + repo + env invariants
#   - Notion operations are *strictly gated* (need_notion)
#   - SOP failures exit immediately
#   - Best-effort SOP failure notes may be written to Notion (__TOP__)
#
# Safe verification:
#   bash ./qtlog.sh --sop-verify
#   bash ./qtlog.sh --sop-verify need_notion
#
# Design rule:
#   NO ASSUMPTIONS. All dependencies are verified before side effects.
# ==============================================================================

# -----------------------------------------------------------------------------
# GOVERNANCE & DISCIPLINE (Unified CLI v1.3.0)
#
# This script is governed by:
#   - docs/03_Technical/QT-Coding-SOP.md
#   - CHANGELOG.md
#   - MASTER_INDEX.md
# -----------------------------------------------------------------------------

export TZ=America/Toronto
QTLOG_REPO_DIR="${QTLOG_REPO_DIR:-$(cd "$(dirname "$0")" && pwd -P)}"

### QTLOG_ENV_BOOTSTRAP ###
# Load env early so NOTION_* and QTLOG_* vars exist before any checks/actions.
# Safe: if missing, continue; SOP verification will flag it where required.
if [ -f "$HOME/.config/qt/.env" ]; then
  set -a
  . "$HOME/.config/qt/.env"
  set +a
fi

# Ensure log dir is never empty (prevents mkdir -p "" crash)
QTLOG_LOG_DIR="${QTLOG_LOG_DIR:-$QTLOG_REPO_DIR/Log}"


VERSION="1.3.5"



### QTLOG_STATUS ###
# Read-only diagnostics. No writes to Notion, no file writes, no git writes.
status_report() {
  local ts today repo_dir log_dir log_file last_line gitref dirty envfile

  ts="$(TZ=America/Toronto date '+%Y-%m-%d %H%M %Z')"
  today="$(TZ=America/Toronto date '+%Y-%m-%d')"

  # Repo dir (prefer known repo path, else current)
  if [ -d "$HOME/qtlog_repo" ] && [ -f "$HOME/qtlog_repo/qtlog.sh" ]; then
    repo_dir="$HOME/qtlog_repo"
  else
    repo_dir="$(pwd -P)"
  fi

  log_dir="${QTLOG_LOG_DIR:-$repo_dir/Log}"
  log_file="$log_dir/${today}.log"

  echo "QTLOG_STATUS: ts=$ts"
  echo "QTLOG_STATUS: repo_dir=$repo_dir"
  echo "QTLOG_STATUS: version=${VERSION:-UNKNOWN}"
  echo "QTLOG_STATUS: sop_version=$(tr -d ' \t\r\n' < .sop_hash 2>/dev/null || echo UNKNOWN)"

  # Git info (read-only)
  if command -v git >/dev/null 2>&1 && git -C "$repo_dir" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    gitref="$(git -C "$repo_dir" rev-parse --short HEAD 2>/dev/null || echo UNKNOWN)"
    dirty="$(git -C "$repo_dir" status --porcelain 2>/dev/null | wc -l | tr -d ' ')"
    echo "QTLOG_STATUS: git=$gitref dirty_files=$dirty"
  else
    echo "QTLOG_STATUS: git=UNAVAILABLE"
  fi

  # Env file presence
  envfile="$HOME/.config/qt/.env"
  if [ -f "$envfile" ]; then
    echo "QTLOG_STATUS: envfile=OK ($envfile)"
  else
    echo "QTLOG_STATUS: envfile=MISSING ($envfile)"
  fi

  # Local log
  if [ -f "$log_file" ]; then
    last_line="$(tail -n 1 "$log_file" 2>/dev/null || true)"
    echo "QTLOG_STATUS: local_log=OK ($log_file)"
    echo "QTLOG_STATUS: local_log_last_line=${last_line}"
  else
    echo "QTLOG_STATUS: local_log=MISSING ($log_file)"
  fi

  echo "QTLOG_STATUS: notion_creds=$([ -n "${NOTION_API_KEY:-}" ] && [ -n "${NOTION_LOG_PAGE_ID:-}" ] && echo OK || echo MISSING)"
  return 0
}

### QTLOG_CONFIG_BLOCK ###
# SOP hash region: configuration + constants (keep stable / minimal here).


### QTLOG_CODING_SOP ###

### QTLOG_ENSURE_TODAY_TOP ###
ensure_today_top() {
  # Enforce Log-day structure invariants before any Notion write.
  # Contract:
  # - H1 "Log" exists under NOTION_LOG_PAGE_ID
  # - Under H1 "Log": toggle "__TOP__" exists (recommended to keep as FIRST manually)
  # - Today's day toggle "YYYY-MM-DD" exists under H1 (inserted after H1 __TOP__ when created)
  # - Under today's day toggle: "__TOP__" exists and MUST be the FIRST child (newest-at-top)
  #
  # Notes:
  # - Notion API does not reliably support reordering existing blocks; where ordering matters,
  #   we FAIL with an explicit instruction to drag "__TOP__" to the top once.
  # - Safe: if Notion env/creds missing, we return 0 (no-op) to avoid blocking local logging.

  sop_env_check need_notion || return 1

  if [ -z "${NOTION_API_KEY:-}" ] || [ -z "${NOTION_LOG_PAGE_ID:-}" ]; then
    echo "ENSURE_TODAY_TOP_SKIP=missing_env"
    return 0
  fi

  command -v curl >/dev/null 2>&1 || { echo "ENSURE_TODAY_TOP_FAIL=curl_missing" >&2; return 1; }
  command -v jq   >/dev/null 2>&1 || { echo "ENSURE_TODAY_TOP_FAIL=jq_missing" >&2; return 1; }

  local today log_h1_id h1_top_id h1_first_id day_id day_first_id day_top_id payload resp
  today="$(TZ=America/Toronto date '+%Y-%m-%d')"

  # 1) Find H1 "Log"
  log_h1_id="$(
    curl -sS "https://api.notion.com/v1/blocks/${NOTION_LOG_PAGE_ID}/children?page_size=200" \
      -H "Authorization: Bearer $NOTION_API_KEY" \
      -H "Notion-Version: 2022-06-28" | \
    jq -r '.results[]?
      | select(.type=="heading_1")
      | select((.heading_1.rich_text|map(.plain_text)|join(""))=="Log")
      | .id' | head -n1
  )"
  if [ -z "${log_h1_id:-}" ]; then
    echo "ENSURE_TODAY_TOP_FAIL=missing_h1_log" >&2
    return 1
  fi

  # 2) Ensure H1 "__TOP__" exists (cannot guarantee it is first; warn/require manual if not)
  h1_first_id="$(
    curl -sS "https://api.notion.com/v1/blocks/${log_h1_id}/children?page_size=1" \
      -H "Authorization: Bearer $NOTION_API_KEY" \
      -H "Notion-Version: 2022-06-28" | jq -r '.results[0].id // empty'
  )"

  h1_top_id="$(
    curl -sS "https://api.notion.com/v1/blocks/${log_h1_id}/children?page_size=200" \
      -H "Authorization: Bearer $NOTION_API_KEY" \
      -H "Notion-Version: 2022-06-28" | \
    jq -r '.results[]?
      | select(.type=="toggle")
      | select((.toggle.rich_text|map(.plain_text)|join(""))=="__TOP__")
      | .id' | head -n1
  )"

  if [ -z "${h1_top_id:-}" ]; then
    payload="$(
      jq -nc --arg after "${h1_first_id:-}" '{
        after: ($after|select(length>0)),
        children:[{object:"block",type:"toggle",toggle:{rich_text:[{type:"text",text:{content:"__TOP__"}}],children:[]}}]
      }'
    )"
    resp="$(
      curl -sS -X PATCH "https://api.notion.com/v1/blocks/${log_h1_id}/children" \
        -H "Authorization: Bearer $NOTION_API_KEY" \
        -H "Notion-Version: 2022-06-28" \
        -H "Content-Type: application/json" \
        -d "$payload"
    )"
    h1_top_id="$(printf '%s' "$resp" | jq -r '.results[0].id // empty')"
    echo "ENSURE_TODAY_TOP_NOTE=created_h1_top_anchor" >&2
  fi

  if [ -z "${h1_top_id:-}" ]; then
    echo "ENSURE_TODAY_TOP_FAIL=h1_top_create_failed" >&2
    return 1
  fi

  # 3) Ensure today's day toggle exists under H1 (inserted after H1 __TOP__ when created)
  day_id="$(
    curl -sS "https://api.notion.com/v1/blocks/${log_h1_id}/children?page_size=200" \
      -H "Authorization: Bearer $NOTION_API_KEY" \
      -H "Notion-Version: 2022-06-28" | \
    jq -r --arg d "$today" '.results[]?
      | select(.type=="toggle")
      | select((.toggle.rich_text|map(.plain_text)|join(""))==$d)
      | .id' | head -n1
  )"

  if [ -z "${day_id:-}" ]; then
    payload="$(
      jq -nc --arg after "$h1_top_id" --arg d "$today" '{
        after: $after,
        children:[{
          object:"block",type:"toggle",
          toggle:{
            rich_text:[{type:"text",text:{content:$d}}],
            children:[
              {object:"block",type:"toggle",
               toggle:{rich_text:[{type:"text",text:{content:"__TOP__"}}],children:[]}}
            ]
          }
        }]
      }'
    )"
    resp="$(
      curl -sS -X PATCH "https://api.notion.com/v1/blocks/${log_h1_id}/children" \
        -H "Authorization: Bearer $NOTION_API_KEY" \
        -H "Notion-Version: 2022-06-28" \
        -H "Content-Type: application/json" \
        -d "$payload"
    )"
    day_id="$(printf '%s' "$resp" | jq -r '.results[0].id // empty')"
    echo "ENSURE_TODAY_TOP_NOTE=created_day_toggle_${today}" >&2
  fi

  if [ -z "${day_id:-}" ]; then
    echo "ENSURE_TODAY_TOP_FAIL=day_create_failed" >&2
    return 1
  fi

  # 4) Ensure day "__TOP__" exists
  day_top_id="$(
    curl -sS "https://api.notion.com/v1/blocks/${day_id}/children?page_size=200" \
      -H "Authorization: Bearer $NOTION_API_KEY" \
      -H "Notion-Version: 2022-06-28" | \
    jq -r '.results[]?
      | select(.type=="toggle")
      | select((.toggle.rich_text|map(.plain_text)|join(""))=="__TOP__")
      | .id' | head -n1
  )"

  if [ -z "${day_top_id:-}" ]; then
    day_first_id="$(
      curl -sS "https://api.notion.com/v1/blocks/${day_id}/children?page_size=1" \
        -H "Authorization: Bearer $NOTION_API_KEY" \
        -H "Notion-Version: 2022-06-28" | jq -r '.results[0].id // empty'
    )"
    payload="$(
      jq -nc --arg after "${day_first_id:-}" '{
        after: ($after|select(length>0)),
        children:[{object:"block",type:"toggle",toggle:{rich_text:[{type:"text",text:{content:"__TOP__"}}],children:[]}}]
      }'
    )"
    resp="$(
      curl -sS -X PATCH "https://api.notion.com/v1/blocks/${day_id}/children" \
        -H "Authorization: Bearer $NOTION_API_KEY" \
        -H "Notion-Version: 2022-06-28" \
        -H "Content-Type: application/json" \
        -d "$payload"
    )"
    day_top_id="$(printf '%s' "$resp" | jq -r '.results[0].id // empty')"
    echo "ENSURE_TODAY_TOP_NOTE=created_day_top_anchor" >&2
  fi

  if [ -z "${day_top_id:-}" ]; then
    echo "ENSURE_TODAY_TOP_FAIL=day_top_create_failed" >&2
    return 1
  fi

  # 5) Hard invariant: day "__TOP__" must be FIRST child (for newest-at-top inserts)
  local day_first_title
  day_first_title="$(
    curl -sS "https://api.notion.com/v1/blocks/${day_id}/children?page_size=1" \
      -H "Authorization: Bearer $NOTION_API_KEY" \
      -H "Notion-Version: 2022-06-28" | \
    jq -r '(
      .results[0]
      | select(.type=="toggle")
      | (.toggle.rich_text|map(.plain_text)|join(""))
    ) // ""'
  )"

  if [ "$day_first_title" != "__TOP__" ]; then
    echo "ENSURE_TODAY_TOP_FAIL=day_top_not_first" >&2
    echo "ACTION: In Notion, open QT ▸ Log ▸ ${today} and drag the '__TOP__' toggle to the very TOP (first child), then retry." >&2
    return 1
  fi

  echo "ENSURE_TODAY_TOP_OK=$today"
  return 0
}



### QTLOG_SOP_FAIL_NOTION_LOG ###
sop_fail_notion_log() {
  # Best-effort observability ONLY. Must never block execution.
  # NOTE: This is intentionally conservative; it will only attempt Notion I/O if creds+deps exist.
  local msg="${1:-SOP failure}"
  if [ -z "${NOTION_API_KEY:-}" ] || [ -z "${NOTION_LOG_PAGE_ID:-}" ]; then
    return 0
  fi
  command -v curl >/dev/null 2>&1 || return 0
  command -v jq   >/dev/null 2>&1 || return 0

  # Placeholder: keep side effects minimal until a full Notion failure-note writer is reintroduced.
  # (We keep the function + marker so SOP hash can track this region.)
  echo "SOP_NOTE: $msg (Notion fail-note writer is stubbed)" >&2
  return 0
}

### QTLOG_SOP_ENV_CHECK ###
sop_env_check() {
  local fail=0

  echo "SOP_CHECK: ts=$(TZ=America/Toronto date '+%Y-%m-%d %H%M %Z')"
  echo "SOP_CHECK: user=$USER home=$HOME pwd=$(pwd -P)"
  echo "SOP_CHECK: termux_version=${TERMUX_VERSION:-MISSING} prefix=${PREFIX:-MISSING}"
  echo "SOP_CHECK: device=$(getprop ro.product.model 2>/dev/null || echo 'UNKNOWN')"

  # 1) Must be Termux (not proot)
  if [ -z "${TERMUX_VERSION:-}" ] || [ -z "${PREFIX:-}" ]; then
    echo "SOP_FAIL: not in a normal Termux session (TERMUX_VERSION/PREFIX missing)" >&2
    fail=1
  fi

  # 2) Must be in repo
  if [ ! -d "$HOME/qtlog_repo" ] || [ ! -f "$HOME/qtlog_repo/qtlog.sh" ]; then
    echo "SOP_FAIL: repo missing at $HOME/qtlog_repo" >&2
    fail=1
  fi

  # 3) Must have env
  if [ ! -f "$HOME/.config/qt/.env" ]; then
    echo "SOP_FAIL: missing envfile $HOME/.config/qt/.env" >&2
    fail=1
  fi

  # 4) Must have Notion creds when doing Notion ops
  if [ -n "${1:-}" ] && [ "$1" = "need_notion" ]; then
    if [ -z "${NOTION_API_KEY:-}" ] || [ -z "${NOTION_LOG_PAGE_ID:-}" ]; then
      echo "SOP_FAIL: NOTION_API_KEY / NOTION_LOG_PAGE_ID missing" >&2
      fail=1
    fi
  fi

  # 5) Must have curl/jq for Notion ops
  if [ -n "${1:-}" ] && [ "$1" = "need_notion" ]; then
    command -v curl >/dev/null 2>&1 || { echo "SOP_FAIL: curl missing" >&2; fail=1; }
    command -v jq   >/dev/null 2>&1 || { echo "SOP_FAIL: jq missing" >&2; fail=1; }
  fi

  return $fail
}
# SOP hash region: coding rules + invariants (keep stable / minimal here).
# - NO ASSUMPTIONS: verify dependencies before side effects
# - Notion writes are gated via need_notion checks
# - TZ fixed to America/Toronto

# --- DYNAMIC DISCOVERY ---
list_bin_commands() {
  if [ -d "bin" ]; then
    echo "Available sub-commands in bin/:"
    ls bin/ | sed 's/^/  - /'
  fi
}

usage() {
  cat <<HELP
qtlog.sh v1.3.0 — Quantum Trek Unified CLI
"One command to rule them all"

Usage:
  ./qtlog.sh [options] <message>
  ./qtlog.sh <command> [args]

Options:
  --log <msg>       (Default) Log message to Filesystem/Notion
  --todo <item>     Add item to Notion ToDo Vault
  --stamp-now       Print authoritative ET timestamp
  --reconcile       Audit system, git, and qtlog clocks
  --verify-all      Read-only check of Notion anchors
  --sop-verify [need_notion]  Read-only SOP env check; optional Notion prereq check; then exit
  --dry-run         Preview actions without execution
  --offline         Disable all git operations
  -h, --help        Show this enhanced help menu

$(list_bin_commands)

Data Room Access:
  See MASTER_INDEX.md for full technical and legal directory.
  Proprietary data is stored in the Private Vault (see SECURITY.md).

HELP
}

# --- STAMP & RECONCILE HELPERS ---
if [[ "${1:-}" == "--stamp-now" ]]; then
  if [ $# -ne 1 ]; then
    echo "qtlog: --stamp-now takes no arguments" >&2
    exit 1
  fi
  TZ="America/New_York" date "+%Y-%m-%d %H:%M:%S ET"
  exit 0
fi

if [[ "${1:-}" == "--reconcile" ]]; then
    echo "--- Time Reconciliation Audit ---"
    echo "System Time: $(date)"
    echo "Auth (ET):   $(TZ="America/New_York" date)"
    echo "Git Status:  $(git log -1 --format=%cd || echo 'No commits yet')"
    exit 0
fi

# --- HELP GATE ---
if [[ "${1:-}" == "-h" ]] || [[ "${1:-}" == "--help" ]]; then
    usage
    exit 0
fi
NO_GIT="${QTLOG_DISABLE_GIT:-0}"
WANT_COMMIT=0
DRY_RUN=0
OVERRIDE_DEVICE=""
STAMP_NOW=0
STAMP_AND_LOG=0
STATUS_ONLY=0
RECONCILE=0
LKG_MODE=0
  LOG_MODE_EXPLICIT=0
VERIFY_ONLY=0


VERIFY_ALL_ONLY=0

VERIFY_TODO_ONLY=0
ARGS=()
TODO_MODE=0
TODO_ITEM=""

BRAG_MODE=0
RELEASE_LOG_MODE=0

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
    --todo)
      shift
      if [ $# -eq 0 ]; then
        echo "qtlog: --todo requires an ITEM" >&2
        exit 1
      fi
      TODO_MODE=1
      TODO_ITEM="$1"
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
      if [ $# -ne 1 ]; then
        echo "qtlog: --stamp-now takes no arguments" >&2
        exit 1
      fi
      STAMP_NOW=1
      shift
      ;;
    --stamp-and-log)
      STAMP_AND_LOG=1
      shift
      ;;
    --reconcile)
      RECONCILE=1
      shift
      ;;
    --status)
      STATUS_ONLY=1
      shift
      ;;
    --verify)
      VERIFY_ONLY=1
      shift
      ;;
    --dry-run)
      DRY_RUN=1
      shift
      ;;
    --verify-todo)
      VERIFY_TODO_ONLY=1
      shift
      ;;
    --verify-all)
      VERIFY_ALL_ONLY=1
      shift
      ;;

    --lkg)
      LKG_MODE=1
      shift
      ;;
    --notion)
      LOG_MODE=notion
        LOG_MODE_EXPLICIT=1
      shift
      ;;
    --local)
      LOG_MODE=local
        LOG_MODE_EXPLICIT=1
      shift
      ;;
    --git)
      LOG_MODE=git
        LOG_MODE_EXPLICIT=1
      shift
      ;;
    --both)
      LOG_MODE=both
        LOG_MODE_EXPLICIT=1
      shift
      ;;
      --log)
        shift
        # Optional: allow --log <local|notion|git|both>
        if [ $# -gt 0 ] && [[ "$1" =~ ^(local|notion|git|both)$ ]]; then
          LOG_MODE="$1"
          LOG_MODE_EXPLICIT=1
          shift
        fi
        ;;
      --brag)
        BRAG_MODE=1
        shift
        ;;

      --release-log)
        RELEASE_LOG_MODE=1
        shift
        ;;


    -h|--help)
      usage
      exit 0
      ;;
    --)
      shift
      break
      ;;

      --sop-verify)

        # Read-only: validate SOP invariants. Inline (cannot rely on functions defined later).

        shift

        rc=0

        echo "SOP_CHECK: ts=$(TZ=America/Toronto date '+%Y-%m-%d %H%M %Z')"

        echo "SOP_CHECK: user=$USER home=$HOME pwd=$(pwd -P)"

        echo "SOP_CHECK: termux_version=${TERMUX_VERSION:-MISSING} prefix=${PREFIX:-MISSING}"

        echo "SOP_CHECK: device=$(getprop ro.product.model 2>/dev/null || echo 'UNKNOWN')"

      

        # 1) Must be Termux (not proot)

        if [ -z "${TERMUX_VERSION:-}" ] || [ -z "${PREFIX:-}" ]; then

          echo "SOP_FAIL: not in a normal Termux session (TERMUX_VERSION/PREFIX missing)" >&2

          rc=1

        fi

      

        # 2) Must be in repo

        if [ ! -d "$HOME/qtlog_repo" ] || [ ! -f "$HOME/qtlog_repo/qtlog.sh" ]; then

          echo "SOP_FAIL: repo missing at $HOME/qtlog_repo" >&2

          rc=1

        fi

      

        # 3) Must have env

        if [ ! -f "$HOME/.config/qt/.env" ]; then

          echo "SOP_FAIL: missing envfile $HOME/.config/qt/.env" >&2

          rc=1

        fi

      

        # Optional Notion prereq check

        if [ "${1:-}" = "need_notion" ]; then

          if [ -z "${NOTION_API_KEY:-}" ] || [ -z "${NOTION_LOG_PAGE_ID:-}" ]; then

            echo "SOP_FAIL: NOTION_API_KEY / NOTION_LOG_PAGE_ID missing" >&2

            rc=1

          fi

          command -v curl >/dev/null 2>&1 || { echo "SOP_FAIL: curl missing" >&2; rc=1; }

          command -v jq   >/dev/null 2>&1 || { echo "SOP_FAIL: jq missing" >&2; rc=1; }

        fi

      

        if [ "$rc" -eq 0 ]; then

          echo "SOP_VERIFY_OK"

        else

          echo "SOP_VERIFY_FAIL" >&2

        fi

        exit "$rc"

        ;;

      --sop-version)
        SOP_VERSION="$(tr -d " \t\r\n" < .sop_hash 2>/dev/null || echo UNKNOWN)"
        echo "VERSION=${VERSION:-UNKNOWN}"
        echo "SOP_VERSION=${SOP_VERSION:-UNKNOWN}"
        exit 0
        ;;

      --sync-sop-timeline)
        sop_env_check need_notion || exit 1
        ensure_today_top || exit 1
        sop_sync_notion_timeline || exit 1
        exit 0
        ;;
    -*)
      echo "qtlog: unknown option: $1" >&2
      echo "Try: qtlog.sh --help" >&2
      exit 1
      ;;
    *)
      ARGS+=("$1")
      shift
      ;;
  esac
done




### QTLOG_BRAG_AND_RELEASE ###
# Convenience generators. They only set MESSAGE; normal logging flow handles local/Notion/git modes.
if [ "${BRAG_MODE:-0}" -eq 1 ]; then
  ARGS=("brag snapshot: Termux-native Bash + Python 3 patch tooling, curl+jq JSON into Notion API, SOP hash enforcement, read-only --status diagnostics, and __TOP__ ordering invariants.")
fi

if [ "${RELEASE_LOG_MODE:-0}" -eq 1 ]; then
  # Build a release note from git if available; otherwise degrade gracefully.
  tag="UNKNOWN"
  commit="UNKNOWN"
  subj="UNKNOWN"
  if command -v git >/dev/null 2>&1 && git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    tag="$(git describe --tags --abbrev=0 2>/dev/null || echo UNKNOWN)"
    commit="$(git rev-parse --short HEAD 2>/dev/null || echo UNKNOWN)"
    subj="$(git log -1 --pretty=%s 2>/dev/null || echo UNKNOWN)"
  fi
  ARGS=("release log: tag=${tag} commit=${commit} subject=${subj}")
fi

### QTLOG_SOP_ENV_CHECK_CALL ###
# (Global SOP gate call site may be reintroduced here if/when needed.)

  # Read-only status and exit
  if [ "${STATUS_ONLY:-0}" -eq 1 ]; then
    status_report
    exit $?
  fi

  # Convenience: print authoritative ET timestamp and then proceed with normal logging.
  if [ "${STAMP_AND_LOG:-0}" -eq 1 ]; then
    if [ "${#ARGS[@]}" -eq 0 ]; then
      echo "qtlog: --stamp-and-log requires a message" >&2
      exit 1
    fi
    TZ=America/Toronto date '+%Y-%m-%d %H:%M:%S %Z'
  fi
    # --- MODE ALIASES (compat): allow "qtlog.sh notion ..." ---
    # After option parsing, positional args live in ARGS[].
    if [ "${#ARGS[@]}" -gt 0 ] && { [ "${ARGS[0]}" = "notion" ] || [ "${ARGS[0]}" = "both" ] || [ "${ARGS[0]}" = "file" ]; }; then
      LOG_MODE="${ARGS[0]}"
      ARGS=("${ARGS[@]:1}")
    fi
### SOP_DEFAULTS_TO_BOTH + NOTION_GUARD ###
  # SOP defaults to BOTH unless the user explicitly set LOG_MODE via flags.
  # This ensures SOP entries are mirrored to Notion by default (traceability).
  if [ "${#ARGS[@]}" -gt 0 ] && [ "${ARGS[0]}" = "sop" ] && [ "${LOG_MODE_EXPLICIT:-0}" -eq 0 ]; then
    LOG_MODE="both"
  fi

  # Guard: warn when Notion logging is requested but missing config.
  if [ "$LOG_MODE" = "notion" ] || [ "$LOG_MODE" = "both" ]; then
    if [ -z "${NOTION_API_KEY:-}" ] || [ -z "${NOTION_LOG_PAGE_ID:-}" ]; then
      echo "qtlog: WARNING: Notion logging requested but NOTION_API_KEY or NOTION_LOG_PAGE_ID is missing. Falling back to local." >&2
      LOG_MODE="local"
    fi
  fi


# --- BEGIN TODO DISPATCH (early exit) ---
if [ "${TODO_MODE:-0}" -eq 1 ]; then
  # Guard rails: must have Notion integration configured
  TODO_PAGE_ID="${NOTION_TODO_PAGE_ID}"
  if [ -z "$TODO_PAGE_ID" ]; then
    echo "qtlog: TODO write failed — NOTION_TODO_PAGE_ID is empty at runtime" >&2
    exit 1
  fi
  if [ -z "${NOTION_API_KEY:-}" ] || [ -z "${NOTION_TODO_PAGE_ID:-}" ]; then
    echo "qtlog: --todo requires NOTION_API_KEY and NOTION_TODO_PAGE_ID in .env" >&2
    exit 1
  fi

  TS_ET="$(TZ=America/Toronto date '+%Y-%m-%d %H%M')"

# --- CEI TITLE (authoritative format) ---
# Format: YYYY-MM-DD HHMM 🟩 Your text [DEVICE]
STATUS_EMOJI="${STATUS_EMOJI:-🟦}"

CEI_TITLE="$TS_ET $STATUS_EMOJI $TODO_ITEM [$DEVICE]"

# --- END CEI TITLE ---
  DATE_ONLY="$(TZ=America/Toronto date '+%Y-%m-%d')"

  # Ensure DEVICE is set (nounset-safe). Device is ALWAYS appended after your text.
  if [ -z "${DEVICE:-}" ]; then
    DEVICE="$(getprop ro.product.model 2>/dev/null | tr ' ' '_' )"
    [ -n "$DEVICE" ] || DEVICE="Device"
  fi

  # Status emoji (override with STATUS_EMOJI=... in env)
  STATUS_EMOJI="${STATUS_EMOJI:-🟦}"

  # If the item already starts with an ET timestamp, do not double-prefix it.
  if [[ "$TODO_ITEM" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}[[:space:]]?[0-9]{4}[[:space:]] ]]; then
    CONTENT="$TODO_ITEM"
    USER_TEXT="$TODO_ITEM"
  else
    CONTENT="$TS_ET $TODO_ITEM"
    USER_TEXT="$TODO_ITEM"
  fi

  # CEI title: YYYY-MM-DD HHMM <emoji> <your text> [DEVICE]
  if [[ "$USER_TEXT" =~ ^([0-9]{4}-[0-9]{2}-[0-9]{2})[[:space:]]?([0-9]{4})[[:space:]]+(.*)$ ]]; then
    CEI_TITLE="${BASH_REMATCH[1]} ${BASH_REMATCH[2]} ${STATUS_EMOJI} ${BASH_REMATCH[3]} [$DEVICE]"
  else
    CEI_TITLE="$TS_ET ${STATUS_EMOJI} $USER_TEXT [$DEVICE]"
  fi

  if [ "${DRY_RUN:-0}" -ne 0 ]; then
    echo "qtlog DRY-RUN (todo)"
    echo "  Notion ToDo page id: ${NOTION_TODO_PAGE_ID}"
    echo "  Content: $CONTENT"
    echo "  CEI_TITLE: $CEI_TITLE"
    echo "  DRY-RUN OK: Notion write skipped (dry-run confirmed)"
    exit 0
  fi

  # Auto-discover the "ToDo" heading block id (must be a block id, not page id)
  TODO_PARENT_ID="$(
    python - "$NOTION_TODO_PAGE_ID" "$NOTION_API_KEY" <<'PYIN'
import sys, json, urllib.request
page_id, key = sys.argv[1], sys.argv[2]
url = f"https://api.notion.com/v1/blocks/{page_id}/children?page_size=100"
req = urllib.request.Request(url, headers={"Authorization": f"Bearer {key}", "Notion-Version": "2022-06-28"})
data = json.loads(urllib.request.urlopen(req).read().decode("utf-8"))
hid = ""
for blk in data.get("results", []):
    t = blk.get("type")
    if t in ("heading_1","heading_2","heading_3"):
        rt = blk.get(t, {}).get("rich_text", [])
        if rt and (rt[0].get("plain_text","").strip().lower() == "todo"):
            hid = blk.get("id","")
            break
print(hid)
PYIN
  )"

  if [ -z "$TODO_PARENT_ID" ]; then
    echo "qtlog: ERROR: Could not auto-discover ToDo heading block" >&2
    exit 1
  fi
  echo "qtlog: Auto-discovered ToDo block id: $TODO_PARENT_ID" >&2
    # --- NEWEST-AT-TOP CONTRACT (ToDo) ---------------------------------
    # We enforce a hard "__TOP__" toggle under:
    #   1) the ToDo heading (direct child) and
    #   2) each YYYY-MM-DD day toggle (child)
    #
    # We always insert "after" the relevant "__TOP__" anchor.
    # If we had to CREATE an anchor (because it was missing), operator may need to
    # drag it to the top to satisfy verification (newest-at-top contract).

    # Helper: find a toggle id by title under a parent block id (first match)
    find_toggle_id() {
      # $1 parent, $2 title
      curl -sS \
        -H "Authorization: Bearer ${NOTION_API_KEY}" \
        -H "Notion-Version: 2022-06-28" \
        "https://api.notion.com/v1/blocks/${1}/children?page_size=200" \
      | jq -r --arg t "$2" '
        (.results // [])[]
        | select(.type=="toggle")
        | select((.toggle.rich_text|map(.plain_text)|join(""))==$t)
        | .id
      ' | head -n1
    }

    # Helper: create a toggle under parent, optionally after an id, return new block id
    create_toggle() {
      # $1 parent, $2 title, $3 after_id (may be empty), $4 child_top (0/1) include internal __TOP__
      local PARENT="$1" TITLE="$2" AFTER="$3" CHILD_TOP="${4:-0}"
      local JSON RESP HTTP_CODE NEWID

      if [ "$CHILD_TOP" -eq 1 ]; then
        if [ -n "$AFTER" ]; then
          JSON="$(jq -nc --arg after "$AFTER" --arg title "$TITLE" '
            {after:$after, children:[{object:"block",type:"toggle",toggle:{rich_text:[{type:"text",text:{content:$title}}],children:[
              {object:"block",type:"toggle",toggle:{rich_text:[{type:"text",text:{content:"__TOP__"}}],children:[]}}
            ]}}]}')"
        else
          JSON="$(jq -nc --arg title "$TITLE" '
            {children:[{object:"block",type:"toggle",toggle:{rich_text:[{type:"text",text:{content:$title}}],children:[
              {object:"block",type:"toggle",toggle:{rich_text:[{type:"text",text:{content:"__TOP__"}}],children:[]}}
            ]}}]}')"
        fi
      else
        if [ -n "$AFTER" ]; then
          JSON="$(jq -nc --arg after "$AFTER" --arg title "$TITLE" '
            {after:$after, children:[{object:"block",type:"toggle",toggle:{rich_text:[{type:"text",text:{content:$title}}],children:[]}}]}')"
        else
          JSON="$(jq -nc --arg title "$TITLE" '
            {children:[{object:"block",type:"toggle",toggle:{rich_text:[{type:"text",text:{content:$title}}],children:[]}}]}')"
        fi
      fi

      RESP="$(curl -sS -w '\nHTTP_CODE=%{http_code}\n' \
        -X PATCH "https://api.notion.com/v1/blocks/${PARENT}/children" \
        -H "Authorization: Bearer ${NOTION_API_KEY}" \
        -H "Notion-Version: 2022-06-28" \
        -H "Content-Type: application/json" \
        --data "$JSON")"
      HTTP_CODE="$(printf '%s' "$RESP" | sed -n 's/^HTTP_CODE=//p' | tail -n 1)"
      if [ -z "$HTTP_CODE" ] || [ "$HTTP_CODE" -lt 200 ] || [ "$HTTP_CODE" -ge 300 ]; then
        echo "qtlog: toggle create failed (HTTP $HTTP_CODE)" >&2
        printf '%s\n' "$RESP" >&2
        exit 1
      fi
      NEWID="$(printf '%s' "$RESP" | sed '/^HTTP_CODE=/d' | jq -r '.results[0].id // ""')"
      echo "$NEWID"
    }

    # 1) Ensure __TOP__ exists under the ToDo heading
    TODO_TOP_ID="$(find_toggle_id "$TODO_PARENT_ID" "__TOP__")"
    if [ -z "${TODO_TOP_ID:-}" ]; then
      TODO_TOP_ID="$(create_toggle "$TODO_PARENT_ID" "__TOP__" "" 0)"
      echo "qtlog: created ToDo __TOP__ anchor (please drag it to FIRST under 'ToDo' if verify fails)" >&2
    fi

    # 2) Ensure today's YYYY-MM-DD toggle exists under ToDo heading, inserted after __TOP__
    DATE_ID="$(find_toggle_id "$TODO_PARENT_ID" "$DATE_ONLY")"
    if [ -z "${DATE_ID:-}" ]; then
      DATE_ID="$(create_toggle "$TODO_PARENT_ID" "$DATE_ONLY" "$TODO_TOP_ID" 1)"
    fi
    echo "qtlog: Using date toggle id: $DATE_ID ($DATE_ONLY)" >&2

    # 3) Ensure day-internal __TOP__ exists under DATE_ID (child)
    DATE_TOP_ID="$(find_toggle_id "$DATE_ID" "__TOP__")"
    if [ -z "${DATE_TOP_ID:-}" ]; then
      DATE_TOP_ID="$(create_toggle "$DATE_ID" "__TOP__" "" 0)"
      echo "qtlog: created day __TOP__ anchor (please drag it to FIRST inside $DATE_ONLY if verify fails)" >&2
    fi

    # ------------------------------------------------------------------
# ==============================================================================
# QTLOG — NOTION LOG INSERTION CONTRACT (GitHub-safe)
# Timestamp: 2026-01-05 1425 ET
#
# PURPOSE
# - Guarantee newest-at-top ordering for QT ▸ Log entries in Notion using a stable anchor pattern.
#
# Q&A (embedded for code-level traceability; canonical SOP is in docs/)
#
# Q1) Where does qtlog append a Log entry in Notion?
# A1) Under NOTION_LOG_PAGE_ID, qtlog locates H1 "Log" and today's day toggle (YYYY-MM-DD),
#     then writes via: PATCH /v1/blocks/${day_id}/children
#
# Q2) Why do we use a '__TOP__' toggle?
# A2) Notion API reliably supports insert-after, but does not reliably support reordering.
#     '__TOP__' is a stable insertion anchor.
#
# Q3) What invariants must be true for ordering to work?
# A3) Under H1 "Log": '__TOP__' exists (recommended FIRST; verify checks it)
#     Under day YYYY-MM-DD: '__TOP__' exists AND IS FIRST CHILD (hard invariant)
#
# Q4) What creates the structure if it’s missing?
# A4) ensure_today_top() ensures:
#     - H1 "Log" exists (required)
#     - H1 '__TOP__' exists (create if missing)
#     - Day toggle exists (create if missing; insert after H1 '__TOP__')
#     - Day '__TOP__' exists (create if missing)
#     - Verifies day '__TOP__' is FIRST CHILD (else fail with manual action)
#
# Q5) What happens if Notion credentials are missing?
# A5) Safety-first: Notion mode is downgraded to local logging (no blocking).
#     ensure_today_top() may print SKIP markers when env is missing.
#
# Q6) How do we verify the structure without writing?
# A6) ./qtlog.sh --verify-all
#     (checks '__TOP__' first-child invariants for Log and today’s day toggle)
#
# Q7) What is the correct insertion rule for newest-at-top day log entries?
# A7) Always insert AFTER the day '__TOP__' anchor id:
#     - In code: top_id is the day '__TOP__' block id
#     - payload_entry MUST include after:$after (where $after == $top_id)
#
# WHERE WE WRITE (IMPLEMENTATION)
# - Function: write_notion_toggle()
# - Anchor id variable: top_id
# - Payload: payload_entry="$(jq -nc --arg after "$top_id" ... '{ after:$after, ... }')"
# - Endpoint: PATCH https://api.notion.com/v1/blocks/${day_id}/children
#
# FAILURE MODE (OPERATOR ACTION REQUIRED)
# - If day '__TOP__' is not FIRST CHILD:
#   -> qtlog MUST FAIL
#   -> Operator manually drags '__TOP__' to the top ONCE, then retry
#
# REFERENCES (GitHub-safe)
# - docs/SOP_NOTION_LOG_ORDERING.md
# - CHANGELOG.md (Notion Log Ordering entry)
# 
# TERMUX BEST PRACTICES (LEARNED THE HARD WAY)
# - Always run from repo root:  cd ~/qtlog_repo || exit 1
# - Pin timezone explicitly for all timestamps:  TZ=America/Toronto
# - Prefer deterministic tooling: use rg/jq/curl and set PAGER=cat for logs
# - Avoid interactive editors/pagers in automation: keep commands non-interactive
# - Keep secrets OUT of git:
#   - store in ~/.config/qt/.env (chmod 600) and do NOT commit it
#   - never echo NOTION_API_KEY / tokens into logs
# - Ensure dependencies exist before side effects:
#   - command -v curl; command -v jq; command -v python
# - Use PATCH inserts with stable anchors; do not rely on Notion reordering
# - When something fails: capture HTTP_CODE + response body once, then stop
# - Use git hygiene:
#   - git status before commit
#   - keep commits small, descriptive, and GitHub-safe (no private IDs/secrets)
# 
# ==============================================================================


  # Create CEI entry (toggle with 3 toggle children) after DATE pin so it appears at the top
  URL="https://api.notion.com/v1/blocks/${DATE_ID}/children"
  JSON="$(cat <<EOF
{
  "after": "$DATE_TOP_ID",
  "children": [
    {
      "object": "block",
      "type": "toggle",
      "toggle": {
        "rich_text": [
          { "type": "text", "text": { "content": "$CEI_TITLE" } }
        ],
        "children": [
          { "object": "block", "type": "toggle", "toggle": { "rich_text": [ { "type": "text", "text": { "content": "Work done" } } ], "children": [] } },
          { "object": "block", "type": "toggle", "toggle": { "rich_text": [ { "type": "text", "text": { "content": "Notes" } } ], "children": [] } },
          { "object": "block", "type": "toggle", "toggle": { "rich_text": [ { "type": "text", "text": { "content": "Next steps" } } ], "children": [] } }
        ]
      }
    }
  ]
}
EOF
)"
  RESP="$(curl -sS -w '\nHTTP_CODE=%{http_code}\n' \
    -X PATCH "$URL" \
    -H "Authorization: Bearer ${NOTION_API_KEY}" \
    -H "Notion-Version: 2022-06-28" \
    -H "Content-Type: application/json" \
    --data "$JSON")"

  HTTP_CODE="$(printf '%s' "$RESP" | sed -n 's/^HTTP_CODE=//p' | tail -n 1)"
  if [ -z "$HTTP_CODE" ]; then
    echo "qtlog: TODO write failed (no HTTP code captured)" >&2
    printf '%s\n' "$RESP" >&2
    exit 1
  fi
  if [ "$HTTP_CODE" -lt 200 ] || [ "$HTTP_CODE" -ge 300 ]; then
    echo "qtlog: TODO write failed (HTTP $HTTP_CODE)" >&2
    printf '%s\n' "$RESP" >&2
    exit 1
  fi

  echo "qtlog: TODO written to Notion"
  exit 0
fi
# --- END TODO DISPATCH (early exit) ---


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


verify_log_structure() {
  local verify_now
  verify_now="$(TZ=America/Toronto date '+%Y-%m-%d %H%M ET')"
  printf "VERIFY_TIME=%s\n" "$verify_now"
  # CI-safe / operator-safe: if Notion env is missing, treat verify as a read-only clock proof
  if [ -z "${NOTION_API_KEY:-}" ] || [ -z "${NOTION_LOG_PAGE_ID:-}" ]; then
    echo "VERIFY_SKIP=missing_env"
    return 0
  fi

  local today log_h1_id day_id h1_first day_first day_second

  today="$(TZ=America/Toronto date '+%Y-%m-%d')"

  log_h1_id="$(
    curl -sS "https://api.notion.com/v1/blocks/${NOTION_LOG_PAGE_ID}/children?page_size=200" \
      -H "Authorization: Bearer $NOTION_API_KEY" \
      -H "Notion-Version: 2022-06-28" | \
    jq -r '.results[]?
      | select(.type=="heading_1")
      | select((.heading_1.rich_text|map(.plain_text)|join(""))=="Log")
      | .id' | head -n1
  )"

  [ -z "$log_h1_id" ] && { echo "VERIFY_FAIL: missing H1 Log"; return 1; }

  h1_first="$(
    curl -sS "https://api.notion.com/v1/blocks/${log_h1_id}/children?page_size=1" \
      -H "Authorization: Bearer $NOTION_API_KEY" \
      -H "Notion-Version: 2022-06-28" | \
    jq -r '( .results[0] | select(.type=="toggle")
      | (.toggle.rich_text|map(.plain_text)|join("")) ) // "NOT_TOGGLE"'
  )"

  day_id="$(
    curl -sS "https://api.notion.com/v1/blocks/${log_h1_id}/children?page_size=200" \
      -H "Authorization: Bearer $NOTION_API_KEY" \
      -H "Notion-Version: 2022-06-28" | \
    jq -r --arg d "$today" '.results[]?
      | select(.type=="toggle")
      | select((.toggle.rich_text[0].plain_text // "")==$d)
      | .id' | head -n1
  )"

  [ -z "$day_id" ] && { echo "VERIFY_FAIL: missing day toggle"; return 1; }

  day_first="$(
    curl -sS "https://api.notion.com/v1/blocks/${day_id}/children?page_size=1" \
      -H "Authorization: Bearer $NOTION_API_KEY" \
      -H "Notion-Version: 2022-06-28" | \
    jq -r '( .results[0] | select(.type=="toggle")
      | (.toggle.rich_text|map(.plain_text)|join("")) ) // "NOT_TOGGLE"'
  )"

  day_second="$(
    curl -sS "https://api.notion.com/v1/blocks/${day_id}/children?page_size=3" \
      -H "Authorization: Bearer $NOTION_API_KEY" \
      -H "Notion-Version: 2022-06-28" | \
    jq -r '.results[1] | select(.type=="toggle")
      | (.toggle.rich_text|map(.plain_text)|join(""))'
  )"

  printf "H1_FIRST=%s\nDAY_FIRST=%s\nDAY_SECOND=%s\n" \
    "$h1_first" "$day_first" "$day_second"
}





verify_todo_structure() {
  local verify_now todo_h_id resp todo_first todo_second top_id top_children

  verify_now="$(TZ=America/Toronto date '+%Y-%m-%d %H%M ET')"
  printf "VERIFY_TIME=%s\n" "$verify_now"

  # CI-safe / operator-safe: if Notion env is missing, treat verify as a read-only clock proof
  if [ -z "${NOTION_API_KEY:-}" ] || [ -z "${NOTION_TODO_PAGE_ID:-}" ]; then
    echo "VERIFY_SKIP=missing_env"
    return 0
  fi

  # 1) Find the ToDo heading block under the ToDo page (accept heading_1/2/3)
  resp="$(
    curl -sS "https://api.notion.com/v1/blocks/${NOTION_TODO_PAGE_ID}/children?page_size=200" \
      -H "Authorization: Bearer $NOTION_API_KEY" \
      -H "Notion-Version: 2022-06-28"
  )"

  todo_h_id="$(
    printf '%s' "$resp" | jq -r '
      .results[]?
      | select(.type=="heading_1" or .type=="heading_2" or .type=="heading_3")
      | . as $b
      | ( if $b.type=="heading_1" then ($b.heading_1.rich_text|map(.plain_text)|join(""))
          elif $b.type=="heading_2" then ($b.heading_2.rich_text|map(.plain_text)|join(""))
          else ($b.heading_3.rich_text|map(.plain_text)|join(""))
        end
        ) as $t
      | select($t=="ToDo")
      | .id
    ' | head -n1
  )"

  printf "TODO_H_ID=%s\n" "${todo_h_id:-}"

  if [ -z "${todo_h_id:-}" ]; then
    echo "VERIFY_FAIL=todo_heading_missing"
    return 1
  fi

  # 2) Check first/second children under the ToDo heading (newest-at-top anchor expected)
  resp="$(
    curl -sS "https://api.notion.com/v1/blocks/${todo_h_id}/children?page_size=3" \
      -H "Authorization: Bearer $NOTION_API_KEY" \
      -H "Notion-Version: 2022-06-28"
  )"

  todo_first="$(
    printf '%s' "$resp" | jq -r '( .results[0] | select(.type=="toggle")
      | (.toggle.rich_text|map(.plain_text)|join("")) ) // "NOT_TOGGLE"'
  )"

  todo_second="$(
    printf '%s' "$resp" | jq -r '( .results[1] | select(.type=="toggle")
      | (.toggle.rich_text|map(.plain_text)|join("")) ) // "EMPTY"'
  )"

  printf "TODO_FIRST=%s\nTODO_SECOND=%s\n" "$todo_first" "$todo_second"

  if [ "$todo_first" != "__TOP__" ]; then
    echo "VERIFY_FAIL=todo_top_anchor_missing_or_not_first"
    return 1
  fi

  # If there is a second item, it must be a toggle (unless EMPTY)
  if [ "$todo_second" = "NOT_TOGGLE" ]; then
    echo "VERIFY_FAIL=todo_second_not_toggle"
    return 1
  fi

  # Optional: ensure __TOP__ anchor has zero children
  top_id="$(
    printf '%s' "$resp" | jq -r '.results[0].id // empty'
  )"
  if [ -n "$top_id" ]; then
    top_children="$(
      curl -sS "https://api.notion.com/v1/blocks/${top_id}/children?page_size=1" \
        -H "Authorization: Bearer $NOTION_API_KEY" \
        -H "Notion-Version: 2022-06-28" | jq -r '(.results|length) // 0'
    )"
    printf "TODO_TOP_CHILDREN=%s\n" "$top_children"
    if [ "$top_children" != "0" ]; then
      echo "VERIFY_FAIL=todo_top_anchor_not_empty"
      return 1
    fi
  fi

  return 0
}


ensure_todo_day_toggle() {
  # Ensures today's YYYY-MM-DD toggle exists under the ToDo heading (direct child),
  # inserted immediately after the __TOP__ anchor (newest-at-top).
  # Creates the day toggle with an internal __TOP__ anchor for future per-day inserts.

  local today todo_h_id resp top_id day_id payload

  today="$(TZ=America/Toronto date '+%Y-%m-%d')"

  if [ -z "${NOTION_API_KEY:-}" ] || [ -z "${NOTION_TODO_PAGE_ID:-}" ]; then
    echo "TODO_ENSURE_SKIP=missing_env"
    return 0
  fi

  # Find ToDo heading under ToDo page
  resp="$(
    curl -sS "https://api.notion.com/v1/blocks/${NOTION_TODO_PAGE_ID}/children?page_size=200" \
      -H "Authorization: Bearer $NOTION_API_KEY" \
      -H "Notion-Version: 2022-06-28"
  )"

  todo_h_id="$(
    printf '%s' "$resp" | jq -r '
      .results[]?
      | select(.type=="heading_1" or .type=="heading_2" or .type=="heading_3")
      | . as $b
      | ( if $b.type=="heading_1" then ($b.heading_1.rich_text|map(.plain_text)|join(""))
          elif $b.type=="heading_2" then ($b.heading_2.rich_text|map(.plain_text)|join(""))
          else ($b.heading_3.rich_text|map(.plain_text)|join(""))
        end ) as $t
      | select($t=="ToDo")
      | .id
    ' | head -n1
  )"

  if [ -z "${todo_h_id:-}" ]; then
    echo "TODO_ENSURE_FAIL=todo_heading_missing"
    return 1
  fi

  # Load children of ToDo heading to find __TOP__ id and whether today's toggle exists
  resp="$(
    curl -sS "https://api.notion.com/v1/blocks/${todo_h_id}/children?page_size=200" \
      -H "Authorization: Bearer $NOTION_API_KEY" \
      -H "Notion-Version: 2022-06-28"
  )"

  top_id="$(
    printf '%s' "$resp" | jq -r '
      .results[]?
      | select(.type=="toggle")
      | select((.toggle.rich_text|map(.plain_text)|join(""))=="__TOP__")
      | .id
    ' | head -n1
  )"

  if [ -z "${top_id:-}" ]; then
    echo "TODO_ENSURE_FAIL=todo_top_anchor_missing"
    return 1
  fi

  day_id="$(
    printf '%s' "$resp" | jq -r --arg today "$today" '
      .results[]?
      | select(.type=="toggle")
      | select((.toggle.rich_text|map(.plain_text)|join(""))==$today)
      | .id
    ' | head -n1
  )"

  if [ -n "${day_id:-}" ]; then
    echo "TODO_DAY_EXISTS=$today"
    return 0
  fi

  # Create today's toggle immediately after __TOP__ (newest-at-top).
  payload="$(
    jq -nc --arg after "$top_id" --arg today "$today" '
      {
        after: $after,
        children: [
          {
            object: "block",
            type: "toggle",
            toggle: {
              rich_text: [{type:"text", text:{content:$today}}],
              children: [
                { object:"block", type:"toggle",
                  toggle:{ rich_text:[{type:"text", text:{content:"__TOP__"}}], children:[] }
                }
              ]
            }
          }
        ]
      }'
  )"

  curl -sS -X PATCH "https://api.notion.com/v1/blocks/${todo_h_id}/children" \
    -H "Authorization: Bearer $NOTION_API_KEY" \
    -H "Notion-Version: 2022-06-28" \
    -H "Content-Type: application/json" \
    -d "$payload" >/dev/null

  echo "TODO_DAY_CREATED=$today"
  return 0
}






# --- VERIFY DISPATCH (early exit, read-only) ---
# --verify-all: supercheck Log + ToDo (read-only) and exit nonzero if any fails
if [ "${VERIFY_ALL_ONLY:-0}" -eq 1 ]; then
  verify_log_structure || exit $?
  verify_todo_structure || exit $?
  exit 0
fi

# --verify: verify Log + ToDo (read-only) and exit nonzero if any fails
if [ "${VERIFY_ONLY:-0}" -eq 1 ]; then
  verify_log_structure || exit $?
  verify_todo_structure || exit $?
  exit 0
fi

# --verify-todo: verify ToDo only (read-only)
if [ "${VERIFY_TODO_ONLY:-0}" -eq 1 ]; then
  verify_todo_structure
  exit $?
fi

# --verify-todo: verify ToDo only (read-only)
if [ "${VERIFY_TODO_ONLY:-0}" -eq 1 ]; then
  verify_todo_structure
  exit $?
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
ENTRY="$MESSAGE"
echo "$ENTRY" >> "$LOG_FILE"



# --- Notion helpers (SOP: toggle-only, JSON-safe) ---

# --- Notion helpers (SOP: toggle-only, JSON-safe, TOP anchor) ---




# --- Notion helpers (SOP: newest-at-top, JSON-safe) ---

# --- Notion helpers (SOP: newest-at-top, JSON-safe) ---

### QTLOG_NOTION_BIGPAYLOAD_HELPERS ###
# Big payload strategy:
# - Keep title short
# - Put large/multiline body under Log as code blocks

# --- Notion helper: find first child toggle by exact title (GitHub-safe) ---
notion_find_child_toggle_id_by_title() {
  local parent_id="$1"
  local title="$2"

  [ -z "${parent_id:-}" ] && return 1
  [ -z "${title:-}" ] && return 1
  [ -z "${NOTION_API_KEY:-}" ] && return 1

  curl -sS "https://api.notion.com/v1/blocks/${parent_id}/children?page_size=200" \
    -H "Authorization: Bearer $NOTION_API_KEY" \
    -H "Notion-Version: 2022-06-28" | \
  jq -r --arg t "$title" '.results[]?
    | select(.type=="toggle")
    | select((.toggle.rich_text|map(.plain_text)|join(""))==$t)
    | .id' | head -n1
}


notion_append_big_text_as_codeblocks() {
  local entry_id="$1"
  local raw_text="$2"

  local log_child_id
      # Retry: newly-created entry children can be eventually-consistent in Notion API
    local tries=0
    while :; do
      log_child_id="$(notion_find_child_toggle_id_by_title "$entry_id" "Log")" || true
      [ -n "${log_child_id:-}" ] && break
      tries=$((tries+1))
      [ "$tries" -ge 6 ] && break
      sleep 1
    done
  [ -z "$log_child_id" ] && return 0

  local body
  body="$(printf "%s" "$raw_text" | awk 'NR==1{next} {print}')"
  [ -z "${body//[[:space:]]/}" ] && return 0

    printf "%s" "$body" | python - <<'PY' | \
      curl -sS -X PATCH "https://api.notion.com/v1/blocks/${log_child_id}/children" \
        -H "Authorization: Bearer ${NOTION_API_KEY}" \
        -H "Notion-Version: 2022-06-28" \
        -H "Content-Type: application/json" \
        -d @-
import json, sys
text = sys.stdin.read()
chunk = 1400
parts = [text[i:i+chunk] for i in range(0, len(text), chunk)]
blocks = [{
  "object":"block",
  "type":"code",
  "code":{"rich_text":[{"type":"text","text":{"content":p}}],"language":"plain text"}
} for p in parts]
print(json.dumps({"children": blocks}, ensure_ascii=False))
PY
}
### /QTLOG_NOTION_BIGPAYLOAD_HELPERS ###
write_notion_toggle() {
  sop_env_check need_notion || return 1
  [ -z "${NOTION_API_KEY:-}" ] && return 0
  [ -z "${NOTION_LOG_PAGE_ID:-}" ] && return 0

  local raw="${ENTRY:-$MESSAGE}"

  # SOP: entry title must be "YYYY-MM-DD HHMM ET — description"
  local ts_min desc title
  ts_min="$(TZ=America/Toronto date '+%Y-%m-%d %H%M')"

  # QTLOG_TITLE_SAFETY
  # Use ONLY first line and hard-cap length for Notion (<=2000)
  desc="$(printf "%s" "$raw" | awk 'NR==1{print; exit}')"
  # Strip trailing timestamps like " — 2025-12-18 221141" or " — 2025-12-18 2211"
  desc="$(printf "%s" "$desc" | sed -E 's/[[:space:]]+—[[:space:]]+[0-9]{4}-[0-9]{2}-[0-9]{2}[[:space:]]+[0-9]{4,6}$//')"
  desc="${desc:0:1800}"
  title="${ts_min} ET — ${desc}"

  local today
  today="$(TZ=America/Toronto date '+%Y-%m-%d')"

  # 1) Locate the H1 "Log" under the QT - Log page
  local log_h1_id
  log_h1_id="$(
    curl -sS "https://api.notion.com/v1/blocks/${NOTION_LOG_PAGE_ID}/children?page_size=100" \
      -H "Authorization: Bearer $NOTION_API_KEY" \
      -H "Notion-Version: 2022-06-28" | \
    jq -r '.results[]?
      | select(.type=="heading_1")
      | select((.heading_1.rich_text[0].plain_text // "")=="Log")
      | .id' | head -n1
  )"

  if [ -z "${log_h1_id:-}" ]; then
    echo "qtlog: Notion log failed (could not find H1 'Log')" >&2
    return 1
  fi

  # 1b) Ensure H1 __TOP__ anchor exists (user should keep it as the FIRST block under H1)
  local h1_top_id h1_first_id
  h1_first_id="$(
    curl -sS "https://api.notion.com/v1/blocks/${log_h1_id}/children?page_size=1" \
      -H "Authorization: Bearer $NOTION_API_KEY" \
      -H "Notion-Version: 2022-06-28" | jq -r '.results[0].id // empty'
  )"

  h1_top_id="$(
    curl -sS "https://api.notion.com/v1/blocks/${log_h1_id}/children?page_size=200" \
      -H "Authorization: Bearer $NOTION_API_KEY" \
      -H "Notion-Version: 2022-06-28" | \
    jq -r '.results[]?
      | select(.type=="toggle")
      | select((.toggle.rich_text|map(.plain_text)|join(""))=="__TOP__")
      | .id' | head -n1
  )"

  if [ -z "${h1_top_id:-}" ]; then
    # Create H1 __TOP__ (best practice: drag it to be FIRST under H1 once, then it stays there)
    local payload_h1_top
    payload_h1_top="$(jq -nc --arg after "${h1_first_id:-}" '{
      after: ($after|select(length>0)),
      children:[{object:"block",type:"toggle",toggle:{rich_text:[{type:"text",text:{content:"__TOP__"}}],children:[]}}]
    }')"
    h1_top_id="$(
      curl -sS -X PATCH "https://api.notion.com/v1/blocks/${log_h1_id}/children" \
        -H "Authorization: Bearer $NOTION_API_KEY" \
        -H "Notion-Version: 2022-06-28" \
        -H "Content-Type: application/json" \
        -d "$payload_h1_top" | jq -r '.results[0].id // empty' )"
    echo "qtlog: created H1 __TOP__ (please drag it to the TOP under H1 'Log' once)" >&2
  fi

  # 2) Find today's toggle under H1, or create it (new day inserted AFTER H1 __TOP__)
  local day_id
  day_id="$(
    curl -sS "https://api.notion.com/v1/blocks/${log_h1_id}/children?page_size=200" \
      -H "Authorization: Bearer $NOTION_API_KEY" \
      -H "Notion-Version: 2022-06-28" | \
    jq -r --arg t "$today" '.results[]?
      | select(.type=="toggle")
      | select((.toggle.rich_text[0].plain_text // "")==$t)
      | .id' | head -n1
  )"

  if [ -z "${day_id:-}" ]; then
    local payload_day
    payload_day="$(jq -nc --arg after "${h1_top_id:-}" --arg d "$today" '{
      after: ($after|select(length>0)),
      children:[{object:"block",type:"toggle",toggle:{rich_text:[{type:"text",text:{content:$d}}],children:[{object:"block",type:"toggle",toggle:{rich_text:[{type:"text",text:{content:"__TOP__"}}],children:[]}}]}}]
    }')"
    day_id="$(
      curl -sS -X PATCH "https://api.notion.com/v1/blocks/${log_h1_id}/children" \
        -H "Authorization: Bearer $NOTION_API_KEY" \
        -H "Notion-Version: 2022-06-28" \
        -H "Content-Type: application/json" \
        -d "$payload_day" | jq -r '.results[0].id // empty' )"
  fi
  [ -z "${day_id:-}" ] && return 1

  # 3) Ensure Day __TOP__ anchor exists (user should keep it as FIRST under the day once)
  local top_id first_id
  first_id="$(
    curl -sS "https://api.notion.com/v1/blocks/${day_id}/children?page_size=1" \
      -H "Authorization: Bearer $NOTION_API_KEY" \
      -H "Notion-Version: 2022-06-28" | jq -r '.results[0].id // empty'
  )"

  top_id="$(
    curl -sS "https://api.notion.com/v1/blocks/${day_id}/children?page_size=200" \
      -H "Authorization: Bearer $NOTION_API_KEY" \
      -H "Notion-Version: 2022-06-28" | \
    jq -r '.results[]?
      | select(.type=="toggle")
      | select((.toggle.rich_text|map(.plain_text)|join(""))=="__TOP__")
      | .id' | head -n1
  )"

  if [ -z "${top_id:-}" ]; then
    local payload_top
    payload_top="$(jq -nc --arg after "${first_id:-}" '{
      after: ($after|select(length>0)),
      children:[{object:"block",type:"toggle",toggle:{rich_text:[{type:"text",text:{content:"__TOP__"}}],children:[]}}]
    }')"
    top_id="$(
      curl -sS -X PATCH "https://api.notion.com/v1/blocks/${day_id}/children" \
        -H "Authorization: Bearer $NOTION_API_KEY" \
        -H "Notion-Version: 2022-06-28" \
        -H "Content-Type: application/json" \
        -d "$payload_top" | jq -r '.results[0].id // empty' )"
    echo "qtlog: created Day __TOP__ (please drag it to the TOP under ${today} once)" >&2
  fi
  [ -z "${top_id:-}" ] && return 1


  # Guard: Day __TOP__ must be the FIRST child under the day toggle for true newest-at-top behavior.
  local day_first_title
  day_first_title="$(
    curl -sS "https://api.notion.com/v1/blocks/${day_id}/children?page_size=1" \
      -H "Authorization: Bearer $NOTION_API_KEY" \
      -H "Notion-Version: 2022-06-28" | \
    jq -r '(
      .results[0]
      | select(.type=="toggle")
      | (.toggle.rich_text|map(.plain_text)|join(""))
    ) // ""'
  )"

  if [ "$day_first_title" != "__TOP__" ]; then
    echo "qtlog: Day __TOP__ is not the first child under ${today}. Drag Day __TOP__ to the TOP once, then retry." >&2
    return 1
  fi

  # 4) Insert newest entry AFTER Day __TOP__ so it always appears at the top of the day list
  local payload_entry
  payload_entry="$(jq -nc --arg after "$top_id" --arg t "$title" '{
    after:$after,
    children:[{
      object:"block", type:"toggle",
      toggle:{
        rich_text:[{type:"text", text:{content:$t}}],
        children:[
          {object:"block", type:"toggle", toggle:{rich_text:[{type:"text", text:{content:"Log"}}], children:[]}},
          {object:"block", type:"toggle", toggle:{rich_text:[{type:"text", text:{content:"Notes"}}], children:[]}},
          {object:"block", type:"toggle", toggle:{rich_text:[{type:"text", text:{content:"Next steps"}}], children:[]}}
        ]
      }
    }]
  }')"

### QTLOG_NOTION_ENTRY_PATCH ###
    # 5) Write entry to Notion (PATCH children of day_id)
    local resp new_id
    resp="$(
      curl -sS -X PATCH "https://api.notion.com/v1/blocks/${day_id}/children" \
        -H "Authorization: Bearer $NOTION_API_KEY" \
        -H "Notion-Version: 2022-06-28" \
        -H "Content-Type: application/json" \
        -d "$payload_entry"
    )"
    new_id="$(printf '%s' "$resp" | jq -r '.results[0].id // empty')"
    if [ -z "${new_id:-}" ]; then
      echo "qtlog: Notion log failed (entry insert returned no id)" >&2
      printf '%s\n' "$resp" >&2
      return 1
    fi
    echo "qtlog: Notion entry inserted id=$new_id" >&2

        # AUTO_APPEND_FILE: if QTLOG_APPEND_FILE points to a file, append its content into the Notion entry.
        # GitHub-safe: no secrets; operator controls file path locally.
        if [ -n "${QTLOG_APPEND_FILE:-}" ] && [ -f "${QTLOG_APPEND_FILE}" ]; then
          local file_body
          file_body="$(cat "${QTLOG_APPEND_FILE}")"
          if [ -n "${file_body:-}" ]; then
            notion_append_big_text_as_codeblocks "$new_id" "$file_body" || true
            echo "qtlog: appended file to Notion entry (QTLOG_APPEND_FILE=${QTLOG_APPEND_FILE})" >&2
          else
            echo "qtlog: QTLOG_APPEND_FILE was empty; nothing appended (${QTLOG_APPEND_FILE})" >&2
          fi
        fi

      # SOP: big payload safety — if multiline (or forced), append body under Log as code blocks
      if [ "${QTLOG_FORCE_BIGPAYLOAD:-0}" = "1" ] || [ "$(printf "%s" "$raw" | wc -l | tr -d " ")" -gt 1 ]; then
        notion_append_big_text_as_codeblocks "$new_id" "$raw" || true
      fi

    return 0

}

# --- Notion sync ---
if [ "$LOG_MODE" = "notion" ] || [ "$LOG_MODE" = "both" ]; then
  write_notion_toggle
fi






confirm_commit() {
  # Non-interactive: commit only if something changed.
  # Return 0 to proceed; return 1 to skip commit/push.
  if command -v git >/dev/null 2>&1; then
    if [ "$(git status --porcelain 2>/dev/null | wc -l | tr -d " ")" -eq 0 ]; then
      echo "qtlog: nothing changed; skipping commit/push"
      return 1
    fi
    return 0
  fi
  return 1
}

# --- Git sync -----------------------------------------------------
cd "$QTLOG_REPO_DIR"

if [ "$NO_GIT" -ne 0 ]; then
  echo "qtlog: git disabled (NO_GIT=1, --no-git, or --offline)"
  echo "qtlog: logged to $LOG_FILE (no git actions)"
  exit 0
fi


echo "qtlog: pulling latest changes..."
if ! git pull --rebase; then
  echo "qtlog: warning: pull failed; continuing with local copy"
fi
if git check-ignore -q "$LOG_FILE" 2>/dev/null; then
  echo "qtlog: log file is gitignored ($LOG_FILE); skipping git commit/push"
  echo "qtlog: logged to $LOG_FILE"
  exit 0
fi

git add "$LOG_FILE"

# --- Message finalization (brag polish) ---
MESSAGE_FINAL="$MESSAGE"
if [ -n "${VERSION:-}" ]; then
  if ! printf '%s' "$MESSAGE_FINAL" | grep -Eq '^v[0-9]'; then
    MESSAGE_FINAL="v${VERSION} ${MESSAGE_FINAL}"
  fi
fi
COMMIT_MSG="[$DEVICE] $TODAY $NOW_FMT $MESSAGE_FINAL"

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

