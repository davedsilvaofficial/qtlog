# Governance Emergency Mode (Solo-Founder)

## Purpose
This repository supports a solo-founder emergency governance mode to allow
critical merges when human reviewers are unavailable, without disabling
compliance automation or CI enforcement.

This mode is **explicit, temporary, and auditable**.

---

## When This Mode May Be Used
Emergency mode MAY be used only when **all** conditions apply:

- Repository has a single active maintainer
- No other collaborators with write access are available
- Change is required to:
  - restore CI / compliance
  - establish a governance baseline
  - respond to an operational or legal incident

---

## Controls That REMAIN Enforced
Even in Emergency Mode, the following are mandatory:

- `Compliance / verify` GitHub status check
- SOP hash verification
- CI workflows must pass
- Linear git history
- No force-pushes
- No branch deletions

---

## Controls Temporarily Relaxed
- Required approving pull-request reviews

No other protections may be disabled.

---

## Activation Procedure (Explicit)
1. Document the reason in commit message or PR description (include: `EMERGENCY-MODE:`)
2. Temporarily disable required PR reviews (NOT status checks)
3. Merge via PR (no direct pushes)
4. Immediately restore normal governance mode

---

## Auditability
- All actions are logged via GitHub audit logs
- CI artifacts and hashes remain immutable
- Emergency usage is visible in git history

---

## Prohibited Actions
- Disabling `Compliance / verify`
- Direct pushes to `main`
- Force-pushes
- Silent merges

**Violation invalidates governance integrity.**

---

## CODEOWNERS-Free Solo-Founder Safeguard (Never Remove Branch Protection)
To avoid ever disabling branch protection again, qtlog uses an emergency auto-approver bot:

- Branch protection stays ON (including **enforce admins**).
- `Compliance / verify` remains required.
- Required approving reviews remain set to **1**.
- A bot can provide that 1 approval **only** when:
  - the PR title/body includes `EMERGENCY-MODE:`
  - the PR is **same-repo** (not a fork)
  - the PR branch matches: `emergency/`, `hotfix/`, or `governance-`
  - the `Compliance` workflow completes successfully

### Setup
1. Create a fine-grained PAT (classic PAT also works) for a *bot identity* with permission to approve PRs on this repo.
2. Add it as repo secret: `QT_EMERGENCY_REVIEW_TOKEN`.
3. The workflow `.github/workflows/emergency-auto-approve.yml` will then approve eligible PRs after `Compliance` succeeds.

This is explicit, temporary, and auditable — and keeps branch protection intact.

---

## Critical Implementation Note (Do Not Forget)

### Why Emergency Auto-Approve Is Required
GitHub enforces the following hard rules, even for solo founders and admins:

1. **A pull request author can never approve their own PR**
   - This applies even with admin privileges
   - `gh pr review --approve` will always fail for the author

2. **If branch protection requires ≥1 approving review**
   - And `enforce_admins` is enabled
   - And no other human collaborators exist  
   → The PR becomes unmergeable **forever** without a second identity

3. **Disabling branch protection to bypass this is a governance violation**
   - Breaks audit continuity
   - Invalidates compliance claims
   - Creates silent integrity gaps

### Resolution (Canonical)
The **Emergency Auto-Approve bot** exists to satisfy the single required approval
*without ever removing branch protection*.

- The bot is a separate identity
- It approves only after `Compliance / verify` succeeds
- It requires an explicit `EMERGENCY-MODE:` declaration
- All actions remain logged and auditable

**If you hit a “merge blocked but all checks are green” situation again:**
→ Verify the emergency auto-approve workflow is present and valid  
→ Verify `QT_EMERGENCY_REVIEW_TOKEN` secret exists  
→ Do **not** remove branch protection

---

## FAQ (Solo-Founder Emergency Governance)

### Q: Why do we need Emergency Auto-Approve at all?
Because GitHub enforces a hard rule: **a PR author cannot approve their own PR**, even as an admin.  
If branch protection requires **≥1 approving review** and you are the only collaborator, merges become **permanently blocked** unless a second identity can approve.

### Q: Isn’t disabling branch protection “fine” in an emergency?
No. In this repo’s governance model, **disabling protections is a governance integrity break** because it creates an unverifiable gap in controls and audit continuity.  
Emergency governance is explicitly designed to avoid that.

### Q: What does the Emergency Auto-Approve bot actually do?
It provides the **single required approval** *only* when all gating criteria are satisfied:
- `Compliance / verify` succeeded
- PR is **same-repo** (not a fork)
- PR explicitly declares `EMERGENCY-MODE:`
- PR branch name matches an allowed prefix (e.g., `emergency/`, `hotfix/`, `governance-`)

### Q: What does “CODEOWNERS-free” mean here?
It means the safeguard does **not** rely on CODEOWNERS review routing.  
Instead, it uses a dedicated bot identity + explicit gating rules to satisfy the review requirement without relaxing protections.

### Q: What if the emergency workflow is missing or broken?
Compliance includes a **warn-only preflight check** (`tools/check_emergency_workflow.py`) that emits a GitHub Actions warning if:
- `.github/workflows/emergency-auto-approve.yml` is missing
- the YAML is malformed
- required gates/tokens are not referenced

This prevents silent regressions.

### Q: Does the bot bypass `Compliance / verify`?
No. The bot triggers only after the **Compliance workflow_run concludes successfully**.  
If `Compliance / verify` is red, the bot will not approve.

### Q: What secret is required?
`QT_EMERGENCY_REVIEW_TOKEN` (a token belonging to a **separate bot identity**) with permission to create PR reviews on this repository.

### Q: What is the “Emergency Governance Enabled” badge?
A transparency marker: this repo contains an explicit, auditable emergency pathway for solo-founder continuity that preserves required CI/compliance controls.

### Q: When should I use Emergency Mode?
Only when **all** “When This Mode May Be Used” conditions apply, and you explicitly declare `EMERGENCY-MODE:` in the PR title/body to make the action auditable.


---

## KEEP THIS (Do Not Forget): Required Status Check Context Must Match Reality

### Symptom
- PR shows all checks green, but merge says: **Required status check "<name>" is expected**.
- Branch protection is requiring a **different** context name than what CI actually reports.

### Canonical Fix
1) Inspect current branch protection:
- `gh api repos/davedsilvaofficial/qtlog/branches/main/protection --jq '{required_checks:(.required_status_checks.contexts // []), required_reviews:(.required_pull_request_reviews.required_approving_review_count // null), enforce_admins:.enforce_admins.enabled}'`

2) Set the required status check context to the *actual* check name produced by CI.
For qtlog, the canonical required check is currently: `verify`

- `gh api -X PATCH repos/davedsilvaofficial/qtlog/branches/main/protection/required_status_checks -H "Accept: application/vnd.github+json" -f strict:=true -f "contexts[]=verify"`

### Why this matters
If the required context name is wrong (e.g., `Compliance / verify` when CI only reports `verify`), merges will remain blocked even though CI is green.

