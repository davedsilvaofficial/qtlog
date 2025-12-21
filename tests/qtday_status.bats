#!/usr/bin/env bats

setup() {
  export TEST_HOME
  TEST_HOME="$(mktemp -d)"

  export HOME="$TEST_HOME"
  mkdir -p "$HOME/.config/qt"
  mkdir -p "$HOME/qt/bin"
  mkdir -p "$BATS_TEST_TMPDIR/tmp"

  # Put qtday in PATH
  export PATH="$HOME/qt/bin:$PATH"

  # Copy repo qtday into fake HOME
  cp -a "./qt/bin/qtday" "$HOME/qt/bin/qtday"
  chmod +x "$HOME/qt/bin/qtday"

  # Override files so tests never touch real Termux paths
  export QTDAY_SESS_FILE="$BATS_TEST_TMPDIR/tmp/qtday.session"
  export QTDAY_STAMP_FILE="$HOME/.config/qt/qtday.last"
  export QTDAY_REPO_DIR="$BATS_TEST_TMPDIR/fake_repo"
  export QTDAY_ENV_FILE="$BATS_TEST_TMPDIR/fake_env"
  export QTDAY_TZ="America/Toronto"

  mkdir -p "$QTDAY_REPO_DIR"
  # Minimal fake env file (not used by --status tests)
  : > "$QTDAY_ENV_FILE"
}

teardown() {
  rm -rf "$TEST_HOME"
}

@test "qtday --status prints required fields" {
  echo "2099-01-01" > "$QTDAY_STAMP_FILE"

  run qtday --status
  [ "$status" -eq 0 ]

  [[ "$output" == *"qtday status"* ]]
  [[ "$output" == *"today:"* ]]
  [[ "$output" == *"qtday.last:"* ]]
  [[ "$output" == *"session marker:"* ]]
  [[ "$output" == *"decision:"* ]]
}

@test "qtday --status reports session marker present and correct decision" {
  : > "$QTDAY_SESS_FILE"
  echo "2099-01-01" > "$QTDAY_STAMP_FILE"

  run qtday --status
  [ "$status" -eq 0 ]

  [[ "$output" == *"session marker:  present"* ]]
  [[ "$output" == *"decision:        skip - already ran this session"* ]]
}
