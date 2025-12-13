#!/usr/bin/env bash
set -euo pipefail

ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"

if [ ! -x "$ROOT/githooks/pre-export" ]; then
  echo "ERROR: githooks/pre-export not found or not executable" >&2
  exit 1
fi

echo "Running pre-export checks..."
"$ROOT/githooks/pre-export"

echo "Publish checks passed."
echo "You may now export / sync public artifacts safely."
