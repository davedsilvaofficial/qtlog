# Baseline ID Pattern (for Governance Diffs)

## Pattern
**BASELINE_ID :=**  
\`QTLOG-GOV-YYYY-MM-DD-<MERGE_SHA7>-PR<PR_NUMBER>\`

## Example
\`QTLOG-GOV-2026-01-11-09b6040-PR5\`

## Usage Rules
1) Every governance “baseline establishment” or “governance epoch” PR should declare a Baseline ID.
2) The Baseline ID must appear in:
   - the PR description (recommended),
   - the baseline lock file (required),
   - and at least one snapshot document (recommended).
3) Future governance diffs should reference the prior Baseline ID, e.g.:
   - “Diff from BASELINE_ID QTLOG-GOV-…”
4) Baseline IDs must be immutable once declared.

