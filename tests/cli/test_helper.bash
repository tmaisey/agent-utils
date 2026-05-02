#!/usr/bin/env bash
# Shared bats setup loaded from each .bats file.
# Vendored helpers live in tests/cli/helpers/ (bats-support, bats-assert).

# shellcheck disable=SC2034
TESTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$TESTS_DIR/../.." && pwd)"
GWT_SH="$REPO_ROOT/managing-git-worktrees/bin/gwt.sh"
SECURITY_AUDIT="$REPO_ROOT/analysing-security/bin/security-audit"

load "$TESTS_DIR/helpers/bats-support/load"
load "$TESTS_DIR/helpers/bats-assert/load"
