.PHONY: test test-bats test-py

test: test-bats test-py

test-bats:
	bats tests/*.bats

test-py:
	pytest -q

# Append release notes to RELEASE.md (bottom of file).
# Usage:
#   make release VERSION=1.3.5
# Then paste the release body, end with Ctrl-D.

# Append release notes to RELEASE.md (bottom of file).
# Usage:
#   make release VERSION=1.3.5
# Then paste the release body, end with Ctrl-D.
#
# Guard:
#   Versions with major>=9 are blocked unless ALLOW_TEST_RELEASE=1
#   Example override: ALLOW_TEST_RELEASE=1 make release VERSION=9.9.9
release:
	@if [ -z "$(VERSION)" ]; then echo "ERROR: VERSION is required (e.g., make release VERSION=1.3.5)"; exit 2; fi
	@echo "Paste RELEASE body now (end with Ctrl-D)."
	@ALLOW_TEST_RELEASE="$${ALLOW_TEST_RELEASE:-0}" ./bin/release_append.sh --version "$(VERSION)"

# Dry-run release output (does not write to RELEASE.md).
# Usage:
#   make release-dry VERSION=1.3.5
release-dry:
	@if [ -z "$(VERSION)" ]; then echo "ERROR: VERSION is required (e.g., make release-dry VERSION=1.3.5)"; exit 2; fi
	@echo "Paste RELEASE body now (end with Ctrl-D)."
	@ALLOW_TEST_RELEASE="$${ALLOW_TEST_RELEASE:-0}" ./bin/release_append.sh --dry-run --version "$(VERSION)"

