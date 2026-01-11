# Auditor Readiness — One-Page Summary (GitHub Governance)

## Purpose
This repository implements IPO/audit-oriented controls for change management, evidence capture, and traceability. The goal is to ensure:
- controlled changes to protected branches,
- repeatable CI verification,
- documented governance approvals,
- durable evidence artifacts stored in-repo.

## Authoritative Navigation
- **MASTER_INDEX.md** (authoritative index)
- docs/INDEX.md (docs-level index)
- docs/DOCUMENTATION_ARCHITECTURE.md (structure & rules)
- NEW_DEVELOPER.md (Day 1–Day 3 onboarding)

## Key Controls Implemented
1) **Protected default branch (`main`)**
- Direct pushes blocked (PR-only changes)
- Required checks enforced: `publish-guard`, `sop`, `verify`
- 1 approving review required
- Conversation resolution required
- Linear history required
- Force pushes & deletions disabled

2) **Governance service account**
- `quantumtrek-governance` configured with 2FA + offline recovery codes
- Used for governance approvals and evidence integrity

3) **Evidence records**
Evidence is captured under:
- `docs/Data_Room/02_Compliance/`

## Evidence Artifacts (Core)
- `GITHUB_GOVERNANCE_ACCOUNT_SETUP.md`
- `GITHUB_BRANCH_PROTECTION_EVIDENCE.md`
- `GITHUB_BRANCH_PROTECTION_TEST_PR_EVIDENCE.md`

## How to Verify in GitHub UI
- Branch rules: Repo → Settings → Branches
- Access: Repo → Settings → Access / Collaborators
- CI checks: PR → Checks

## Expected Outcome
Any change to `main` requires:
- a pull request,
- required checks passing,
- at least one approval,
- and resolved conversations.

