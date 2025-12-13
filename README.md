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
