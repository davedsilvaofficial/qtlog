# GOVERNANCE_BASELINE_LOCK.md — Baseline State of Record

**Baseline ID:** QTLOG-GOV-2026-01-11-09b6040-PR5  
**Established via PR:** https://github.com/davedsilvaofficial/qtlog/pull/5  
**Baseline merge commit:** 09b604064f302b1dc7b67645574fc92878a0bbf4  
**Date (ET):** 2026-01-11

## Purpose
This document designates the authoritative governance baseline state of record for this repository. It exists to:
- anchor future audits and due diligence,
- establish a fixed reference point for governance diffs,
- prevent ambiguity about “what was baseline” vs. “what changed later.”

## Baseline Controls (Summary)
- Protected branch: `main`
- Direct pushes blocked; changes must be made through PRs
- Required checks: `publish-guard`, `sop`, `verify`
- Minimum approvals required: 1
- Conversation resolution required: true
- Linear history required: true
- Force pushes: disabled
- Branch deletion: disabled
- Admin enforcement: enabled

## Evidence Location (Data Room)
- docs/Data_Room/02_Compliance/GITHUB_GOVERNANCE_ACCOUNT_SETUP.md
- docs/Data_Room/02_Compliance/GITHUB_BRANCH_PROTECTION_EVIDENCE.md
- docs/Data_Room/02_Compliance/GITHUB_BRANCH_PROTECTION_TEST_PR_EVIDENCE.md
- docs/Data_Room/02_Compliance/AUDITOR_READINESS_ONE_PAGER.md
- docs/Governance/Snapshots/ (timestamped baselines)

## Governance Accounts
- Human: davedsilvaofficial
- Governance: quantumtrek-governance (2FA enabled; recovery codes offline)

