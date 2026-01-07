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
