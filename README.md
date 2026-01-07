## Daily bootstrap (qtday)

- `qtday` prepares the day (Log + ToDo) and runs `--verify-all`.
- Termux auto-runs `qtday` once per day + first interactive shell per session (with optional debug messages).

See: `docs/qtlog.md`

![version](https://img.shields.io/badge/version-v1.2.2-blue)

```# qtlog — Quantum Trek Logging
## Release Notes — v1.2.2

### Summary
Adds authoritative Eastern Time (ET) helpers to eliminate perceived timestamp drift across Termux, subshells, Git, and external UIs.

### What Changed
- **New helper: `--stamp-now`**  
  Prints the authoritative current time in **America/Toronto (ET)** and exits.  
  Use this when you need to know “what time is it really, right now?”

- **New helper: `--reconcile`**  
  Prints the authoritative system ET time and exits.  
  Useful for cross-checking timestamps when other displays appear delayed or inconsistent.

### Why This Exists
Some environments (Termux, subshells, pagers, external UIs) can display time that appears behind due to caching or timezone inheritance.  
`qtlog` now provides a single source of truth by pinning time to **America/Toronto (ET)**.

### Usage
```bash
./qtlog.sh --stamp-now
./qtlog.sh --reconcile
This repository contains the logging script `qtlog.sh` and related files for automated project logging.

## About
`qtlog.sh` is a shell script designed to:
- capture timestamped log entries
- store logs locally
- version log code
- sync logs to a private repository
- support multi-device development

## Release Notes — v1.2.2

### Summary
Adds authoritative Eastern Time (ET) helpers to eliminate perceived timestamp drift across Termux, subshells, Git, and external UIs.

### What Changed
- **New helper: `--stamp-now`**  
  Prints the authoritative current time in **America/Toronto (ET)** and exits.  
  Use this when you need to know “what time is it really, right now?”

- **New helper: `--reconcile`**  
  Prints the authoritative system ET time and exits.  
  Useful for cross-checking timestamps when other displays appear delayed or inconsistent.

### Why This Exists
Some environments (Termux, subshells, pagers, external UIs) can display time that appears behind due to caching or timezone inheritance.  
`qtlog` now provides a single source of truth by pinning time to **America/Toronto (ET)**.

### Usage
```bash
./qtlog.sh --stamp-now
./qtlog.sh --reconcile

## Directory Structure

---

## Public vs Private Boundary

This repository is **private by default**.

Only the contents of the `/public` directory are intended to be used for:
- documentation
- examples
- public sharing

Everything else in this repository is considered **private, operational, or sensitive** and must never be published verbatim.


## Tests

Run:
- `./scripts/test.sh`
- or `make test`

## Documentation

- Architecture: [ARCHITECTURE.md](ARCHITECTURE.md)
- Security notes: [SECURITY.md](SECURITY.md)
- Notion ordering SOP: [docs/SOP_NOTION_LOG_ORDERING.md](docs/SOP_NOTION_LOG_ORDERING.md)
- Executive summary (non-technical): [docs/EXEC_SUMMARY.md](docs/EXEC_SUMMARY.md)
- Changelog / audit trail: [CHANGELOG.md](CHANGELOG.md)

## Data Room

Investor-facing, GitHub-safe external disclosure index:
- [docs/Data_Room/README.md](docs/Data_Room/README.md)


## 📋 Data Room Compliance

[![Data Room Compliance](docs/Data_Room/COMPLIANCE_BADGE.svg)](docs/Data_Room/COMPLIANCE_BADGE.md)

- **Status:** PASS
- **Tag:** v2026.01.06-compliance
- **Release:** https://github.com/davedsilvaofficial/qtlog/releases/tag/v2026.01.06-compliance
- **SOC 2 / ISO Mapping:** docs/Data_Room/02_Compliance/SOC2_ISO27001_MAPPING.md
- **Investor Index:** docs/Data_Room/INVESTOR_DATA_ROOM_INDEX.md
- **Evidence:** docs/Data_Room/COMPLIANCE_BADGE.md
- **Explanation:** docs/Data_Room/COMPLIANCE_BADGE.md#what-this-compliance-run-represents
- **Verification:** Strict bottom-only QT Big Picture hub

