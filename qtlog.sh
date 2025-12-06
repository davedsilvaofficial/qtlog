#!/usr/bin/env bash
# qtlog.sh - Quantum Trek log helper
# Version: 1.2.0

set -uo pipefail

QTLOG_VERSION="1.2.0"

#######################################
# Utility helpers
#######################################

bool_is_true() {
  case "${1:-}" in
    [Tt][Rr][Uu][Ee]|[Yy][Ee][Ss]|[Yy]|1)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

script_dir() {
  local src="${BASH_SOURCE[0]:-$0}"
  while [ -h "$src" ]; do
    local dir
    dir="$(cd -P "$(dirname "$src")" >/dev/null 2>&1 && pwd)"
    src="$(readlink "$src")"
    [[ $src != /* ]] && src="$dir/$src"
  done
  cd -P "$(dirname "$src")" >/dev/null 2>&1 && pwd
}

detect_device() {
  # If user explicitly set a device label, respect it
  if [ -n "${QTLOG_DEVICE:-}" ] && [ "${QTLOG_DEVICE}" != "auto" ]; then
    echo "${QTLOG_DEVICE}"
    return 0
  fi

  # Android / Termux model name
  if command -v getprop >/dev/null 2>&1; then
    local model
    model="$(getprop ro.product.model 2>/dev/null | tr -d '\r')"
    if [ -n "$model" ]; then
      echo "$model"
      return 0
    fi
  fi

  # Fallback to hostname
  if command -v hostname >/dev/null 2>&1; then
    local hn
    hn="$(hostname 2>/dev/null | tr -d '\r')"
    if [ -n "$hn" ]; then
      echo "$hn"
      return 0
    fi
  fi

  echo "device"
}

#######################################
# Git helpers
#######################################

safe_git_pull() {
  if ! bool_is_true "${QTLOG_AUTO_PULL:-true}"; then
    return 0
  fi

  if ! command -v git >/dev/null 2>&1; then
    echo "qtlog: git not available; skipping pull" >&2
    return 0
  fi

  if [ ! -d ".git" ]; then
    echo "qtlog: not a git repo; skipping pull" >&2
    return 0
  fi

  local status
  status="$(git status --porcelain 2>/dev/null || echo "__ERR__")"

  if [ "$status" = "__ERR__" ]; then
    echo "qtlog: git status failed; skipping pull" >&2
    return 1
  fi

  # Clean working tree
  if [ -z "$status" ]; then
    if ! git pull --ff-only; then
      echo "qtlog: git pull failed; continuing with local copy only" >&2
      return 1
    fi
    return 0
  fi

  # Dirty working tree -> stash, pull, un-stash
  echo "qtlog: local changes detected; attempting safe pull with stash" >&2

  if ! git stash push -u -k -m "qtlog auto-stash before pull" >/dev/null 2>&1; then
    echo "qtlog: git stash failed; skipping pull" >&2
    return 1
  fi

  if git pull --ff-only; then
    if ! git stash pop >/dev/null 2>&1; then
      echo "qtlog: warning: stash pop had conflicts; please resolve manually" >&2
    fi
    return 0
  else
    echo "qtlog: git pull failed; restoring stash and continuing with local copy only" >&2
    git stash pop >/dev/null 2>&1 || true
    return 1
  fi
}

git_commit_and_push_log() {
  if ! bool_is_true "${QTLOG_AUTO_PUSH:-true}"; then
    return 0
  fi

  if ! command -v git >/dev/null 2>&1; then
    echo "qtlog: git not available; skipping push" >&2
    return 0
  fi

  if [ ! -d ".git" ]; then
    echo "qtlog: not a git repo; skipping push" >&2
    return 0
  fi

  local logfile="$1"
  local entry="$2"

  # Stage only the log file
  if ! git add "$logfile" 2>/dev/null; then
    echo "qtlog: git add failed for $logfile; skipping push" >&2
    return 1
  fi

  # Commit; ignore "nothing to commit" errors
  if ! git commit -m "$entry" >/dev/null 2>&1; then
    # Probably nothing to commit
    return 0
  fi

  if ! git push; then
    echo "qtlog: git push failed; logs are only local right now" >&2
    return 1
  fi

  return 0
}

#######################################
# Mode handlers
#######################################

show_version() {
  local repo_root="$1"
  echo "qtlog version: $QTLOG_VERSION"
  echo "repo: $repo_root"
  echo "log_dir: ${QTLOG_LOG_DIR}"
  echo "device: $(detect_device)"
  echo "timestamp_format: ${QTLOG_TIMESTAMP_FORMAT}"
  echo "auto_pull: ${QTLOG_AUTO_PULL:-true}"
  echo "auto_push: ${QTLOG_AUTO_PUSH:-true}"
}

run_doctor() {
  local repo_root="$1"
  local ok=0

  echo "qtlog doctor (v${QTLOG_VERSION})"
  echo "repo: $repo_root"
  echo

  if [ -d "$repo_root" ]; then
    echo "[OK] repo directory exists: $repo_root"
  else
    echo "[ERR] repo directory missing: $repo_root"
    ok=1
  fi

  if [ -f "$repo_root/.qtlog_env" ]; then
    echo "[OK] .qtlog_env found"
  else
    echo "[WARN] .qtlog_env not found (using defaults)"
  fi

  if mkdir -p "${QTLOG_LOG_DIR}" 2>/dev/null; then
    echo "[OK] log directory: ${QTLOG_LOG_DIR}"
  else
    echo "[ERR] cannot create/access log directory: ${QTLOG_LOG_DIR}"
    ok=1
  fi

  if command -v git >/dev/null 2>&1; then
    echo "[OK] git is installed"
  else
    echo "[ERR] git is not installed"
    ok=1
  fi

  if [ -d "$repo_root/.git" ] && command -v git >/dev/null 2>&1; then
    if git -C "$repo_root" status >/dev/null 2>&1; then
      echo "[OK] git status succeeded"
    else
      echo "[ERR] git status failed"
      ok=1
    fi
  else
    echo "[WARN] not a git repo or git missing; skipping git checks"
  fi

  echo
  if [ "$ok" -eq 0 ]; then
    echo "Doctor: all essential checks passed."
  else
    echo "Doctor: some checks FAILED. Please review messages above."
  fi

  return "$ok"
}

#######################################
# Main
#######################################

main() {
  local repo_root
  repo_root="$(script_dir)"
  cd "$repo_root"

  # Attempt to load local environment, if present
  if [ -f ".qtlog_env" ]; then
    # shellcheck disable=SC1091
    . ".qtlog_env"
  fi

  # Defaults
  QTLOG_LOG_DIR="${QTLOG_LOG_DIR:-"$repo_root/Log"}"
  QTLOG_TIMESTAMP_FORMAT="${QTLOG_TIMESTAMP_FORMAT:-"%Y-%m-%d %H%M %Z"}"
  QTLOG_AUTO_PULL="${QTLOG_AUTO_PULL:-true}"
  QTLOG_AUTO_PUSH="${QTLOG_AUTO_PUSH:-true}"

  local cmd="${1:-}"

  case "$cmd" in
    --version|-V)
      show_version "$repo_root"
      exit 0
      ;;
    --doctor)
      run_doctor "$repo_root"
      exit $?
      ;;
  esac

  if [ "$#" -eq 0 ]; then
    echo "Usage: $0 [--version|--doctor|message...]" >&2
    exit 1
  fi

  # Normal log mode
  shift 0
  local message="$*"
  local device timestamp entry logfile today

  device="$(detect_device)"
  timestamp="$(date +"${QTLOG_TIMESTAMP_FORMAT}")"
  entry="[$device] $timestamp $message"

  # Ensure log dir
  mkdir -p "${QTLOG_LOG_DIR}"

  today="$(date +%Y-%m-%d)"
  logfile="${QTLOG_LOG_DIR}/${today}.log"

  # Safe sync before writing
  safe_git_pull || true

  # Append log entry
  echo "$entry" >> "$logfile"

  echo "qtlog: created entry '$entry' under ${logfile}"

  # Commit + push (optional)
  git_commit_and_push_log "$logfile" "$entry" || true
}

main "$@"
