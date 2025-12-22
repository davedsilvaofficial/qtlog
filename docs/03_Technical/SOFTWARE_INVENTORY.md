# 🛠️ Software Inventory & Control Registry
**Authoritative Version:** v1.3.0
**Project Lead:** Dave D'Silva

## 1. Core Infrastructure
| Artifact | Version | Description | Governance Role |
| :--- | :--- | :--- | :--- |
| `qtlog.sh` | 1.3.0 | Unified CLI Dispatcher | Primary Operational Control |
| `.env` | - | Environment Configuration | Sensitive Key Management |
| `.sop_hash` | - | Immutable SOP Fingerprint | Integrity Verification |

## 2. Automation & Utility Binaries (`bin/`)
| Script | Version | Description | Governance Role |
| :--- | :--- | :--- | :--- |
| `generate_index.sh` | 1.1.0 | Automated Librarian | Data Room Navigation |
| `sop_hash.sh` | 1.0.0 | SOP Integrity Generator | Change Control / Auditing |
| `qt-wbs` | 1.0.0 | Work Breakdown Structure | Project Lifecycle Tracking |

## 3. Git Invariants & Hooks
* **Pre-Commit Hook:** Executes `qtlog.sh --sop-verify` to prevent unauthorized state changes.
* **Master Index:** Automated synchronization with repository structure via `generate_index.sh`.

---
*Last Audited: $(TZ="America/New_York" date "+%Y-%m-%d %H:%M:%S ET")*
