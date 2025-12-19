# CHANGELOG

## Discipline (Daily Use)

- Read `docs/QT-Coding-SOP.md` first when changing behavior or process.
- This `CHANGELOG.md` is the daily audit anchor: every functional or governance change must be recorded.
- If a step produced no proof/output, it is treated as not executed.
- Generator (if used): `scripts/update-changelog.sh`


Generated: 2025-12-14 0816 EST

## Unreleased (since v1.2.3)
- 2025-12-19 (uncommitted) feat(verify): add --verify read-only Notion newest-at-top anchor check; prints VERIFY_TIME (ET)
- 2025-12-19 (uncommitted) chore(notion): remove DEBUG_NOTION gating (default debug env no longer required)
- 2025-12-19 (uncommitted) docs(help): document --verify in usage()/help output
- 2025-12-14 ae227af chore: add CHANGELOG.md and generator script for daily code review
- 2025-12-13 04203d2 Enforce explicit yes/no confirmation before qtlog git commits
- 2025-12-13 65402fd Harden governance: bind qtlog.sh to SOFTWARE_INVENTORY and add executable guard header
- 2025-12-13 a8b6174 Add executable software inventory
- 2025-12-13 07a33f2 Harden disclosure governance: PPM guardrails, publish policy enforcement, and source-of-truth register
- 2025-12-13 df9a606 Add References due-diligence structure and verification guidance
- 2025-12-13 51a2e06 Add gated Equity Terms due-diligence structure and guidance
- 2025-12-13 db4828a Add gated Legal and Security due-diligence structure and guidance
- 2025-12-13 7cce3c1 Add IP and technology due-diligence structure and guidance
- 2025-12-13 d1a3c1b Add investor-grade Financials data-room structure and guidance
- 2025-12-13 d6e7a15 ci(guard): run publish.sh via bash with dry-run args in CI
- 2025-12-13 c10ed8d ci(guard): normalize publish.sh guard message and exit code
- 2025-12-13 66cbf49 ci(guard): non-fatal publish guard with exit code reporting
- 2025-12-13 3b868e9 ci(guard): add publish guard stub enforcing screened exports
- 2025-12-13 90280ea ci(guard): add GitHub Actions publish guard enforcing screened exports
- 2025-12-13 715b13e docs(release): add v1.0.1 release notes for screened export boundary
- 2025-12-13 0e8add5 feat(boundary): enforce screened public exports with pre-export guard
- 2025-12-13 67cf941 test(public): should be blocked
- 2025-12-13 47e05ed test(hook): benign patterns
- 2025-12-13 0097e8c test(hook): safe content
- 2025-12-13 1f550fb chore(repo): add pre-commit hook and public export README

## v1.2.3
- 2025-12-13 3e7b4bb feat(integrity): enforce pre-export scan blocking non-/public references
- 2025-12-13 4b4eb86 docs(security): add explicit public export policy (public/ only)
- 2025-12-13 304d7bc docs(security): define explicit public vs private boundary (public/ only)
- 2025-12-13 b8d9f93 chore(security): enforce private-by-default gitignore (sec/, secrets, env)
- 2025-12-12 0653579 docs: add version badge v1.2.2
- 2025-12-12 b949589 docs: add v1.2.2 release notes (authoritative ET helpers)

## v1.2.2
- 2025-12-12 c16b7f8 v1.2.2: add --stamp-now helper and early short-circuit (authoritative ET time)
- 2025-12-12 df0b67b Pin timezone to America/Toronto to eliminate timestamp drift (Termux-safe)
- 2025-12-12 f41b10b [Fold7] 2025-12-12 2025-12-12 2244 EST CODE: QF-ION-INTEGRITY — Suspend investor/sovereign mapping work. Integrity concern: current submission has not been validated against initial quantumfusion.ca and ion drive/impulse-engine materials. Once validated/mapped, formalize into the propellantless component. Return to this after baseline references reviewed.
- 2025-12-06 4548efd Update SEC filing notes under SOP pattern
- 2025-12-06 05fed71 Add SEC filing notes to repo under docs
- 2025-12-06 4b552c1 Add coding SOP for Notion log automation
- 2025-12-06 97cec51 Add qtlog.sh upgrade SOP (SOP.md)
- 2025-12-06 c94dca5 Upgrade qtlog.sh to v1.2.1
- 2025-12-06 6094bb5 [Fold7] 2025-12-06 2025-12-06 1110 EST v1.2.1 install test
- 2025-12-06 d581657 Upgrade qtlog.sh to v1.2.1
- 2025-12-06 3ef915c [Fold7] 2025-12-06 2025-12-06 1055 EST v1.2.1 install test
- 2025-12-06 b7a0a44 Upgrade qtlog.sh to vX.Y.Z
- 2025-12-06 0533e23 [Fold7] 1029 EST Test log entry vX.Y.Z
- 2025-12-06 89c4d93 Ignore backup and before-format files
- 2025-12-06 6df88f9 [Fold7] 2025-12-06 0937 EST Sync logic test

