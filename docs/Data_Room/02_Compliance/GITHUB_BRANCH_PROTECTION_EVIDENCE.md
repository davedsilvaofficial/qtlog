# GitHub Branch Protection — Evidence Record

**Timestamp:** 2026-01-11 0942 ET  
**Repository:** davedsilvaofficial/qtlog  
**Branch:** main  
**Governance account:** quantumtrek-governance  
**Governance permission:** admin  

## Protection Summary (Expected)
- Required status checks (strict): **true**
  - verify
  - publish-guard
  - sop
- Enforce admins: **true**
- PR reviews required: **1**
- Dismiss stale reviews: **true**
- Require linear history: **true**
- Force pushes allowed: **false**
- Deletions allowed: **false**
- Require conversation resolution: **true**

## Raw API Evidence (Branch Protection JSON)
```json
{"url":"https://api.github.com/repos/davedsilvaofficial/qtlog/branches/main/protection","required_status_checks":{"url":"https://api.github.com/repos/davedsilvaofficial/qtlog/branches/main/protection/required_status_checks","strict":true,"contexts":["verify","publish-guard","sop"],"contexts_url":"https://api.github.com/repos/davedsilvaofficial/qtlog/branches/main/protection/required_status_checks/contexts","checks":[{"context":"verify","app_id":15368},{"context":"publish-guard","app_id":15368},{"context":"sop","app_id":15368}]},"required_pull_request_reviews":{"url":"https://api.github.com/repos/davedsilvaofficial/qtlog/branches/main/protection/required_pull_request_reviews","dismiss_stale_reviews":true,"require_code_owner_reviews":false,"require_last_push_approval":false,"required_approving_review_count":1},"required_signatures":{"url":"https://api.github.com/repos/davedsilvaofficial/qtlog/branches/main/protection/required_signatures","enabled":false},"enforce_admins":{"url":"https://api.github.com/repos/davedsilvaofficial/qtlog/branches/main/protection/enforce_admins","enabled":true},"required_linear_history":{"enabled":true},"allow_force_pushes":{"enabled":false},"allow_deletions":{"enabled":false},"block_creations":{"enabled":false},"required_conversation_resolution":{"enabled":true},"lock_branch":{"enabled":false},"allow_fork_syncing":{"enabled":false}}
```

## Where to Verify in GitHub UI
- Branch rules:  
  https://github.com/davedsilvaofficial/qtlog/settings/branches
- Access / collaborators:  
  https://github.com/davedsilvaofficial/qtlog/settings/access

