# Software Inventory — Executable Artifacts
Quantum Trek Corporation

## Purpose
This document lists executable scripts created or formalized in this repository.
It exists to prevent loss of operational knowledge and to distinguish
governance-critical software from utilities.

Only versioned executables are listed here.

---

## CORE GOVERNANCE SCRIPTS

### 1. publish.sh
Type: Shell script (executable)

Role:
- Enforces disclosure and publish discipline
- Controls publish modes (GitHub / Notion / both)
- Blocks accidental or direct publication
- Acts as a governance control layer

Status:
- Active
- Governance-critical

Notes:
This script encodes policy, not just mechanics.
Any modification should be reviewed for disclosure impact.

---

### 2. qt-log-entry.sh
Type: Shell script (executable)

Role:
- Creates structured, timestamped operational logs
- Supports auditability and diligence traceability
- Replaces informal memory with durable records

Status:
- Active
- Memory-critical

Notes:
This script is part of the operational audit trail.
It should not be removed without replacement.

---

## SUPPORTING CONTROLS

### 3. Pre-commit Hook
Type: Git hook / policy script

Role:
- Enforces commit hygiene
- Prevents malformed or incomplete commits

Status:
- Active
- Supporting control

Notes:
This hook operates silently but protects repository integrity.

---

## EXCLUDED ITEMS (NOT EXECUTABLE)

The following are intentionally excluded from this inventory:
- README files
- Markdown policy documents
- Planning notes
- Legal documents (PPM, agreements)

These are governance artifacts, not software.

---

## Change Control
Any addition, removal, or deprecation of executable scripts
must be reflected in this file.

