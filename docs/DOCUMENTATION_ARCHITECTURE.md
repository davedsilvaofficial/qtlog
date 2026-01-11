# Documentation Architecture & Navigation

## Purpose
This repository is designed to be **self-explanatory** for:
- future maintainers (including “future Dave”),
- assigned programmers,
- auditors / due diligence reviewers,
- investors (via the Data Room subset).

It is organized so that **governance evidence** remains clean and traceable, while operational work can evolve without contaminating the audit trail.

---

## Authoritative Indexes (Read This First)

1) **Repository Master Index (Authoritative)**
- `MASTER_INDEX.md`
- This is the single source of truth for documentation navigation.

2) **Docs Folder Index (Canonical within /docs)**
- `docs/INDEX.md`
- Sub-index of key docs and governance references.

3) **Redirect (Non-authoritative)**
- `docs/index.md`
- Exists only to prevent ambiguity for tooling and readers. It points to the two canonical indexes above.

---

## Repository “Front Door” Files (Top-level)

- `README.md` — overview and entry points for developers and reviewers.
- `MASTER_INDEX.md` — authoritative documentation map (single source of truth).
- `AUDITOR_README.md` — audit-specific orientation and evidence expectations.
- `SECURITY.md` — IP protection + access protocols.
- `SOP.md` — operating procedures for logging, changes, and governance discipline.
- `CHANGELOG.md` — change history.
- `ARCHITECTURE.md` — system/approach overview (high-level).
- `ONE_PAGER.md` — executive-level overview.
- `SOC2_ISO_MAPPING.md` — high-level compliance mapping reference (expanded mapping also exists in Data Room).

---

## Documentation Zones (Under /docs)

### 00_Administration
Administrative summaries and status reports.

### 01_Legal
Legal checklists, handover summaries, security clearance notes, and governing document references.

### 02_Finance
Use-of-proceeds, SEC filing notes, financial planning artifacts.

### 03_Technical
Engineering SOPs, software inventory, technical narrative.

### 04_Defense
Defense-facing capability statements and engagement strategy documentation.

### Data_Room (Investor / Diligence Subset)
`docs/Data_Room/` is a curated structure suitable for investor diligence:
- `docs/Data_Room/INVESTOR_DATA_ROOM_INDEX.md` is the entry point
- compliance mapping, glossary, control ownership, and board artifacts live here
- prefer placing investor-facing evidence here once reviewed and approved

### Governance (Evidence Trail)
- `docs/GOVERNANCE_*` and `docs/Governance/Snapshots/`
- These support evidence chaining and governance traceability.
- Snapshots are timestamped and should not be casually edited.

---

## Where New Documents Should Go

When creating new documentation:
1) Choose the correct zone (`01_Legal`, `02_Finance`, `03_Technical`, etc.).
2) Use clear, stable names (UPPER_SNAKE_CASE.md preferred).
3) Add the doc link to:
   - `MASTER_INDEX.md` (authoritative),
   - and optionally `docs/INDEX.md` if it’s a docs-level quick reference.

---

## “Rule of Authority”
- **MASTER_INDEX.md is the authoritative navigation map.**
- Folder-level indexes are secondary convenience views.
- Evidence-chain documents (Governance/Snapshots) should be treated as controlled artifacts.

---

## Quick Start (For New Programmers)
1) Read: `README.md` → `MASTER_INDEX.md`
2) Review operating rules: `SOP.md`, `SECURITY.md`
3) If working on compliance/governance: `AUDITOR_README.md`, `docs/GOVERNANCE_*`, `docs/Data_Room/*`
4) If working on tooling/scripts: start in `docs/03_Technical/*` and the repo `bin/` / `qt/` folders as applicable.
