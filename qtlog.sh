#!/usr/bin/env bash
set -euo pipefail

############################################
# Config / env loading
############################################

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="$SCRIPT_DIR/.qtlog_env"

if [[ -f "$ENV_FILE" ]]; then
  # shellcheck disable=SC1090
  source "$ENV_FILE"
else
  echo "qtlog: env file $ENV_FILE not found" >&2
  exit 1
fi

: "${NOTION_API_KEY:?NOTION_API_KEY is not set (check $ENV_FILE)}"
: "${PAGE_ID:?PAGE_ID is not set (check $ENV_FILE)}"
: "${LOG_BLOCK_ID:?LOG_BLOCK_ID is not set (check $ENV_FILE)}"

NOTION_API_BASE="https://api.notion.com/v1"
NOTION_VERSION="2022-06-28"

############################################
# Helpers
############################################

die() {
  echo "qtlog: $*" >&2
  exit 1
}

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || die "Required command '$1' not found. Please install it."
}

require_cmd curl
require_cmd jq

notion_get_children() {
  local block_id="$1"
  curl -sS \
    -H "Authorization: Bearer $NOTION_API_KEY" \
    -H "Notion-Version: $NOTION_VERSION" \
    -H "Content-Type: application/json" \
    "$NOTION_API_BASE/blocks/$block_id/children?page_size=100"
}

notion_append_children() {
  local block_id="$1"
  local json="$2"
  curl -sS \
    -X PATCH \
    -H "Authorization: Bearer $NOTION_API_KEY" \
    -H "Notion-Version: $NOTION_VERSION" \
    -H "Content-Type: application/json" \
    -d "$json" \
    "$NOTION_API_BASE/blocks/$block_id/children"
}

############################################
# Description selection
############################################

choose_description() {
  # Non-interactive: any arguments become the description.
  if [[ $# -gt 0 ]]; then
    printf '%s\n' "$*"
    return 0
  fi

  # Interactive menu
  echo "Choose entry type:"
  echo "  1) 💬 ChatGPT Chat"
  echo "  2) 🧭 WBS / IP Changes"
  echo "  3) ❄️ QuantumFusion.ca Update"
  echo "  4) 🌱 Misc"
  read -rp "Selection [1-4]: " choice

  case "$choice" in
    1) echo "ChatGPT Chat" ;;
    2) echo "WBS / IP Changes" ;;
    3) echo "QuantumFusion.ca Update" ;;
    4) echo "Misc" ;;
    *) die "Invalid selection '$choice'" ;;
  esac
}

############################################
# Main logic
############################################

main() {
  local description
  description="$(choose_description "$@")"

  local date_str time_str entry_title
  date_str="$(date +%F)"   # YYYY-MM-DD
  time_str="$(date +%H%M)" # HHMM
  entry_title="$date_str $time_str $description"

  # 1. Find or create the day toggle under the Log block
  local children_json day_block_id
  children_json="$(notion_get_children "$LOG_BLOCK_ID")"
  day_block_id="$(
    echo "$children_json" | jq -r --arg DATE "$date_str" '
      (if type=="array" then . else .results end // [])
      | map(
          select(.type=="toggle")
          | select(.toggle.rich_text[0].plain_text == $DATE)
        )
      | .[0].id // empty
    '
  )"

  if [[ -z "$day_block_id" ]]; then
    # Create the day toggle
    local new_day_json resp
    new_day_json="$(
      jq -n --arg DATE "$date_str" '
        {
          "children": [
            {
              "object": "block",
              "type": "toggle",
              "toggle": {
                "rich_text": [
                  {
                    "type": "text",
                    "text": { "content": $DATE }
                  }
                ]
              }
            }
          ]
        }
      '
    )"

    resp="$(notion_append_children "$LOG_BLOCK_ID" "$new_day_json")"
    day_block_id="$(
      echo "$resp" |
        jq -r '( .results // [] )
               | if (length>0 and .[0].id!=null)
                 then .[0].id
                 else empty end'
    )"

    [[ -z "$day_block_id" ]] && die "Failed to create day toggle for $date_str"
  fi

  # 2. Create the entry toggle under the day toggle
  local entry_json resp2 entry_block_id
  entry_json="$(
    jq -n --arg TITLE "$entry_title" '
      {
        "children": [
          {
            "object": "block",
            "type": "toggle",
            "toggle": {
              "rich_text": [
                {
                  "type": "text",
                  "text": { "content": $TITLE }
                }
              ]
            }
          }
        ]
      }
    '
  )"

  resp2="$(notion_append_children "$day_block_id" "$entry_json")"
  entry_block_id="$(
    echo "$resp2" |
      jq -r '( .results // [] )
             | if (length>0 and .[0].id!=null)
               then .[0].id
               else empty end'
  )"

  [[ -z "$entry_block_id" ]] && die "Failed to create entry toggle '$entry_title'"

  # 3. Add standard child toggles under the entry
  local child_json
  child_json="$(
    jq -n '
      {
        "children": [
          {
            "object": "block",
            "type": "toggle",
            "toggle": {
              "rich_text": [
                { "type": "text", "text": { "content": "Work done" } }
              ]
            }
          },
          {
            "object": "block",
            "type": "toggle",
            "toggle": {
              "rich_text": [
                { "type": "text", "text": { "content": "Notes / thoughts" } }
              ]
            }
          },
          {
            "object": "block",
            "type": "toggle",
            "toggle": {
              "rich_text": [
                { "type": "text", "text": { "content": "Next steps" } }
              ]
            }
          }
        ]
      }
    '
  )"

  notion_append_children "$entry_block_id" "$child_json" >/dev/null

  # 4. One-line confirmation
  echo "qtlog: created entry '$entry_title' under Log/$date_str"
}

main "$@"
