# Governance — What Is Formally True (State of Record)

**Timestamp (ET):** 2026-01-11 1255 ET  
**Repository:** davedsilvaofficial/qtlog  
**Protected branch:** main  
**Baseline tag:** baseline/v1  
**Baseline ID anchor:** QTLOG-GOV-2026-01-11-09b6040-PR5

## What is formally enforced (current branch protection)
- ✅ PR-only changes to `main` (direct pushes blocked)
- ✅ Required status checks (strict): `publish-guard`, `sop`, `verify`
- ✅ Required approving reviews: **1**
- ✅ Require review from Code Owners: **true**
- ✅ Dismiss stale reviews: **true**
- ✅ Require conversation resolution: **true**
- ✅ Linear history required: **true**
- ✅ Enforce admins: **true**
- ✅ Force pushes: **disabled**
- ✅ Deletions: **disabled**

## Audit-grade characteristics proven in practice
- ✅ Protected branch enforcement via PR workflow
- ✅ Approval invalidation on history rewrite (rebase/force-push changes merge-base)
- ✅ Re-approval after rebase
- ✅ Governance service account oversight (`quantumtrek-governance`)
- ✅ Baseline artifacts committed and tied to PRs + merge commits (see GOVERNANCE_EPOCHS.md)

## Offline evidence capture (for auditors / counsel)
Saved from GitHub API at time of writing:
- `docs/Data_Room/02_Compliance/_offline/branch_protection_2026-01-11_1255_ET.json`
- `docs/Data_Room/02_Compliance/_offline/branch_protection_2026-01-11_1255_ET.pretty.json`

## Where to verify in GitHub UI
- Repo → Settings → Branches (main branch protection rules)
- Repo → Settings → Collaborators
- PRs → Checks / Reviews
