# Investor Data Room Index (Machine-Verifiable)
**As of:** 2026-01-06 19:07 ET

This index is designed for investors/auditors to navigate the data room quickly and validate governance controls.

---

## 1) Governance & Compliance (Start Here)
- **Compliance Badge (evidence record):** `docs/Data_Room/COMPLIANCE_BADGE.md`
- **Compliance Badge (visual):** `docs/Data_Room/COMPLIANCE_BADGE.svg`
- **SOC 2 / ISO 27001 Mapping:** `docs/Data_Room/02_Compliance/SOC2_ISO27001_MAPPING.md`
- **Verifier (governance-as-code):** `tools/verify_sop_automation.py`
- **CI Workflow (Compliance):** `.github/workflows/compliance.yml`
- **CI Workflow (Release PDF):** `.github/workflows/release-pdf.yml`

---

## 2) Core Operating Pages (Authoritative Notion Hub)
Authoritative hub is the **“New Navigation Block”** at the bottom of *QT – Big Picture*.  
The verifier checks those links via Notion API against secured environment IDs.

Core pages governed by the hub:
- QT Canon
- QT Log
- QT To-Do
- QT WBS Crosswalk
- QT Due Diligence
- QT Investors

---

## 3) Governance Epochs (Baselines)
- Tags (examples):
  - `v2026.01.06-compliance`
  - `v2026.01.06-compliance-pdf`

These tags represent point-in-time baselines for governance verification and evidence integrity.

