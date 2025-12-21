.PHONY: test test-bats test-py

test: test-bats test-py

test-bats:
bats tests/*.bats

test-py:
pytest -q
