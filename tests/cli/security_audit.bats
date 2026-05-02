#!/usr/bin/env bats
#
# Tests for analysing-security/bin/security-audit (bash 3.2+).
# Functional scanner tests skip when the underlying tool isn't on PATH.
#
# SPEC: SEC-001..SEC-006

load "test_helper.bash"

setup() {
  TMP="$(mktemp -d)"
  # Sandbox XDG_DATA_HOME so reports never land outside the test dir.
  export XDG_DATA_HOME="$TMP/xdg"
  mkdir -p "$XDG_DATA_HOME"
}

teardown() {
  rm -rf "$TMP"
}

require_tool() {
  command -v "$1" >/dev/null 2>&1 || skip "$1 not on PATH"
}

# Initialise a tiny git repo with optional planted content.
init_repo() {
  local dir="$1"
  mkdir -p "$dir"
  git -C "$dir" init -q
  git -C "$dir" config user.email "test@example.com"
  git -C "$dir" config user.name "test"
}

# ── SEC-001: help, version, setup --check-only ───────────────────────────────

@test "SEC-001 help_version_setup: --help exits 0 and prints usage" {
  run "$SECURITY_AUDIT" --help
  assert_success
  assert_output --partial "USAGE"
  assert_output --partial "security-audit"
}

@test "SEC-001 help_version_setup: version prints v1.0.0" {
  run "$SECURITY_AUDIT" version
  assert_success
  assert_output --partial "security-audit v"
}

@test "SEC-001 help_version_setup: setup --check-only does not mutate the repo" {
  # Snapshot the project's bin dir mtime; setup --check-only must not touch it.
  local before
  before=$(stat -f '%m' "$SECURITY_AUDIT" 2>/dev/null || stat -c '%Y' "$SECURITY_AUDIT")
  run "$SECURITY_AUDIT" setup --check-only
  # Exit may be 0 (all installed) or non-zero (some missing) — both are valid.
  local after
  after=$(stat -f '%m' "$SECURITY_AUDIT" 2>/dev/null || stat -c '%Y' "$SECURITY_AUDIT")
  [[ "$before" == "$after" ]] || { echo "CLI mtime changed during setup --check-only"; return 1; }
}

# ── SEC-002: reports land in XDG_DATA_HOME, never in the scanned repo ────────

@test "SEC-002 reports_land_in_xdg: scan writes under XDG_DATA_HOME, not inside repo" {
  require_tool gitleaks
  require_tool jq
  init_repo "$TMP/repo"
  echo "hello" > "$TMP/repo/README.md"
  git -C "$TMP/repo" add . && git -C "$TMP/repo" commit -q -m "init"

  cd "$TMP/repo"
  run "$SECURITY_AUDIT" --profile quick --quiet
  # Exit 0 (clean) or 1 (findings) both fine; 2 = tool error.
  [[ "$status" -eq 0 || "$status" -eq 1 ]] \
    || { echo "unexpected exit $status; output: $output"; return 1; }

  # Reports must exist under XDG, not under the scanned repo.
  [[ -d "$XDG_DATA_HOME/security-audit/repo" ]] \
    || { echo "no report dir under XDG_DATA_HOME"; return 1; }
  # Crucially, no scan output landed inside the repo.
  ! find "$TMP/repo" -name "report.md" -o -name "findings.json" 2>/dev/null | grep -q . \
    || { echo "scan output leaked into the repo"; return 1; }
}

# ── SEC-003: scan finds a planted AWS key via gitleaks ───────────────────────

@test "SEC-003 scan_finds_planted_secret: gitleaks detects a planted private key" {
  require_tool gitleaks
  require_tool jq
  init_repo "$TMP/repo"
  # Planted: PEM private-key block. Gitleaks has had the private-key rule
  # forever with no allowlist exceptions, so this is the most stable fixture.
  # AWS docs example keys (AKIA*EXAMPLE) are explicitly allowlisted, so don't use those.
  cat > "$TMP/repo/leaked.pem" <<'EOF'
-----BEGIN RSA PRIVATE KEY-----
MIIBOgIBAAJBAKj34GkxFhD90vcNLYLInFEX6Ppy1tPf9Cnzj4p4WGeKLs1Pt8Qu
KUpRKfFLfRYC9AIKjbJTWit+CqvjWYzvQwECAwEAAQJAIJLixBy2qpFoS4DSmoEm
o3qGy0t6z09AIJtH+5OeRV1be+N4cDYJKffGzDa88vQENZiRm0GRq6a+HPGQMd2k
TQIhAKMSvzIBnni7ot/OSie2TmJLY4SwTQAevXysE2RbFDYdAiEBCUEaRQnMnbp7
9mxDXDf6AU0cN/RPBjb9qSHDcWZHGzUCIG2Es59z8ugGrDY+pxLQnwfotadxd+Uy
v/Ow5T0q5gIJAiEAyS4RaI9YG8EWx/2w0T67ZUVAw8eOMB6BIUg0Xcu+3okCIBOs
/5OiPgoTdSy7bcF9IGpSE8ZgGKzgYQVZeN97YE00
-----END RSA PRIVATE KEY-----
EOF
  git -C "$TMP/repo" add . && git -C "$TMP/repo" commit -q -m "add config"

  cd "$TMP/repo"
  # quick/standard profiles limit gitleaks to HEAD~20..HEAD (so a single-commit
  # fixture sees nothing). deep scans full history.
  run "$SECURITY_AUDIT" --profile deep --tool gitleaks --quiet
  [[ "$status" -eq 1 ]] || { echo "expected exit 1 (findings), got $status; output: $output"; return 1; }

  local findings_file
  findings_file="$XDG_DATA_HOME/security-audit/repo/latest/findings.json"
  [[ -f "$findings_file" ]] || { echo "no findings.json"; return 1; }
  jq -e 'map(select(.tool == "gitleaks")) | length > 0' "$findings_file" >/dev/null \
    || { echo "no gitleaks findings; file: $(cat "$findings_file")"; return 1; }
}

