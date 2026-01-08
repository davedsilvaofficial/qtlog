#!/usr/bin/env bash
set -euo pipefail

echo "[governance-verify] Running one-command governance verification..."

# 1) Emergency workflow should exist and be parseable (warn-only validator emits ::warning)
python tools/check_emergency_workflow.py || true

# 2) Ensure governance doc exists
test -f docs/GOVERNANCE_EMERGENCY_MODE.md || { echo "ERROR: docs/GOVERNANCE_EMERGENCY_MODE.md missing"; exit 1; }

# 3) Ensure docs indices exist
test -f docs/INDEX.md || { echo "ERROR: docs/INDEX.md missing"; exit 1; }
test -f docs/README.md || { echo "ERROR: docs/README.md missing"; exit 1; }

echo "[governance-verify] OK"
