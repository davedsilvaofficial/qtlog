# qtlog / qtday — Termux + Notion Daily Logging

## Traceability / “What ran and why” (Auditable behavior)

This repo is designed so an auditor/maintainer can answer:

- What runs automatically on Termux startup?
- Why did it run (or not run) today?
- What files prove this behavior (in repo + on device)?
- How do we prevent regression?

### Single source of truth: `qtday` command

`qtday` is the bootstrap command used everywhere (manual + auto-run). It supports:

- `qtday --status` (no side effects): prints the state + the decision (“would run” / “skip”) and why.
- `qtday` or `qtday --run`: performs the bootstrap pipeline (Log + ToDo + verify).

Repo copy (mirrored locally):
- `qt/bin/qtday` (tracked in git)

Device install location (Termux):
- `~/qt/bin/qtday` (must match the repo version)

### Proof files / markers (Termux)

These files provide evidence of the decision gates:

- **Once-per-day stamp**: `~/.config/qt/qtday.last` contains `YYYY-MM-DD`
- **Once-per-session marker**: `/data/data/com.termux/files/usr/tmp/qt/qtday.session`

Interpretation:
- If the session marker exists: `qtday` will skip with “already ran this session”
- If today matches the stamp: `qtday` will skip with “already ran today”
- Otherwise: `qtday` would run / runs (and updates the stamp)

### Debug visibility (recommended ON)

If debug is enabled, Termux startup prints one line explaining the decision.
This is intentional: the automation has side effects, so we keep it observable.

### Regression lock

This repo includes tests and CI to lock behavior:

- Bats tests: CLI behavior + sourcing-safe behavior (no accidental real path writes)
- Python tests: “format contract” for `qtday --status` output keys

CI runs on every push/PR to prevent regressions.


This repo provides a CLI (`qtlog.sh`) to write structured entries to:
- **Notion Log** (daily toggle structure, newest-at-top)
- **Notion ToDo** (daily toggle structure, newest-at-top)
- local log files (and optional git)

It also supports a daily bootstrap helper alias: **`qtday`**.

---

## Daily bootstrap: qtday

### What qtday is
`qtday` is a convenience command that prepares the day so you never fight ordering issues.

Typical alias:

- `qtday` runs:
  - `./qtlog.sh sop "bootstrap day"`  (Log-side bootstrap)
  - `./qtlog.sh --todo "bootstrap day"` (ToDo-side bootstrap)
  - `./qtlog.sh --verify-all` (strict structure verification)

### Auto-run behavior (Termux)
On Termux startup, `~/.bashrc` auto-runs **qtday** with two safety rules:

1) **Once per calendar day**
- Stored in: `~/.config/qt/qtday.last` (contains `YYYY-MM-DD`)

2) **First interactive shell per Termux session**
- Stored in: `/data/data/com.termux/files/usr/tmp/qt/qtday.session`

Meaning:
- If you open multiple shells/tabs in the same Termux session, qtday runs only once.
- If you fully close Termux and reopen, it may run again **only if the day changed**.

---

## Debug output (recommended ON)

When `QTLOG_QTDAY_DEBUG=1` is exported in `~/.bashrc`, each new interactive shell prints a one-line reason:

Examples:
- `qtday: ran — 2025-12-21 0912 ET`
- `qtday: skip — already ran today (2025-12-20)`
- `qtday: skip — already ran this session`
- `qtday: skip — qtday missing`

This is intentionally “always visible” so you can trust automation with side effects.

---

## Notion structure contracts

### Root ordering (newest-at-top)
Both Log and ToDo have the same root contract under their headings:

- child #1: `__TOP__` toggle (must be empty)
- child #2: `YYYY-MM-DD` (today) toggle

### Day ordering
Inside each `YYYY-MM-DD` toggle:
- a `__TOP__` toggle must exist and be empty
- entries are inserted “after” the day-level `__TOP__` so newest appear at top

---

## Verify commands

- `./qtlog.sh --verify`  
  Checks core anchors

- `./qtlog.sh --verify-todo`  
  Checks ToDo anchors only

- `./qtlog.sh --verify-all`  
  Strict “supercheck” (root + day contracts for Log + ToDo)

---

## Planned additions

### qtday --status
A status command that prints:
- Today date
- `qtday.last` stamp
- session marker existence
- whether qtday exists in PATH
- the run/skip decision and reason

### Notion logging for qtday
When qtday actually runs (not skip), write a Notion Log entry marking the bootstrap run.

### Tests
Add repo tests to prevent regressions in:
- help text
- verify behavior (especially missing-env safety)
- qtday status output format

---

## Tests (regression lock)

This repo includes tests to prevent regressions in:

- `qtday --status` output keys + decision text (format contract)
- `qtday --status` behavior under session marker conditions (CLI behavior)
- future additions: `qtlog.sh --verify-all` contracts (Log + ToDo newest-at-top)

### Run tests

- `./scripts/test.sh`
- or `make test`

### Why env overrides exist in qtday

For safe testing, `qtday` supports env overrides so tests don’t touch real Termux paths:

- `QTDAY_SESS_FILE`
- `QTDAY_STAMP_FILE`
- `QTDAY_REPO_DIR`
- `QTDAY_ENV_FILE`
- `QTDAY_TZ`

Production behavior is unchanged when these are not set.
