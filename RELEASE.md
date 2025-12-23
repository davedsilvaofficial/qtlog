
## v1.3.5 — 2025-12-23

### Fixed
- **Notion day creation invariant**: new daily log toggles are now created with an embedded `__TOP__` child on first insert.
- Eliminates post-create anchor repair and manual drag operations.
- Guarantees *newest-at-top* ordering from the first entry of a new day.

### Verified
- Confirmed via direct Notion API inspection.
- Simulated future-day creation (`YYYY-MM-DD+1`) to ensure zero manual intervention.

## v9.9.9 — 2025-12-23

### Fixed
- Smoke test: make release appends to bottom; auto-stamps date; enforces ordering.
