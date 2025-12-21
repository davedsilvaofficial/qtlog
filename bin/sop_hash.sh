#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

cd "$(dirname "$0")/.." || exit 1
f="qtlog.sh"
[ -f "$f" ] || { echo "SOP_HASH_FAIL: missing $f" >&2; exit 1; }

need() { command -v "$1" >/dev/null 2>&1 || { echo "SOP_HASH_FAIL: missing $1" >&2; exit 1; }; }
need awk
need sha256sum

# Hash only the critical SOP-relevant regions so unrelated edits don't change the SOP hash.
# Markers must exist.
markers=(
  "### QTLOG_CONFIG_BLOCK ###"
  "### QTLOG_CODING_SOP ###"
  "### QTLOG_SOP_ENV_CHECK ###"
  "### QTLOG_SOP_FAIL_NOTION_LOG ###"
  "### QTLOG_SOP_ENV_CHECK_CALL ###"
  "### QTLOG_ENSURE_TODAY_TOP ###"
)

for m in "${markers[@]}"; do
  grep -F "$m" "$f" >/dev/null 2>&1 || { echo "SOP_HASH_FAIL: marker missing: $m" >&2; exit 1; }
done

extract_block() {
  local start="$1"
  awk -v start="$start" '
    BEGIN{p=0}
    $0 ~ start {p=1}
    p==1 {print}
    p==1 && $0 ~ /^\}\s*$/ {exit}
  ' "$f"
}

tmp="$(mktemp)"
{
  echo "FILE=$f"
  for m in "${markers[@]}"; do
    echo "=== $m ==="
    # For function blocks we stop at the closing brace; for comment blocks we’ll print next ~120 lines max.
    if echo "$m" | grep -q "ENSURE_TODAY_TOP\|SOP_ENV_CHECK\|SOP_FAIL_NOTION_LOG"; then
      extract_block "$m"
    elif echo "$m" | grep -q "SOP_ENV_CHECK_CALL"; then
      awk -v start="$m" '
        BEGIN{p=0}
        index($0,start)>0 {p=1}
        p==1 {print}
        p==1 && index($0,"sop_env_check")>0 && index($0,"exit 1")>0 {exit}
      ' "$f"
    else
      awk -v start="$m" '
        BEGIN{p=0; n=0}
        index($0,start)>0 {p=1}
        p==1 {print; n++}
        p==1 && n>=160 {exit}
      ' "$f"
    fi
  done
} > "$tmp"

sha256sum "$tmp" | awk '{print $1}'
rm -f "$tmp"
