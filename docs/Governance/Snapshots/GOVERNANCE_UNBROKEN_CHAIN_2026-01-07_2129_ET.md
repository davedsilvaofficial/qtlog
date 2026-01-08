# Governance — Unbroken Chain Snapshot

**Timestamp:** 2026-01-07 2129 ET

This document is a timestamped snapshot of governance state and continuity mechanisms.

---

## One-command governance verification (canonical)

```bash
tools/governance_verify.sh && gh api repos/davedsilvaofficial/qtlog/branches/main/protection --jq '{enforce_admins:.enforce_admins.enabled,linear_history:.required_linear_history.enabled,force_pushes:.allow_force_pushes.enabled,deletions:.allow_deletions.enabled,required_checks:(.required_status_checks.contexts//[]),required_reviews:(.required_pull_request_reviews.required_approving_review_count//null)}'
```

### tools/governance_verify.sh output

```text
[governance-verify] Running one-command governance verification...
::warning title=Emergency Governance Preflight::PyYAML not available; cannot validate emergency workflow structure.
[governance-verify] OK
```

### Branch protection (main)

```json
{"deletions":false,"enforce_admins":true,"force_pushes":false,"linear_history":true,"required_checks":["verify"],"required_reviews":1}
```

---

## Emergency auto-approve workflow (verbatim)

```yaml
name: Emergency Auto-Approve (Solo-Founder)

on:
  pull_request:
    types: [opened, synchronize, reopened, ready_for_review]

permissions:
  contents: read
  pull-requests: write
  statuses: read

jobs:
  approve:
    runs-on: ubuntu-latest
    steps:
      - name: Guard: require bot token secret (skip cleanly if missing)
        id: guard
        env:
          QT_TOKEN: ${{ secrets.QT_EMERGENCY_REVIEW_TOKEN }}
        run: |
          if [ -z "${QT_TOKEN:-}" ]; then
            echo "QT_EMERGENCY_REVIEW_TOKEN is not set; skipping auto-approve."
            echo "has_token=false" >> "$GITHUB_OUTPUT"
            exit 0
          fi
          echo "has_token=true" >> "$GITHUB_OUTPUT"

      - name: Read PR metadata
        if: steps.guard.outputs.has_token == 'true'
        env:
          GH_TOKEN: ${{ secrets.QT_EMERGENCY_REVIEW_TOKEN }}
        run: |
          pr="${{ github.event.pull_request.number }}"
          gh api "repos/${{ github.repository }}/pulls/${pr}" --jq '{
            number:.number,
            title:.title,
            body:(.body // ""),
            headRepo:.head.repo.full_name,
            baseRepo:.base.repo.full_name,
            headRef:.head.ref,
            headSha:.head.sha
          }' > pr.json
          cat pr.json

      - name: Gate 1 (explicit + same-repo + branch prefix)
        id: gate1
        if: steps.guard.outputs.has_token == 'true'
        env:
          GH_TOKEN: ${{ secrets.QT_EMERGENCY_REVIEW_TOKEN }}
        run: |
          headRepo="$(jq -r .headRepo pr.json)"
          baseRepo="$(jq -r .baseRepo pr.json)"
          body="$(jq -r .body pr.json)"
          title="$(jq -r .title pr.json)"
          headRef="$(jq -r .headRef pr.json)"

          allowed="true"

          if [ "$headRepo" != "$baseRepo" ]; then
            echo "Not same-repo PR; refusing auto-approve."
            allowed="false"
          fi

          echo "$title $body" | grep -q "EMERGENCY-MODE:" || { echo "Missing EMERGENCY-MODE: marker; refusing."; allowed="false"; }
          echo "$headRef" | grep -Eq '^(emergency/|governance-|hotfix/)' || { echo "Head ref '$headRef' not allowed; refusing."; allowed="false"; }

          echo "allowed=$allowed" >> "$GITHUB_OUTPUT"
          echo "Gate1 allowed=$allowed"

      - name: Gate 2 (required status context must be SUCCESS)
        id: gate2
        if: steps.guard.outputs.has_token == 'true' && steps.gate1.outputs.allowed == 'true'
        env:
          GH_TOKEN: ${{ secrets.QT_EMERGENCY_REVIEW_TOKEN }}
        run: |
          sha="$(jq -r .headSha pr.json)"

          # Accept either "verify" or "qtlog verify" as SUCCESS.
          state_verify="$(gh api "repos/${{ github.repository }}/commits/${sha}/status" --jq '
            (.statuses // [])
            | map(select(.context=="verify" or .context=="qtlog verify"))
            | .[0].state // empty
          ')"

          if [ -z "$state_verify" ]; then
            echo "Neither status context 'verify' nor 'qtlog verify' found on SHA ${sha}; refusing auto-approve."
            echo "ok=false" >> "$GITHUB_OUTPUT"
            exit 0
          fi

          if [ "$state_verify" != "success" ]; then
            echo "Required status context is not success (got: $state_verify); refusing auto-approve."
            echo "ok=false" >> "$GITHUB_OUTPUT"
            exit 0
          fi

          echo "Required status context is success."
          echo "ok=true" >> "$GITHUB_OUTPUT"

      - name: Approve PR (bot review)
        if: steps.guard.outputs.has_token == 'true' && steps.gate1.outputs.allowed == 'true' && steps.gate2.outputs.ok == 'true'
        env:
          GH_TOKEN: ${{ secrets.QT_EMERGENCY_REVIEW_TOKEN }}
        run: |
          pr="$(jq -r .number pr.json)"
          gh api -X POST "repos/${{ github.repository }}/pulls/${pr}/reviews"             -f event=APPROVE             -f body="Auto-approval: Emergency Mode criteria satisfied (EMERGENCY-MODE: present + required status context green + same-repo + allowed branch)."
```

---

## Verify status bridge workflow (verbatim)

```yaml
name: Verify Status Bridge (legacy context)

on:
  workflow_run:
    workflows: ["qtlog verify", "Compliance"]
    types: [completed]

permissions:
  statuses: write
  contents: read

jobs:
  set-status:
    if: github.event.workflow_run.event == 'pull_request'
    runs-on: ubuntu-latest
    steps:
      - name: Set legacy status context "verify" on head SHA
        env:
          GH_TOKEN: ${{ github.token }}
        run: |
          set -euo pipefail
          sha="${{ github.event.workflow_run.head_sha }}"
          concl="${{ github.event.workflow_run.conclusion }}"
          repo="${{ github.repository }}"

          # Map workflow_run conclusion -> commit status state
          state="failure"
          if [ "$concl" = "success" ]; then state="success"; fi
          if [ "$concl" = "neutral" ] || [ "$concl" = "skipped" ]; then state="success"; fi

          desc="Bridged from workflow_run (${concl})"
          target="${{ github.event.workflow_run.html_url }}"

          gh api -X POST "repos/${repo}/statuses/${sha}" \
            -f state="$state" \
            -f context="verify" \
            -f description="$desc" \
            -f target_url="$target"

          echo "Set status context verify=$state on $sha"
```

---

## Invariants (DO NOT BREAK)

- Branch protection always ON (including enforce_admins)
- Linear history required (no merge commits)
- Required status context must match CI’s actual context string (currently: `verify`)
- Required approvals = 1 (satisfied only via emergency bot token; NOT `github.token` approvals)
- Emergency actions must be explicit + auditable (EMERGENCY-MODE marker + same-repo + allowed branch prefix)
