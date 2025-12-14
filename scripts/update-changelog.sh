#!/usr/bin/env bash
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

OUT="CHANGELOG.md"
TZ_NAME="${TZ_NAME:-America/Toronto}"

{
  echo "# CHANGELOG"
  echo
  echo "Generated: $(TZ="$TZ_NAME" date '+%Y-%m-%d %H%M %Z')"
  echo

  ROOT="$(git rev-list --max-parents=0 HEAD | tail -n 1)"

  # Tags (prefer v*), ascending so we can build clean ranges.
  mapfile -t TAGS < <(git tag --list 'v*' --sort=v:refname)

  if (( ${#TAGS[@]} > 0 )); then
    LATEST_TAG="${TAGS[-1]}"

    echo "## Unreleased (since ${LATEST_TAG})"
    git log "${LATEST_TAG}..HEAD" --date=short --pretty=format:"- %ad %h %s" || true
    echo
    echo

    for (( i=${#TAGS[@]}-1; i>=0; i-- )); do
      TAG="${TAGS[$i]}"
      if (( i==0 )); then
        RANGE="${ROOT}..${TAG}"
      else
        PREV="${TAGS[$((i-1))]}"
        RANGE="${PREV}..${TAG}"
      fi

      echo "## ${TAG}"
      git log "${RANGE}" --date=short --pretty=format:"- %ad %h %s" || true
      echo
      echo
    done
  else
    echo "## Unreleased"
    git log --date=short --pretty=format:"- %ad %h %s"
    echo
  fi
} > "$OUT"

echo "Wrote $OUT"
