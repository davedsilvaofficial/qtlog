# Data Room — Execution Track Record
## Project Management Methodology (Canonical Index)

_Last updated: 2026-01-05 1710 ET_

This folder is the **investor / auditor / government-safe** index that answers:

> “How did you manage complexity at scale without losing control?”

It does so by linking to canonical, GitHub-safe source documents (no secrets required).

---

---

## How this fits the QT Big Picture

This Data Room corresponds to the **“Data Room → external disclosure”** layer
described in the QT – Big Picture.

It provides a **frozen, investor-safe view** of:
- the canonical method,
- its operational enforcement,
- and its audited evolution.

Live planning and narrative live in **Notion**.  
**Truth-at-time-of-action is recorded by `qtlog`.**

---

## Governance Note (Important)

Notion **explains** the system; it does **not** define or enforce it.

- Governance rules are defined in **code** (`qtlog.sh`)
- Enforcement happens at **execution time**
- Changes are tracked via **Git history and CHANGELOG.md**

This separation ensures:
- narrative flexibility without loss of control,
- operational correctness without human drift,
- and investor / auditor confidence that process discipline is enforced by tooling.


## Folder Map (what you asked to see)

📁 Data Room  
 ├─ 01_Execution_Track_Record  
 │   ├─ Project_Management_Methodology  
 │   │   ├─ WBS_MASTER_FORMAT.md  
 │   │   ├─ ARCHITECTURE.md  
 │   │   ├─ SOP_NOTION_LOG_ORDERING.md  
 │   │   └─ EXEC_SUMMARY.md  

---

## A) Canonical Method (the “how”)

### ✅ WBS_MASTER_FORMAT.md
**Canonical source:** `docs/WBS_MASTER_FORMAT.md`  
**Data Room alias:** `docs/Data_Room/01_Execution_Track_Record/Project_Management_Methodology/WBS_MASTER_FORMAT.md`

This is the single source of truth for:
- How thousands of artifacts were structured
- How versioning avoided chaos
- How nothing was overwritten or reused
- How evidence (eN), appendices (aN), and versions (vN) were controlled

This file answers:
- “How did you manage complexity at scale without losing control?”

---


---

### 🏭 Proven Lineage — Maple Leaf Foods Mini-EPM Transformation

**Canonical lineage anchor:**  
`WBS-1.1.1_Maple_Leaf_Foods_Mini_EPM_Lineage.md`

This execution system is built on a **real, large-scale transformation**:
- Thousands of employees coordinated
- ~$1B modernization program
- ~$4B annual revenue preserved
- Six Sigma + Microsoft Project Server Mini-EPM

qtlog is the **automation and evolution** of this proven model — not a theory.


## B) Operational Proof (the “it actually runs”)

### ✅ qtlog.sh (embedded contract + enforcement)
**Canonical source:** `qtlog.sh` (repo root)

Specifically:
- `QTLOG — NOTION LOG INSERTION CONTRACT`
- `ensure_today_top()` invariant enforcement
- Auto-append hooks (`QTLOG_APPEND_FILE`)

This proves:
- The system is not theoretical
- Process discipline is enforced by tooling
- Humans cannot accidentally “do the wrong thing”

This answers:
- “Is this just a deck, or is it operational?”

---

## C) Audit Trail (the “when and why”)

### ✅ CHANGELOG.md
**Canonical source:** `CHANGELOG.md`

This is critical for investors. It shows:
- When governance rules changed
- Why they changed
- That changes were intentional and traceable
- That SOP hardening followed real operational lessons

This answers:
- “Can we trust the evolution of this system?”

---

## D) Executive Framing (the “so what”)

### ✅ EXEC_SUMMARY.md
**Canonical source:** `docs/EXEC_SUMMARY.md`  
**Data Room alias:** `docs/Data_Room/01_Execution_Track_Record/Project_Management_Methodology/EXEC_SUMMARY.md`

This is the non-technical bridge. It frames the system as:
- Investor-safe
- Government-safe
- Auditor-safe
- Built under hostile real-world constraints

This answers:
- “Why does this matter to us?”

---

## E) Supporting Governance Docs

### ✅ ARCHITECTURE.md
**Canonical source:** `ARCHITECTURE.md`  
**Data Room alias:** `docs/Data_Room/01_Execution_Track_Record/Project_Management_Methodology/ARCHITECTURE.md`

### ✅ SOP_NOTION_LOG_ORDERING.md
**Canonical source:** `docs/SOP_NOTION_LOG_ORDERING.md`  
**Data Room alias:** `docs/Data_Room/01_Execution_Track_Record/Project_Management_Methodology/SOP_NOTION_LOG_ORDERING.md`

### ✅ SECURITY.md
**Canonical source:** `SECURITY.md`  
(Referenced for completeness; lives at repo root.)

---

## “Why is this done this way?” (single sentence answer)

Because the repository is designed so that the answer is discoverable in:
- the code contract (`qtlog.sh`)
- the SOP (`docs/SOP_NOTION_LOG_ORDERING.md`)
- the audit trail (`CHANGELOG.md`)

…and this Data Room index provides the investor-facing navigation layer.
