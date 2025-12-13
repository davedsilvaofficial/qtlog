#!/usr/bin/env bash
set -euo pipefail

# publish.sh — policy guard + mode/stamp helpers
# Default behavior (no args): block public publishing (exit 1).
# Flags are for local workflows and future automation hooks.

MODE="both"        # github|notion|both
DRY_RUN=0
STAMP_NOW=0

usage() {
  cat <<'USAGE'
Usage: ./publish.sh [--mode github|notion|both] [--stamp-now] [--dry-run] [--help]

Behavior:
  - Default (no args): prints policy guard message and exits 1 (blocks publish).
  - --dry-run: prints what would happen and exits 0.
  - --stamp-now: prints an ET timestamp line (for copy/paste + reconciliation).
  - --mode: selects intended logging targets (future hooks): github, notion, or both.
USAGE
}

# Parse args
while [[ $# -gt 0 ]]; do
  case "$1" in
    --mode)
      MODE="${2:-}"
      shift 2
      ;;
    --stamp-now)
      STAMP_NOW=1
      shift
      ;;
    --dry-run)
      DRY_RUN=1
      shift
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

case "$MODE" in
  github|notion|both) ;;
  *)
    echo "Invalid --mode: $MODE (expected github|notion|both)" >&2
    exit 2
    ;;
esac

# Timestamp helper (ET with DST)
if [[ "$STAMP_NOW" -eq 1 ]]; then
  TZ="America/Toronto" date +"%Y-%m-%d %H%M ET"
fi

echo "Publish Guard active"
echo "This repository requires screened / redacted export."
echo "Direct public publish is blocked by policy."
echo "mode=$MODE dry_run=$DRY_RUN"

if [[ "$DRY_RUN" -eq 1 ]]; then
  echo "Dry run: no publish attempted."
  exit 0
fi

# Guard: block direct publish by default
exit 1

