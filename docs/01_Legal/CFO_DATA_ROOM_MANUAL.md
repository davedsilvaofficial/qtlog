# 📘 CFO Manual: Data Room Maintenance & Governance

## 1. The Golden Rule
All additions to the Data Room must be logged. No "loose files" or undocumented changes. This ensures our **SOIA** (Top Secret) compliance remains intact.

## 2. Using the qtlog System
To add a financial record or legal update, use the following command structure in the terminal:
`./qtlog.sh --both "FINANCE: Added [Document Name] to 02_Finance."`

## 3. Re-Verifying the SOP Gate
Whenever you update the Data Room, you must re-calculate the integrity hash.
1. Run `./bin/generate_index.sh` (The Librarian).
2. Run `bash ./bin/sop_hash.sh > .sop_hash` (The Seal).
3. Commit and Push to GitHub.

## 4. Access Control
Tier 1 (Public) is for initial vetting. Tier 2 (Private Vault) access is only granted after the **SOIA Screening Questionnaire** is completed and an NDA is signed.

---
*Authorized by: Dave D'Silva*
