#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

echo "[bootstrap] Updating Termux packages..."
pkg update -y || true

echo "[bootstrap] Ensuring core tools..."
# Termux uses gawk (not 'awk' package)
pkg install -y git python coreutils grep sed gawk || true

ensure_line() {
  local line="$1" file="$2"
  touch "$file"
  grep -qxF "$line" "$file" 2>/dev/null || echo "$line" >> "$file"
}

# PATH lines (idempotent)
ensure_line 'export PATH="$HOME/qt/bin:$PATH"' "$HOME/.bashrc"
ensure_line 'export PATH="$HOME/.local/bin:$PATH"' "$HOME/.bashrc"

# Reload PATH for current session
# shellcheck disable=SC1090
source "$HOME/.bashrc" || true

echo "[bootstrap] Installing pytest (user)..."
python -m pip install --user -U pytest >/dev/null

echo "[bootstrap] Installing bats-core locally (no apt)..."
mkdir -p "$HOME/.local/src"
if [ ! -d "$HOME/.local/src/bats-core" ]; then
  git clone --depth 1 https://github.com/bats-core/bats-core.git "$HOME/.local/src/bats-core"
fi
cd "$HOME/.local/src/bats-core"
./install.sh "$HOME/.local" >/dev/null

echo "[bootstrap] Verifying tools..."
command -v pytest >/dev/null && pytest --version
command -v bats  >/dev/null && bats --version

echo "[bootstrap] Done. Restart Termux (or run: exec -l bash)."
