# qtlog / qtday — Auditor / Maintainer Readme (1 page)

## Purpose
This repo provides a Termux-friendly CLI to write structured entries into Notion.

Core contracts:
- Log + ToDo are maintained with **newest-at-top** ordering.
- A daily bootstrap helper (`qtday`) ensures the day structure exists and is verified.

## Single source of truth: `qtday`
`qtday` is the one bootstrap command used everywhere.

- `qtday --status` (no side effects)
  - Prints: today, qtday.last, session marker status, repo/env paths, and the decision (“skip/would run”) with reason.
- `qtday` / `qtday --run`
  - Runs: bootstrap Log + bootstrap ToDo + strict verify.

Tracked file in repo:
- `qt/bin/qtday`

Installed location on Termux device:
- `~/qt/bin/qtday` (should match repo version)

## Decision evidence (“why did it run?”)
Two markers govern whether `qtday` runs:

1) Once per day:
- `~/.config/qt/qtday.last` contains `YYYY-MM-DD`

2) Once per Termux session:
- `/data/data/com.termux/files/usr/tmp/qt/qtday.session` exists after first interactive shell

Interpretation:
- If session marker exists → skip (“already ran this session”)
- Else if last == today → skip (“already ran today”)
- Else → run (and update `qtday.last`)

## Regression lock
Tests included:
- `tests/qtday_status.bats` (CLI behavior / session marker logic)
- `tests/test_qtday_status_format.py` (format contract: keys appear exactly once)

CI workflow:
- `.github/workflows/ci.yml`

## Release marker
Traceability lock tag:
- `v1.0.0 (traceability-locked)`

---

## Index Authority (Navigation Control)

For audit/due diligence navigation, the authoritative index is:

- **MASTER_INDEX.md** (repository-wide single source of truth)

Secondary convenience indexes:
- `docs/INDEX.md` (docs folder canonical index)
- `docs/README.md` (secondary docs landing page)
- `docs/index.md` (intentional redirect; non-authoritative)

If any links conflict, defer to **MASTER_INDEX.md**.