## v1.1.0


## v1.0.1
- 2025-12-13 0e8add5 feat(boundary): enforce screened public exports with pre-export guard
- 2025-12-13 67cf941 test(public): should be blocked
- 2025-12-13 47e05ed test(hook): benign patterns
- 2025-12-13 0097e8c test(hook): safe content
- 2025-12-13 1f550fb chore(repo): add pre-commit hook and public export README
- 2025-12-13 3e7b4bb feat(integrity): enforce pre-export scan blocking non-/public references
- 2025-12-13 4b4eb86 docs(security): add explicit public export policy (public/ only)
- 2025-12-13 304d7bc docs(security): define explicit public vs private boundary (public/ only)
- 2025-12-13 b8d9f93 chore(security): enforce private-by-default gitignore (sec/, secrets, env)
- 2025-12-12 0653579 docs: add version badge v1.2.2
- 2025-12-12 b949589 docs: add v1.2.2 release notes (authoritative ET helpers)
- 2025-12-12 c16b7f8 v1.2.2: add --stamp-now helper and early short-circuit (authoritative ET time)
- 2025-12-12 df0b67b Pin timezone to America/Toronto to eliminate timestamp drift (Termux-safe)
- 2025-12-12 f41b10b [Fold7] 2025-12-12 2025-12-12 2244 EST CODE: QF-ION-INTEGRITY — Suspend investor/sovereign mapping work. Integrity concern: current submission has not been validated against initial quantumfusion.ca and ion drive/impulse-engine materials. Once validated/mapped, formalize into the propellantless component. Return to this after baseline references reviewed.
- 2025-12-06 4548efd Update SEC filing notes under SOP pattern
- 2025-12-06 05fed71 Add SEC filing notes to repo under docs
- 2025-12-06 4b552c1 Add coding SOP for Notion log automation
- 2025-12-06 97cec51 Add qtlog.sh upgrade SOP (SOP.md)
- 2025-12-06 c94dca5 Upgrade qtlog.sh to v1.2.1
- 2025-12-06 6094bb5 [Fold7] 2025-12-06 2025-12-06 1110 EST v1.2.1 install test
- 2025-12-06 d581657 Upgrade qtlog.sh to v1.2.1
- 2025-12-06 3ef915c [Fold7] 2025-12-06 2025-12-06 1055 EST v1.2.1 install test
- 2025-12-06 b7a0a44 Upgrade qtlog.sh to vX.Y.Z
- 2025-12-06 0533e23 [Fold7] 1029 EST Test log entry vX.Y.Z
- 2025-12-06 89c4d93 Ignore backup and before-format files
- 2025-12-06 6df88f9 [Fold7] 2025-12-06 0937 EST Sync logic test
- 2025-12-06 a4e7936 Improve timestamp format (YYYY-MM-DD HHMM TZ), add device override
- 2025-12-06 cd079d9 [Fold7] 2025-12-06 0857 EST New timestamp test
- 2025-12-06 8ba65c5 [Fold7] 2025-12-06 0855 EST New timestamp test
- 2025-12-06 4dfac61 [Fold7] 2025-12-06 0853 EST New log format test

## v1.0.0
- 2025-12-06 eaa9164 [Fold7] 2025-12-06 2025-12-06 0822 safe pull test
- 2025-12-06 72645b9 Device override + auto-detect logic
- 2025-12-06 988f7c7 [Fold7] 2025-12-06 2025-12-06 0809 Fold7 manual-override test
- 2025-12-06 a12f4a7 [Fold7] 2025-12-06 2025-12-06 0745 Device auto-detect test
- 2025-12-06 0f6349f [Fold7] 2025-12-06 2025-12-06 0728 Fold7 bootstrap working test
- 2025-12-05 78cf68e [Fold7] 2025-12-05 2043 Fold7 device auto-push test
- 2025-12-05 7b7b3eb [Fold7] 2025-12-05 2025-12-05 1928 Test entry A
- 2025-12-05 0f07dd2 [Fold7] 2025-12-05 1716 Fold7 device auto-pull + tag test
- 2025-12-05 12ace1e Bootstrap Fold7 qtlog env + script
- 2025-12-05 d5dd387 [SamsungGalaxyFold7] 2025-12-05 1432 Fold7 device-tag test entry
- 2025-12-05 0e6cf1a Second auto-push test - verifying repeat commit
- 2025-12-05 1764e2b Test auto-push entry from updated script
- 2025-12-05 137e6f4 Create README.md


### Governance
- Accepted operator-approved screenshot-to-text conversions (e.g., Gemini OCR) as valid proof (soft rule). Validation responsibility remains with the assistant.


## 2025-12-14 19:09 EST
- PREVIEW: Recover from --help syntax regression caused by unsafe help-text insertion; will re-add hierarchy using shell-safe heredoc.
