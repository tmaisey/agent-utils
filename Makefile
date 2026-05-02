.PHONY: test test-cli test-content rubrics-list

test: test-cli test-content

test-cli:
	@command -v bats >/dev/null || { echo "bats not installed (brew install bats-core bats-assert bats-support)"; exit 1; }
	bats tests/cli

test-content:
	uv run pytest tests/content

rubrics-list:
	@ls tests/rubrics/*.md 2>/dev/null || echo "no rubrics yet"
