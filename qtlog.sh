# ENV FILE (authoritative): ~/.config/qt/.env
# Contains: NOTION_API_KEY, NOTION_LOG_PAGE_ID, NOTION_TODO_PAGE_ID

usage() {

  cat <<'EOF'

qtlog.sh — Quantum Trek Logging Utility



Usage:

  qtlog.sh [options] <message>



Options:

  --help            Show this help

  --log             Log message (default)

    local            Filesystem only

    notion           Notion only

    both             Filesystem + Notion

  --todo <item>     Write item to Notion ToDo

  --dry-run         Preview without side effects

  --reconcile       Audit / reconciliation mode

  --verify          Verify Notion newest-at-top anchors (read-only), prints VERIFY_TIME (ET) and exit

  --offline         Disable git operations



Execution hierarchy is documented in code and CHANGELOG.

EOF

}


#!/usr/bin/env bash
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
VERSION="1.2.4"
set -euo pipefail

# --- DEVICE GUARD (nounset-safe; required by SOP) ---
: "${DEVICE:=$(getprop ro.product.model 2>/dev/null || true)}"
[ -n "$DEVICE" ] || DEVICE="Device"
# --- END DEVICE GUARD ---

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
    --verify        Verify Notion newest-at-top anchors (read-only) and exit

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
LKG_MODE=0
VERIFY_ONLY=0


