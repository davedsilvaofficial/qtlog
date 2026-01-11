# GitHub CODEOWNERS Enforcement — Evidence Record

**Timestamp (ET):** 2026-01-11 1246 ET  
**Repo:** davedsilvaofficial/qtlog  
**Control:** require_code_owner_reviews = true

## What changed / why it matters
CODEOWNERS review requirements are now enforced for governance-critical paths, strengthening separation of duties and auditability.

## Raw API Evidence (required_pull_request_reviews)
```json
{"url":"https://api.github.com/repos/davedsilvaofficial/qtlog/branches/main/protection/required_pull_request_reviews","dismiss_stale_reviews":true,"require_code_owner_reviews":true,"require_last_push_approval":false,"required_approving_review_count":1}
```

## Where to verify in GitHub UI
Repo → Settings → Branches → Branch protection rules → “Require review from Code Owners”
