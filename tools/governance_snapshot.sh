#!/usr/bin/env bash
set -euo pipefail

COMMIT=0
if [ "${1:-}" = "--commit" ]; then
  COMMIT=1
fi

# Timestamp in ET, filesystem-safe
TS_ET="$(TZ=America/New_York date '+%Y-%m-%d_%H%M_ET')"
TS_HUMAN="$(TZ=America/New_York date '+%Y-%m-%d %H%M ET')"

OUT_DIR="docs/Governance/Snapshots"
OUT_FILE="${OUT_DIR}/GOVERNANCE_UNBROKEN_CHAIN_${TS_ET}.md"
INDEX_FILE="${OUT_DIR}/README.md"

mkdir -p "$OUT_DIR"

VERIFY_CMD="tools/governance_verify.sh && gh api repos/davedsilvaofficial/qtlog/branches/main/protection --jq '{enforce_admins:.enforce_admins.enabled,linear_history:.required_linear_history.enabled,force_pushes:.allow_force_pushes.enabled,deletions:.allow_deletions.enabled,required_checks:(.required_status_checks.contexts//[]),required_reviews:(.required_pull_request_reviews.required_approving_review_count//null)}'"

# Collect outputs (do not fail the snapshot if governance_verify prints warnings)
VERIFY_OUT="$( (tools/governance_verify.sh || true) 2>&1 )"

PROT_OUT="$(gh api repos/davedsilvaofficial/qtlog/branches/main/protection --jq '{enforce_admins:.enforce_admins.enabled,linear_history:.required_linear_history.enabled,force_pushes:.allow_force_pushes.enabled,deletions:.allow_deletions.enabled,required_checks:(.required_status_checks.contexts//[]),required_reviews:(.required_pull_request_reviews.required_approving_review_count//null)}' 2>&1 || true)"

EWF_PATH=".github/workflows/emergency-auto-approve.yml"
if [ -f "$EWF_PATH" ]; then
  EWF_TEXT="$(cat "$EWF_PATH")"
else
  EWF_TEXT="MISSING: $EWF_PATH"
fi

BRIDGE_PATH=".github/workflows/verify-status-bridge.yml"
if [ -f "$BRIDGE_PATH" ]; then
  BRIDGE_TEXT="$(cat "$BRIDGE_PATH")"
else
  BRIDGE_TEXT="MISSING: $BRIDGE_PATH"
fi

cat > "$OUT_FILE" <<MD
# Governance — Unbroken Chain Snapshot

**Timestamp:** ${TS_HUMAN}

This document is a timestamped snapshot of governance state and continuity mechanisms.

---

## One-command governance verification (canonical)

\`\`\`bash
${VERIFY_CMD}
\`\`\`

### tools/governance_verify.sh output

\`\`\`text
${VERIFY_OUT}
\`\`\`

### Branch protection (main)

\`\`\`json
${PROT_OUT}
\`\`\`

---

## Emergency auto-approve workflow (verbatim)

\`\`\`yaml
${EWF_TEXT}
\`\`\`

---

## Verify status bridge workflow (verbatim)

\`\`\`yaml
${BRIDGE_TEXT}
\`\`\`

---

## Invariants (DO NOT BREAK)

- Branch protection always ON (including enforce_admins)
- Linear history required (no merge commits)
- Required status context must match CI’s actual context string (currently: \`verify\`)
- Required approvals = 1 (satisfied only via emergency bot token; NOT \`github.token\` approvals)
- Emergency actions must be explicit + auditable (EMERGENCY-MODE marker + same-repo + allowed branch prefix)
MD

# Update index (newest first)
if [ ! -f "$INDEX_FILE" ]; then
  cat > "$INDEX_FILE" <<'MD'
# Governance Snapshots (Timestamped History)

Newest first. Each snapshot captures:
- one-command governance verification output
- branch protection state
- emergency workflow(s) verbatim

---
MD
fi

REL_PATH="./$(basename "$OUT_FILE")"
TITLE="GOVERNANCE_UNBROKEN_CHAIN_${TS_ET}.md"

# Prepend entry if not already present
if ! grep -qF "$TITLE" "$INDEX_FILE"; then
  TMP="$(mktemp)"
  {
    echo "# Governance Snapshots (Timestamped History)"
    echo
    echo "Newest first. Each snapshot captures:"
    echo "- one-command governance verification output"
    echo "- branch protection state"
    echo "- emergency workflow(s) verbatim"
    echo
    echo "---"
    echo
    echo "- [${TITLE}](${REL_PATH}) — ${TS_HUMAN}"
    echo
    # Keep previous content minus the header block we just rewrote
    awk 'NR==1{next} NR==2{next} NR==3{next} NR==4{next} NR==5{next} NR==6{next} NR==7{next} {print}' "$INDEX_FILE"
  } > "$TMP"
  mv "$TMP" "$INDEX_FILE"
fi

echo "WROTE: $OUT_FILE"
echo "INDEX: $INDEX_FILE"

if [ "$COMMIT" -eq 1 ]; then
  git add "$OUT_FILE" "$INDEX_FILE"
  git commit -m "Governance: snapshot unbroken chain (${TS_ET})"
  git push
  echo "COMMITTED+PUSHED: ${TITLE}"
else
  echo
  echo "⚠️  Reminder: snapshot is not committed."
  echo "    To persist: tools/governance_snapshot.sh --commit"
fi
