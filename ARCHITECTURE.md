# qtlog — Architecture & Design Rationale

_Last updated: 2026-01-05 1647 ET_

## Why this exists
If someone asks “why is this done this way?” the answer must be discoverable in:
- the code (qtlog.sh contract block)
- the SOP (docs/SOP_NOTION_LOG_ORDERING.md)
- the changelog (CHANGELOG.md)
- this architecture note

## What we guarantee
- Zero-assumption SOP engineering (verify before side effects)
- Deterministic Notion log ordering under hostile API constraints
- Termux/Android operational discipline (non-interactive, timezone pinned, secrets kept out of git)
- Audit-safe documentation (no private IDs/secrets required to understand intent)

## Key ordering design
Notion does not reliably reorder blocks.
Therefore:
- we enforce a stable `__TOP__` anchor
- we insert new day entries AFTER the day `__TOP__` block id
- we fail fast if invariants are violated (operator action: drag `__TOP__` to first child once)

## Where the truth lives
- Code contract: `qtlog.sh` (QTLOG — NOTION LOG INSERTION CONTRACT)
- Canonical SOP: `docs/SOP_NOTION_LOG_ORDERING.md`
- Audit trail: `CHANGELOG.md`