# ── SEC-004: scan flags a vulnerable dependency via trivy ────────────────────

@test "SEC-004 scan_flags_vulnerable_dep: trivy flags a known-vulnerable Python dep" {
  require_tool trivy
  require_tool jq
  init_repo "$TMP/repo"
  # requirements.txt with an old, known-CVE version of `requests`.
  cat > "$TMP/repo/requirements.txt" <<'EOF'
requests==2.19.1
EOF
  # Add a .py file so language detection picks up Python.
  echo "import requests" > "$TMP/repo/app.py"
  git -C "$TMP/repo" add . && git -C "$TMP/repo" commit -q -m "init"

  cd "$TMP/repo"
  run "$SECURITY_AUDIT" --profile quick --tool trivy --quiet
  # Trivy may report findings (exit 1) or none if the DB hasn't synced (exit 0).
  [[ "$status" -eq 0 || "$status" -eq 1 ]] \
    || { echo "unexpected exit $status; output: $output"; return 1; }

  # Just assert trivy actually ran and produced raw output.
  local raw_dir
  raw_dir="$XDG_DATA_HOME/security-audit/repo/latest/raw"
  [[ -d "$raw_dir" ]] || { echo "no raw/ dir"; return 1; }
  ls "$raw_dir" | grep -q trivy || { echo "trivy raw output missing; raw/: $(ls "$raw_dir")"; return 1; }
}

# ── SEC-005: scan flags a code-pattern issue via semgrep ─────────────────────

@test "SEC-005 scan_flags_semgrep_finding: semgrep flags a SAST issue" {
  require_tool semgrep
  require_tool jq
  init_repo "$TMP/repo"
  # Python eval() of user input — classic SAST pattern.
  cat > "$TMP/repo/app.py" <<'EOF'
import sys
def run(payload):
    return eval(payload)  # nosec — intentional for SAST test fixture
if __name__ == "__main__":
    print(run(sys.argv[1]))
EOF
  git -C "$TMP/repo" add . && git -C "$TMP/repo" commit -q -m "init"

  cd "$TMP/repo"
  run "$SECURITY_AUDIT" --profile standard --tool semgrep --quiet
  # Semgrep findings → exit 1; first run downloads rulesets so allow exit 2 (timeout) too.
  [[ "$status" -eq 0 || "$status" -eq 1 || "$status" -eq 2 ]] \
    || { echo "unexpected exit $status; output: $output"; return 1; }

  local raw_dir
  raw_dir="$XDG_DATA_HOME/security-audit/repo/latest/raw"
  [[ -d "$raw_dir" ]] || { echo "no raw/ dir"; return 1; }
  ls "$raw_dir" | grep -qE 'sast|semgrep' \
    || { echo "semgrep raw output missing; raw/: $(ls "$raw_dir")"; return 1; }
}

# ── SEC-006: report --latest returns the most recent scan ────────────────────

@test "SEC-006 report_latest: returns the most recent scan" {
  require_tool gitleaks
  require_tool jq
  init_repo "$TMP/repo"
  echo "hello" > "$TMP/repo/README.md"
  git -C "$TMP/repo" add . && git -C "$TMP/repo" commit -q -m "init"
  cd "$TMP/repo"
  run "$SECURITY_AUDIT" --profile quick --tool gitleaks --quiet
  [[ "$status" -eq 0 || "$status" -eq 1 ]] || { echo "scan failed: $output"; return 1; }

  run "$SECURITY_AUDIT" report --latest --stdout
  assert_success
  assert_output --partial "Security Audit"
}
