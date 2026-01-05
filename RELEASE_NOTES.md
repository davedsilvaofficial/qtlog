# Release Notes

## v1.0.1 — Screened public export boundary enforced

### Summary
This release hardens the public export boundary by introducing a **pre-export guard** that prevents public artifacts from referencing private paths and enforces a required screening header for screened public content.

### What shipped
- **Pre-export guard:** blocks references to private paths (e.g., `../` and `sec/`) from tracked `public/` files.
- **Screened public requirement:** files under `public/screened/` must include a `screened-by:` header.
- **Publish gate:** `publish.sh` runs the pre-export checks before any export/sync.

### Operator workflow
1. Run `./publish.sh`
2. If checks pass, export/sync public artifacts.

### Tag
- `v1.0.1` (annotated tag) pushed to origin.


### Documentation

- **SOP hardening (Android / Termux)**
  - Fixed `DIRECTORY STRUCTURE` code fence rendering issue.
  - Verified and formalized Android / Termux credential handling to prevent intermittent authentication failures.
  - Reference SOP tag: `sop-fix-directory-structure-v1`

