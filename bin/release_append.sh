#!/usr/bin/env bash
set -euo pipefail

# release_append.sh
# Appends a new RELEASE.md section at the bottom:
#   ## vX.Y.Z — YYYY-MM-DD
# then the markdown piped on stdin (e.g., "### Fixed ...").
#
# Enforces:
# - version must be unique (not already present)
# - version must be > last version in RELEASE.md (semver compare)
# - date must be >= last date in RELEASE.md (YYYY-MM-DD string compare)
# - Guard: blocks test-y major versions (>=9) unless ALLOW_TEST_RELEASE=1

usage() {
  cat <<'EOF'
Usage:
  cat <<'MD' | ./bin/release_append.sh --version 1.3.5
  ### Fixed
  - ...
  MD

Options:
  --version X.Y.Z    (required)
  --date YYYY-MM-DD  (optional; defaults to today in America/Toronto)
  --file PATH        (optional; defaults to RELEASE.md)
  --dry-run          (optional; validate + print section; do not write)

Env:
  ALLOW_TEST_RELEASE=1  Allow major>=9 versions (e.g., 9.9.9) for smoke tests.
EOF
}

FILE="RELEASE.md"
VERSION=""
DATE="$(TZ=America/Toronto date +%Y-%m-%d)"
DRY_RUN=0

while [ $# -gt 0 ]; do
  case "$1" in
    --version) VERSION="${2:-}"; shift 2 ;;
    --date)    DATE="${2:-}"; shift 2 ;;
    --file)    FILE="${2:-}"; shift 2 ;;
    --dry-run) DRY_RUN=1; shift 1 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "release_append: unknown arg: $1" >&2; usage; exit 2 ;;
  esac
done

if [ -z "$VERSION" ]; then
  echo "release_append: --version is required" >&2
  exit 2
fi

if ! [[ "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "release_append: version must be X.Y.Z (got: $VERSION)" >&2
  exit 2
fi

if ! [[ "$DATE" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
  echo "release_append: date must be YYYY-MM-DD (got: $DATE)" >&2
  exit 2
fi

# Guard: block major>=9 unless explicitly allowed
major="${VERSION%%.*}"
if [ "$major" -ge 9 ] && [ "${ALLOW_TEST_RELEASE:-0}" != "1" ]; then
  echo "release_append: REFUSING test version v$VERSION (major>=9). Set ALLOW_TEST_RELEASE=1 to override." >&2
  exit 7
fi

# Ensure file exists
touch "$FILE"

# Unique version check
if grep -qE "^##[[:space:]]+v${VERSION}[[:space:]]+—[[:space:]]+[0-9]{4}-[0-9]{2}-[0-9]{2}[[:space:]]*$" "$FILE"; then
  echo "release_append: version v$VERSION already exists in $FILE" >&2
  exit 3
fi

# Find last release header in file (chronological base)
last_line="$(
  grep -nE "^##[[:space:]]+v[0-9]+\.[0-9]+\.[0-9]+[[:space:]]+—[[:space:]]+[0-9]{4}-[0-9]{2}-[0-9]{2}[[:space:]]*$" "$FILE" \
  | tail -n 1 || true
)"

last_ver=""
last_date=""

if [ -n "$last_line" ]; then
  last_hdr="${last_line#*:}"
  last_ver="$(printf '%s' "$last_hdr" | sed -E 's/^##[[:space:]]+v([0-9]+\.[0-9]+\.[0-9]+)[[:space:]]+—[[:space:]]+([0-9]{4}-[0-9]{2}-[0-9]{2}).*$/\1/')"
  last_date="$(printf '%s' "$last_hdr" | sed -E 's/^##[[:space:]]+v([0-9]+\.[0-9]+\.[0-9]+)[[:space:]]+—[[:space:]]+([0-9]{4}-[0-9]{2}-[0-9]{2}).*$/\2/')"
fi

semver_gt() {
  # returns 0 if $1 > $2
  local a="$1" b="$2"
  local a1 a2 a3 b1 b2 b3
  IFS='.' read -r a1 a2 a3 <<<"$a"
  IFS='.' read -r b1 b2 b3 <<<"$b"
  if [ "$a1" -ne "$b1" ]; then [ "$a1" -gt "$b1" ]; return; fi
  if [ "$a2" -ne "$b2" ]; then [ "$a2" -gt "$b2" ]; return; fi
  [ "$a3" -gt "$b3" ]
}

if [ -n "$last_ver" ]; then
  if ! semver_gt "$VERSION" "$last_ver"; then
    echo "release_append: version must be > last version ($last_ver). Got: $VERSION" >&2
    exit 4
  fi
fi

if [ -n "$last_date" ]; then
  # YYYY-MM-DD lexical compare works
  if [[ "$DATE" < "$last_date" ]]; then
    echo "release_append: date must be >= last date ($last_date). Got: $DATE" >&2
    exit 5
  fi
fi

body="$(cat)"

# Require some content (prevents empty accidental releases)
if [ -z "$(printf '%s' "$body" | tr -d '[:space:]')" ]; then
  echo "release_append: stdin body is empty; refusing to write release entry" >&2
  exit 6
fi

section="$(printf "\n## v%s — %s\n\n%s\n" "$VERSION" "$DATE" "$body")"

if [ "$DRY_RUN" -eq 1 ]; then
  printf "%s" "$section"
  echo "OK: dry-run validated v$VERSION — $DATE (no write)"
  exit 0
fi

# Append at bottom
printf "%s" "$section" >> "$FILE"
echo "OK: appended v$VERSION — $DATE to $FILE"
