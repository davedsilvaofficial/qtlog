# GitHub Branch Protection — Test PR Evidence

**Timestamp:** 2026-01-11 0946 ET  
**Repository:** davedsilvaofficial/qtlog  
**PR:** https://github.com/davedsilvaofficial/qtlog/pull/3  
**Head SHA:** d2ddede76fa14cf70a101918c73ca8839d70a92b  
**Observed merge state:** mergeable=MERGEABLE mergeStateStatus=BLOCKED  

## Expected Required Checks
- publish-guard
- sop
- verify

## Observed Check Runs (name | status | conclusion)
```
build-board-slide | completed | success
publish-guard | completed | success
sop | completed | success
verify | completed | success
```

## Interpretation
- If required checks are present and not all successful, the PR should remain blocked from merge.
- Once checks pass and at least 1 approval is provided (and conversation is resolved), merge should be allowed (subject to branch protection).

