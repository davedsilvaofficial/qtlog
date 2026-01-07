# SOC 2 / ISO 27001 Mapping — Governance-as-Code Controls
**As of:** 2026-01-06 19:07 ET  
**Repository:** qtlog (GitHub source-of-truth)  

This document maps Quantum Trek’s *governance-as-code* compliance system to:
- **SOC 2 Trust Services Criteria (TSC)** categories, and
- **ISO/IEC 27001 Annex A** control themes (high-level).

**Scope note:** This is a *control mapping + evidence index* (audit-ready structure). Formal SOC 2 / ISO certification requires an auditor-led engagement and full organizational scope definition.

---

## System Summary (What We Control)
**Control objective:** Prevent undetected documentation drift and enforce an authoritative governance navigation hub.

**Mechanisms (controls by construction):**
- **Verification script:** `tools/verify_sop_automation.py`
- **CI enforcement:** `.github/workflows/compliance.yml`
- **Release artifact build/attach:** `.github/workflows/release-pdf.yml`
- **Evidence artifacts:**
  - `docs/Data_Room/COMPLIANCE_BADGE.md`
  - `docs/Data_Room/COMPLIANCE_BADGE.svg`
  - `ONE_PAGER.md` → rendered PDF in Release workflow
- **Immutable governance epoch tags:** e.g. `v2026.01.06-compliance`, `v2026.01.06-compliance-pdf`

---

## Primary Evidence References
- **Compliance record (human-readable):** `docs/Data_Room/COMPLIANCE_BADGE.md`
- **Visual badge (renders in README):** `docs/Data_Room/COMPLIANCE_BADGE.svg`
- **Authoritative navigation requirement:** *QT – Big Picture* → **“New Navigation Block”**
- **Verifier enforcement point:** strict bottom-only hub verification in `verify_sop_automation.py`
- **CI enforcement:** GitHub Actions “Compliance” workflow (required to pass once branch protection is enabled)
- **Release evidence:** GitHub Releases (tagged) + attached PDF (once CI run attaches assets)

---

## Control Mapping Table (SOC 2 ↔ ISO 27001 ↔ Evidence)
> This table uses **SOC 2 category-level mapping** (Security/Availability/etc.) and **ISO Annex A themes** (high-level) to index evidence.

| Control Mechanism | SOC 2 (TSC) Category | ISO/IEC 27001 Annex A Theme | What It Achieves | Evidence / Where to Inspect |
|---|---|---|---|---|
| Strict “New Navigation Block” hub verification (Notion API) | Security, Integrity | A.5 (policies), A.8 (asset mgmt), A.12/A.14 (change/SDLC themes) | Prevents unauthorized or accidental drift in governance navigation | `tools/verify_sop_automation.py` + Notion page links validated via API |
| GitHub Actions “Compliance” workflow | Security, Availability, Integrity | A.12 (ops), A.14 (SDLC), A.16 (incident mgmt themes) | Continuous enforcement on push/PR; fails build on drift | `.github/workflows/compliance.yml` + Actions run logs |
| Environment-based identity (repo secrets) | Security | A.5/A.8/A.9 (access control themes) | No hard-coded sensitive IDs; secrets controlled by GitHub | Repo secrets: `NOTION_API_KEY`, `QT_*_PAGE_ID` (configured) |
| Immutable evidence artifacts committed in repo | Integrity | A.8 (asset mgmt), A.12 (ops) | Preserves evidence trail inside source-of-truth | `docs/Data_Room/COMPLIANCE_BADGE.md`, `.svg`, README pointers |
| Signed governance tag (“epoch”) | Integrity | A.8/A.12 | Anchors a point-in-time baseline state | Git tag: `v2026.01.06-compliance*` (tag metadata) |
| Release PDF workflow (containerized build) | Integrity, Availability | A.12/A.14 | Reproducible, auditor-readable PDF generated in clean env | `.github/workflows/release-pdf.yml` + Release assets |
| Artifact upload (Actions) | Availability, Integrity | A.12 | Keeps build outputs available for review | Actions artifacts + Release attachments |

---

## SOC 2 Category Notes (How to Read This)
- **Security:** Controls prevent unauthorized changes and detect drift.
- **Availability:** CI automation executes reliably and is repeatable.
- **Integrity:** Outputs and governance structure are deterministic, evidence-bound.
- **Confidentiality:** Secrets are stored in GitHub Actions Secrets, not in code.
- **Privacy:** Not in scope here unless personal data processing is introduced.

---

## ISO/IEC 27001 Notes (High-Level)
This mapping references **Annex A themes**, not a full Statement of Applicability (SoA).  
If/when you proceed toward ISO certification, this document becomes the seed for:
- **SoA creation**
- **risk register linkage**
- **control ownership + operating effectiveness evidence**

---

## Evidence

- **Governance Glossary:** docs/Data_Room/02_Compliance/GLOSSARY.md Checklist (Auditor / Investor Quick View)
- [ ] README shows PASS badge and links to evidence section
- [ ] `docs/Data_Room/COMPLIANCE_BADGE.md` includes explanation + PASS record
- [ ] `tools/verify_sop_automation.py` enforces strict bottom-only hub verification
- [ ] GitHub Actions: “Compliance” run passes on main
- [ ] Release workflow exists for PDF artifact attachment on tags
- [ ] Governance epoch tags exist and are documented

---

## SOC 2 Auditor Narrative (Governance Control Environment)

The organization enforces governance controls through automated
Continuous Integration (CI) mechanisms designed to prevent unauthorized
or undetected changes to authoritative documentation.

Controls are executed on every proposed change and include automated
verification of governance navigation integrity, required artifact
presence, and linkage between operational documentation and the
source-of-truth repository.

Control failures result in immediate rejection of the change and
prevent promotion into the production branch.

These controls support SOC 2 Trust Services Criteria related to
Security and Processing Integrity by ensuring changes are authorized,
reviewed, verified, and fully auditable.

Evidence is generated automatically through system execution and is
retained in immutable repositories and signed releases.

---
