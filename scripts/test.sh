#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

echo "[1/2] Bats..."
bats tests/*.bats

echo "[2/2] Pytest..."
pytest -q
