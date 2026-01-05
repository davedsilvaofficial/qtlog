# QTLOG SOP — Notion Log Ordering & Insertion (GitHub-safe)

## Purpose
Guarantee that QT ▸ Log entries are always inserted **newest-at-top** inside the day toggle, using a stable anchor pattern (`__TOP__`) because Notion’s API does not reliably support reordering existing blocks.

This SOP is written to be committed to GitHub.

---

## Q&A (Questions and Answers)

### Q1) Where does qtlog append a *Log* entry in Notion?
**A1)** Under the page identified by `NOTION_LOG_PAGE_ID`, qtlog locates:
- the **Heading 1** block titled **"Log"**
- the **day toggle** titled `YYYY-MM-DD` (for today, ET / America/Toronto)

The actual log entry is inserted into the day toggle’s children via:
`PATCH https://api.notion.com/v1/blocks/${day_id}/children`

The insertion uses an `after: "<day __TOP__ id>"` strategy so the new entry appears immediately below `__TOP__` (i.e., at the top of the day log stream).

---

### Q2) Why do we use a `__TOP__` toggle?
**A2)** Because `__TOP__` serves as a stable insertion anchor.
Notion supports inserting “after a block id” reliably, but it does not reliably support reordering existing blocks. Using `__TOP__` lets us keep “newest-at-top” ordering by always inserting after the anchor.

---

### Q3) What invariants must be true for ordering to work?
**A3)**

**Under H1 "Log":**
- `__TOP__` toggle exists (recommended to keep as the first child; verify checks it)

**Under today’s day toggle (`YYYY-MM-DD`):**
- a child toggle named `__TOP__` exists
- that day `__TOP__` must be the **FIRST** child under the day toggle (hard invariant)

If day `__TOP__` is not first, qtlog must **fail with an explicit instruction** for the operator to drag it to the top once.

---

### Q4) What creates the structure if it’s missing?
**A4)** `ensure_today_top()` is responsible for ensuring:
- H1 "Log" exists (must exist; otherwise fail)
- H1-level `__TOP__` exists (create if missing)
- today’s `YYYY-MM-DD` day toggle exists (create if missing, inserted after H1 `__TOP__`)
- day-level `__TOP__` exists under the day toggle (create if missing)

Then it verifies the “day `__TOP__` is FIRST” invariant.

---

### Q5) What happens if Notion credentials are missing?
**A5)** For safety and local usability:
- If `NOTION_API_KEY` or `NOTION_LOG_PAGE_ID` is missing, `ensure_today_top()` prints a skip marker and returns success (no-op), and qtlog will fall back to local logging if Notion mode was requested.

This prevents “Notion not configured” from blocking local logging.

---

### Q6) How do we verify the structure without writing?
**A6)** Run:
- `./qtlog.sh --verify-all`

The verify step checks:
- first child under H1 "Log" is `__TOP__`
- first child under today’s day toggle is `__TOP__`
- (and any additional structures included in `--verify-all`)

---

### Q7) What is the correct insertion rule for newest-at-top log entries?
**A7)** Always insert the new log entry **after** the day `__TOP__` block id:

- Determine `day_id` for today
- Determine `day_top_id` where the toggle title == `__TOP__`
- `PATCH /v1/blocks/${day_id}/children` with JSON:
  - `"after": "${day_top_id}"`
  - `"children": [ { new log entry block(s) } ]`

This ensures entries land at the top of the day stream, immediately below `__TOP__`.

---

## GitHub Commit Notes
When changing ordering logic:
- Update `docs/SOP_NOTION_LOG_ORDERING.md` (this file)
- Add a short CHANGELOG entry referencing this SOP
- Add a code comment block near the Notion writer code indicating:
  - insertion point rule (“after day __TOP__”)
  - fallback behavior
  - manual action required if invariant fails

---

## Termux Best Practices (Learned the hard way)

- Always run from repo root: `cd ~/qtlog_repo || exit 1`
- Pin timestamps to ET explicitly: `TZ=America/Toronto`
- Prefer non-interactive output while debugging: `export PAGER=cat`
- Keep secrets out of GitHub:
  - store in `~/.config/qt/.env` (recommend `chmod 600`)
  - never commit API keys or page IDs
- Verify dependencies before Notion operations: `curl`, `jq`, and `python`
- When diagnosing Notion writes:
  - capture the HTTP code and response once
  - avoid repeated “retry loops” that spam Notion
- Ordering rule: rely on `__TOP__` anchors + insert-after, not reordering
- Git hygiene:
  - small commits
  - no secrets in commit messages, changelog, or docs

_Last updated: 2026-01-05 1429 ET_
