# Executive Summary — qtlog (Non-Technical)

_Last updated: 2026-01-05 1647 ET_

## What qtlog is
qtlog is a lightweight operational logging system designed to produce:
- consistent daily logs,
- optional Notion mirroring for traceability,
- and a GitHub-backed audit trail.

It is built for real-world constraints (Android/Termux, unreliable APIs, human workflows).

## Why it exists
When building investor/government/auditor-facing documentation, the weakest point is often process drift:
- logs become inconsistent,
- ordering breaks,
- assumptions creep in,
- secrets leak into public repos,
- and nobody can explain “why” decisions were made.

qtlog solves this by enforcing SOP-grade discipline in tooling.

## What this repo demonstrates
- **Zero-assumption SOP engineering**  
  Dependencies are verified before side effects occur.

- **API-ordering correctness under hostile constraints**  
  Notion ordering is enforced deterministically using a stable `__TOP__` anchor.

- **Android/Termux operational knowledge**  
  Non-interactive workflows, timezone pinning, and hard rules to prevent failure loops.

- **Investor / auditor / gov-safe documentation discipline**  
  The “why” is captured in code, SOPs, and changelog — without requiring secrets.

## How “why is it done this way?” is answered
- Code-level contract: `qtlog.sh` (embedded Q&A contract)
- Canonical SOP: `docs/SOP_NOTION_LOG_ORDERING.md`
- Audit trail: `CHANGELOG.md`
- Architecture overview: `ARCHITECTURE.md`

## Bottom line
This repository is structured so that correctness and intent survive:
- unreliable API behavior,
- operational friction on mobile,
- and human memory loss over time.
