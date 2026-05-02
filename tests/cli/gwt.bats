#!/usr/bin/env bats
#
# Tests for managing-git-worktrees/bin/gwt.sh (zsh).
# Bats runs in bash; we invoke gwt.sh via `zsh -c "source gwt.sh; ..."`.
#
# SPEC: GWT-001..GWT-005

load "test_helper.bash"

setup() {
  TMP="$(mktemp -d)"
}

teardown() {
  rm -rf "$TMP"
}

# Run a snippet inside a fresh zsh that has gwt.sh sourced.
# Usage: run_in_zsh '<zsh code>'
run_in_zsh() {
  run zsh -c "source '$GWT_SH'; $1"
}

# ── GWT-001: __gwt_sanitize_name ─────────────────────────────────────────────

@test "GWT-001 sanitize_name: lowercases and replaces / with -" {
  run_in_zsh '__gwt_sanitize_name "feat/Foo"'
  assert_success
  assert_output "feat-foo"
}

@test "GWT-001 sanitize_name: replaces _ with -" {
  run_in_zsh '__gwt_sanitize_name "FOO_BAR_BAZ"'
  assert_success
  assert_output "foo-bar-baz"
}

@test "GWT-001 sanitize_name: strips leading and trailing hyphens" {
  run_in_zsh '__gwt_sanitize_name "-leading-trailing-"'
  assert_success
  assert_output "leading-trailing"
}

@test "GWT-001 sanitize_name: truncates to 50 chars" {
  # 60-char input; expect 50-char output.
  local input
  input="$(printf 'a%.0s' {1..60})"
  run_in_zsh "__gwt_sanitize_name '$input'"
  assert_success
  [[ ${#output} -eq 50 ]] || { echo "got len=${#output}, want 50"; return 1; }
}

# ── GWT-002: __gwt_discover_ports ────────────────────────────────────────────

@test "GWT-002 discover_ports: parses \${*_PORT} vars in order" {
  cat > "$TMP/.env.template" <<'EOF'
APP_PORT=${APP_PORT}
DB_PORT=${DB_PORT}
CACHE_PORT=${CACHE_PORT}
EOF
  run_in_zsh "__gwt_discover_ports '$TMP/.env.template'"
  assert_success
  assert_line --index 0 "APP_PORT"
  assert_line --index 1 "DB_PORT"
  assert_line --index 2 "CACHE_PORT"
}

@test "GWT-002 discover_ports: dedupes repeated PORT vars" {
  cat > "$TMP/.env.template" <<'EOF'
APP_PORT=${APP_PORT}
DB_PORT=${DB_PORT}
APP_HEALTHCHECK_URL=http://host:${APP_PORT}/health
EOF
  run_in_zsh "__gwt_discover_ports '$TMP/.env.template'"
  assert_success
  # APP_PORT once, DB_PORT once.
  [[ "$(echo "$output" | wc -l | tr -d ' ')" -eq 2 ]] \
    || { echo "expected 2 unique vars, got: $output"; return 1; }
}

@test "GWT-002 discover_ports: missing template returns nonzero" {
  run_in_zsh "__gwt_discover_ports '$TMP/does-not-exist'"
  assert_failure
}

# ── GWT-003: port allocation (first-fit from 40000) ──────────────────────────

@test "GWT-003 port_allocation: first allocation starts at 40000" {
  # Bare git repo so `git worktree list --porcelain` returns just the main worktree.
  git -C "$TMP" init -q
  git -C "$TMP" commit -q --allow-empty -m init
  run_in_zsh "__gwt_find_port_range '$TMP' 5"
  assert_success
  assert_output "40000"
}

@test "GWT-003 port_allocation: first-fit picks gap before existing allocation" {
  git -C "$TMP" init -q
  git -C "$TMP" commit -q --allow-empty -m init
  # Plant a .gwt_index in the main worktree at 40010, block size 5.
  echo "40010 5" > "$TMP/.gwt_index"
  # Need 3 ports — 40000..40002 fits before the 40010 allocation.
  run_in_zsh "__gwt_find_port_range '$TMP' 3"
  assert_success
  assert_output "40000"
}

@test "GWT-003 port_allocation: when first gap too small, picks after allocation" {
  git -C "$TMP" init -q
  git -C "$TMP" commit -q --allow-empty -m init
  # Plant a .gwt_index allocation at 40002 (only a 2-port gap before it).
  echo "40002 5" > "$TMP/.gwt_index"
  # Need 5 ports — 40000..40004 won't fit (collides at 40002), so picks 40007.
  run_in_zsh "__gwt_find_port_range '$TMP' 5"
  assert_success
  assert_output "40007"
}

# ── GWT-004: gwt ports reports the assignment ────────────────────────────────

@test "GWT-004 gwt_ports_reports_assignment: prints var=port lines" {
  cat > "$TMP/.env.template" <<'EOF'
APP_PORT=${APP_PORT}
DB_PORT=${DB_PORT}
EOF
  echo "40050 2" > "$TMP/.gwt_index"
  run_in_zsh "__gwt_print_ports '$TMP/.gwt_index' '$TMP/.env.template'"
  assert_success
  assert_output --partial "APP_PORT"
  assert_output --partial "40050"
  assert_output --partial "DB_PORT"
  assert_output --partial "40051"
}

@test "GWT-004 gwt_ports_reports_assignment: missing .gwt_index returns nonzero" {
  run_in_zsh "__gwt_print_ports '$TMP/missing' '$TMP/missing'"
  assert_failure
  assert_output --partial "No port allocation found"
}

# ── GWT-005: misuse exits non-zero with a clear message ──────────────────────

@test "GWT-005 misuse_exits_nonzero: gwt with no args prints help and exits non-zero" {
  # Force into a tmp dir so we don't accidentally run inside this repo.
  cd "$TMP"
  git init -q
  git commit -q --allow-empty -m init
  run_in_zsh "gwt"
  assert_failure
  assert_output --partial "Usage:"
}

@test "GWT-005 misuse_exits_nonzero: gwt cleanup with no branch exits non-zero" {
  cd "$TMP"
  git init -q
  git commit -q --allow-empty -m init
  run_in_zsh "gwt cleanup"
  assert_failure
  assert_output --partial "Usage: gwt cleanup"
}
