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
