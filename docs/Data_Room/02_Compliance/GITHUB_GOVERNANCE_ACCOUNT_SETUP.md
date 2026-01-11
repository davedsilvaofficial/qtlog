# GitHub Governance Account Setup — Evidence Record

**Timestamp:** 2026-01-11 0920 ET  
**Repository:** davedsilvaofficial/qtlog  
**Default branch:** main  
**Visibility:** Public

## Governance Account
- **Username:** quantumtrek-governance
- **Verified permission on repo:** read

## Required Checks Observed on main (HEAD: 19d7bc4b2d3cbd8bb6cbf47328d6a4968c877aea)
- publish-guard,sop,verify

## Controls Implemented (Current State)
- Governance service account exists and is configured with 2FA + recovery codes (stored offline).
- Governance service account has repo-level permission consistent with break-glass / admin governance.

## Next Controls (Pending)
- Apply branch protection on `main` with required status checks:
  - publish-guard
  - sop
  - verify
- Disable force-push and branch deletion (recommended).
- Document branch protection JSON and screenshots (optional) for auditors.

## Where to Verify in GitHub UI
1) Repo → **Settings** → **Collaborators** (or **Manage access**) → confirm quantumtrek-governance role  
2) Repo → **Settings** → **Branches** → Branch protection rules for `main`  
3) Repo → **Actions** → confirm required checks are running and passing