ARGS=()
TODO_MODE=0
TODO_ITEM=""

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
      STAMP_NOW=1
      shift
      ;;
    --reconcile)
      RECONCILE=1
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

    --lkg)
      LKG_MODE=1
      shift
      ;;
    --notion)
      LOG_MODE=notion
      shift
      ;;
    --local)
      LOG_MODE=local
      shift
      ;;
    --git)
      LOG_MODE=git
      shift
      ;;
    --both)
      LOG_MODE=both
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

  # Helper: ensure a pinned sentinel exists so we can always insert newest "at top" (after it).
  ensure_pin() {
    # $1 = parent_block_id, $2 = pin_title
    local PARENT="$1"
    local PIN_TITLE="$2"

    local DATA
    DATA="$(curl -sS \
      -H "Authorization: Bearer ${NOTION_API_KEY}" \
      -H "Notion-Version: 2022-06-28" \
      "https://api.notion.com/v1/blocks/${PARENT}/children?page_size=50")"

    local PIN_ID
    PIN_ID="$(printf '%s' "$DATA" | jq -r --arg t "$PIN_TITLE" '
      [.results[] | select(.type=="toggle") | select((.toggle.rich_text[0].plain_text // "")==$t)][0].id // ""')"

    if [ -n "$PIN_ID" ]; then
      echo "$PIN_ID"
      return 0
    fi

    # Create pin sentinel
    local JSON RESP NEWID
    JSON="$(cat <<EOF
{"children":[{"object":"block","type":"toggle","toggle":{"rich_text":[{"type":"text","text":{"content":"$PIN_TITLE"}}],"children":[]}}]}
EOF
)"
    RESP="$(curl -sS -w '\nHTTP_CODE=%{http_code}\n' \
      -X PATCH "https://api.notion.com/v1/blocks/${PARENT}/children" \
      -H "Authorization: Bearer ${NOTION_API_KEY}" \
      -H "Notion-Version: 2022-06-28" \
      -H "Content-Type: application/json" \
      --data "$JSON")"
    local HTTP_CODE
    HTTP_CODE="$(printf '%s' "$RESP" | sed -n 's/^HTTP_CODE=//p' | tail -n 1)"
    if [ -z "$HTTP_CODE" ] || [ "$HTTP_CODE" -lt 200 ] || [ "$HTTP_CODE" -ge 300 ]; then
      echo "qtlog: PIN create failed (HTTP $HTTP_CODE)" >&2
      printf '%s\n' "$RESP" >&2
      exit 1
    fi
    NEWID="$(printf '%s' "$RESP" | sed '/^HTTP_CODE=/d' | jq -r '.results[0].id // ""')"
    echo "$NEWID"
  }

  # Ensure DATE toggle exists under ToDo heading. Insert "near top" by using a pin sentinel.
  TODO_PIN_ID="$(ensure_pin "$TODO_PARENT_ID" "📌 PIN")"

  DATE_ID="$(curl -sS \
    -H "Authorization: Bearer ${NOTION_API_KEY}" \
    -H "Notion-Version: 2022-06-28" \
    "https://api.notion.com/v1/blocks/${TODO_PARENT_ID}/children?page_size=100" \
    | jq -r --arg d "$DATE_ONLY" '
      [.results[] | select(.type=="toggle") | select((.toggle.rich_text[0].plain_text // "")==$d)][0].id // ""'
  )"

  if [ -z "$DATE_ID" ]; then
    # Create date toggle after PIN (so it sits at the top section)
    JSON="$(cat <<EOF
{"after":"$TODO_PIN_ID","children":[{"object":"block","type":"toggle","toggle":{"rich_text":[{"type":"text","text":{"content":"$DATE_ONLY"}}],"children":[]}}]}
EOF
)"
    RESP="$(curl -sS -w '\nHTTP_CODE=%{http_code}\n' \
      -X PATCH "https://api.notion.com/v1/blocks/${TODO_PARENT_ID}/children" \
      -H "Authorization: Bearer ${NOTION_API_KEY}" \
      -H "Notion-Version: 2022-06-28" \
      -H "Content-Type: application/json" \
      --data "$JSON")"
    HTTP_CODE="$(printf '%s' "$RESP" | sed -n 's/^HTTP_CODE=//p' | tail -n 1)"
    if [ -z "$HTTP_CODE" ] || [ "$HTTP_CODE" -lt 200 ] || [ "$HTTP_CODE" -ge 300 ]; then
      echo "qtlog: DATE create failed (HTTP $HTTP_CODE)" >&2
      printf '%s\n' "$RESP" >&2
      exit 1
    fi
    DATE_ID="$(printf '%s' "$RESP" | sed '/^HTTP_CODE=/d' | jq -r '.results[0].id // ""')"
  fi
  echo "qtlog: Using date toggle id: $DATE_ID ($DATE_ONLY)" >&2

  # Ensure a pin exists inside the DATE toggle too, so newest CEI goes to top (after that pin).
  DATE_PIN_ID="$(ensure_pin "$DATE_ID" "📌 TOP")"

  # Create CEI entry (toggle with 3 toggle children) after DATE pin so it appears at the top
  URL="https://api.notion.com/v1/blocks/${DATE_ID}/children"
  JSON="$(cat <<EOF
{
  "after": "$DATE_PIN_ID",
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

# --- VERIFY DISPATCH (early exit, read-only) ---
if [ "${VERIFY_ONLY:-0}" -eq 1 ]; then
  verify_log_structure
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
write_notion_toggle() {
  [ -z "${NOTION_API_KEY:-}" ] && return 0
  [ -z "${NOTION_LOG_PAGE_ID:-}" ] && return 0

  local raw="${ENTRY:-$MESSAGE}"

  # SOP: entry title must be "YYYY-MM-DD HHMM ET — description"
  local ts_min desc title
  ts_min="$(TZ=America/Toronto date '+%Y-%m-%d %H%M')"

  # Strip trailing timestamps like " — 2025-12-18 221141" or " — 2025-12-18 2211"
  desc="$(printf "%s" "$raw" | sed -E 's/[[:space:]]+—[[:space:]]+[0-9]{4}-[0-9]{2}-[0-9]{2}[[:space:]]+[0-9]{4,6}$//')"
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
      children:[{object:"block",type:"toggle",toggle:{rich_text:[{type:"text",text:{content:$d}}],children:[]}}]
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

}

# --- Notion sync ---
if [ "$LOG_MODE" = "notion" ] || [ "$LOG_MODE" = "both" ]; then
  write_notion_toggle
fi





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
