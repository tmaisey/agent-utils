# Tool Catalog

Reference for all CLI tools used by the secure-design skill. Each entry covers invocation, output parsing, severity mapping, and timeouts.

## Auto-Detection

Run tools only when their language indicators are present:

| Indicator files | Tools to run |
|---|---|
| `*.py` + active venv (`$VIRTUAL_ENV` or `.venv/`) | bandit, pip-audit |
| `*.py` + no venv | bandit, trivy (covers Python deps via manifests) |
| `package.json`, `package-lock.json`, `*.js`, `*.ts` | npm audit |
| `*.sh`, `*.bash`, `*.zsh` | shellcheck |
| `Dockerfile*`, `docker-compose*.yml` | hadolint, trivy (image mode) |
| `*.tf`, `*.tfvars` | checkov |
| `go.mod` | govulncheck |
| `Cargo.toml`, `Cargo.lock` | cargo audit |
| `Gemfile`, `Gemfile.lock` | bundler-audit |
| _(always)_ | gitleaks |
| _(standard/deep)_ | semgrep |

---

## 1. gitleaks — Secrets Detection

**What it checks**: Hardcoded secrets, API keys, tokens, passwords in code and git history.

**Invocation — staged/recent commits (quick/standard)**:
```bash
gitleaks detect --source . --no-banner --report-format json --report-path /dev/stdout \
  --log-opts="HEAD~20..HEAD" 2>/dev/null
```

**Invocation — full git history (deep)**:
```bash
gitleaks detect --source . --no-banner --report-format json --report-path /dev/stdout 2>/dev/null
```

**Output format**: JSON array of finding objects.

**Parse fields**:
- `RuleID` — rule that triggered (e.g., `generic-api-key`)
- `File` — file path
- `StartLine` — line number
- `Secret` — the matched secret (redact in reports — show first/last 3 chars)
- `Commit` — commit SHA (for history scans)

**Severity mapping**:
| gitleaks rule category | Mapped severity |
|---|---|
| All findings | **High** (secrets are always high) |

**Exit codes**: 0 = clean, 1 = findings, other = error.

**Timeout**: 60s (quick/standard), 300s (deep/full history).

**Alternative — trufflehog**: `trufflehog git file://. --json` provides similar functionality with verified-secret detection (checks if secrets are still active). Not required but noted as an alternative. Install via `brew install trufflehog`.

---

## 2. pip-audit — Python Dependency Vulnerabilities

**What it checks**: Known CVEs in installed Python packages (Python Advisory Database).

**Compatibility**: Not yet compatible with Python 3.14. Requires Python ≤3.13.

**When to run**: Only when a virtualenv is detected:
- `$VIRTUAL_ENV` environment variable is set, OR
- `.venv/` or `venv/` directory exists in the repository root

When no venv is present, trivy (section 4) covers Python dependency
scanning via requirements.txt / pyproject.toml / poetry.lock.

**Invocation**:
```bash
pip-audit --format=json --desc 2>/dev/null
# Or for a specific requirements file:
pip-audit -r requirements.txt --format=json --desc 2>/dev/null
```

**Parse fields**:
- `name` — package name
- `version` — installed version
- `vulns[].id` — CVE/PYSEC identifier
- `vulns[].fix_versions` — versions that fix the issue
- `vulns[].description` — vulnerability description

**Severity mapping**:
| Condition | Mapped severity |
|---|---|
| CVE with fix available | **High** |
| CVE without fix | **Medium** |

Note: pip-audit's JSON output does not include exploit-availability data, so the
CLI cannot distinguish "known exploit" from other CVEs. Use trivy or manual
review for exploit intelligence.

**Exit codes**: 0 = clean, 1 = vulnerabilities found.

**Timeout**: 120s.

---

## 3. npm audit — Node.js Dependency Vulnerabilities

**What it checks**: Known CVEs in npm packages (GitHub Advisory Database).

**Invocation**:
```bash
npm audit --json 2>/dev/null
```

**Parse fields**:
- `vulnerabilities.<pkg>.severity` — npm's own severity (critical/high/moderate/low)
- `vulnerabilities.<pkg>.via[].url` — advisory URL
- `vulnerabilities.<pkg>.fixAvailable` — whether `npm audit fix` can resolve it

**Severity mapping** (direct from npm):
| npm severity | Mapped severity |
|---|---|
| critical | **Critical** |
| high | **High** |
| moderate | **Medium** |
| low | **Low** |

**Exit codes**: 0 = clean, non-zero = vulnerabilities found.

**Timeout**: 120s.

---

## 4. trivy — Multi-Purpose Vulnerability Scanner

**What it checks**: OS packages, language dependencies, Dockerfiles, IaC misconfigurations (NVD + multi-source).

**Invocation — filesystem mode**:
```bash
trivy fs --format json --severity HIGH,CRITICAL --quiet . 2>/dev/null
```

**Invocation — Docker image mode** (if Dockerfile present):
```bash
trivy image --format json --severity HIGH,CRITICAL --quiet <image-name> 2>/dev/null
```

**Invocation — IaC config mode**:
```bash
trivy config --format json --severity HIGH,CRITICAL --quiet . 2>/dev/null
```

**Parse fields**:
- `Results[].Vulnerabilities[].VulnerabilityID` — CVE identifier
- `Results[].Vulnerabilities[].Severity` — CRITICAL/HIGH/MEDIUM/LOW
- `Results[].Vulnerabilities[].PkgName` — affected package
- `Results[].Vulnerabilities[].InstalledVersion` / `FixedVersion`
- `Results[].Vulnerabilities[].Title` — short description

**Severity mapping**: Direct from trivy output (already standard).

**Exit codes**: 0 = clean, 1 = vulnerabilities found.

**Timeout**: 180s.

---

## 5. checkov — IaC Security Scanner

**What it checks**: Terraform, CloudFormation, Kubernetes, Dockerfile misconfigurations.

**Invocation**:
```bash
checkov -d . --output json --quiet --compact 2>/dev/null
```

**Parse fields**:
- `results.failed_checks[].check_id` — CKV rule ID
- `results.failed_checks[].check_result.result` — FAILED
- `results.failed_checks[].file_path` — file
- `results.failed_checks[].file_line_range` — [start, end]
- `results.failed_checks[].guideline` — remediation URL

**Severity mapping**:
| CKV check category | Mapped severity |
|---|---|
| Encryption, public access, IAM | **High** |
| Logging, versioning, tags | **Medium** |
| Best practices | **Low** |

**Exit codes**: 0 = all passed, 1 = failures found.

**Timeout**: 180s.

---

## 6. govulncheck — Go Vulnerability Scanner

**What it checks**: Known vulnerabilities in Go dependencies (Go Vulnerability Database).

**Invocation**:
```bash
govulncheck -json ./... 2>/dev/null
```

**Parse fields**:
- `finding.osv` — OSV identifier
- `finding.trace[].function` — affected function
- `finding.trace[].position.filename` — file
- `finding.trace[].position.line` — line number

**Severity mapping**:
| Condition | Mapped severity |
|---|---|
| Called vulnerable function | **High** |
| Imported vulnerable package (not called) | **Medium** |

**Exit codes**: 0 = clean, 3 = vulnerabilities found.

**Timeout**: 120s.

---

## 7. cargo audit — Rust Dependency Vulnerabilities

**What it checks**: Known CVEs in Rust crates (RustSec Advisory Database).

**Invocation**:
```bash
cargo audit --json 2>/dev/null
```

**Parse fields**:
- `vulnerabilities.list[].advisory.id` — RUSTSEC identifier
- `vulnerabilities.list[].advisory.title` — description
- `vulnerabilities.list[].advisory.severity` — CVSS severity
- `vulnerabilities.list[].package.name` — crate name
- `vulnerabilities.list[].package.version` — installed version
- `vulnerabilities.list[].versions.patched` — fixed versions

**Severity mapping**: Direct from CVSS in advisory.

**Exit codes**: 0 = clean, 1 = vulnerabilities found.

**Timeout**: 60s.

---

## 8. bundler-audit — Ruby Dependency Vulnerabilities

**What it checks**: Known CVEs in Ruby gems (rubysec Advisory Database).

**Invocation**:
```bash
bundler-audit check --format json 2>/dev/null
```

**Parse fields**:
- `results[].advisory.id` — CVE identifier
- `results[].advisory.title` — description
- `results[].advisory.criticality` — high/medium/low
- `results[].gem.name` — gem name
- `results[].gem.version` — installed version

**Severity mapping**: Direct from criticality field.

**Exit codes**: 0 = clean, 1 = vulnerabilities found.

**Timeout**: 60s.

---

## 9. bandit — Python Static Analysis

**What it checks**: Common security issues in Python code (hardcoded passwords, SQL injection, exec usage, etc.).

**Invocation**:
```bash
bandit -r . -f json --severity-level medium 2>/dev/null
```

**Parse fields**:
- `results[].test_id` — B-code (e.g., B101)
- `results[].test_name` — human-readable name
- `results[].issue_severity` — HIGH/MEDIUM/LOW
- `results[].issue_confidence` — HIGH/MEDIUM/LOW
- `results[].filename` — file path
- `results[].line_number` — line
- `results[].issue_text` — description
- `results[].code` — code snippet

**Severity mapping**:
| bandit severity + confidence | Mapped severity |
|---|---|
| HIGH severity + HIGH confidence | **High** |
| HIGH severity + MEDIUM confidence | **Medium** |
| MEDIUM severity + any confidence | **Medium** |
| LOW severity | **Low** |

**Exit codes**: 0 = clean, 1 = findings.

**Timeout**: 120s.

---

## 10. shellcheck — Shell Script Analysis

**What it checks**: Common shell scripting bugs, portability issues, and security pitfalls.

**Invocation**:
```bash
shellcheck -f json --severity=warning *.sh **/*.sh 2>/dev/null
```

**Parse fields**:
- `[].code` — SC rule number (e.g., 2086)
- `[].level` — error/warning/info/style
- `[].message` — description
- `[].file` — file path
- `[].line` / `[].column` — position

**Severity mapping**:
| shellcheck level | Mapped severity |
|---|---|
| error | **High** |
| warning | **Medium** |
| info, style | **Low** |

**Security-relevant rules** (always flag these as High):
- SC2086 — word splitting (command injection risk)
- SC2091 — eval-like constructs
- SC2046 — unquoted command substitution

**Exit codes**: 0 = clean, 1 = findings.

**Timeout**: 30s.

---

## 11. hadolint — Dockerfile Linter

**What it checks**: Dockerfile best practices and security issues.

**Invocation**:
```bash
hadolint --format json Dockerfile 2>/dev/null
# For multiple Dockerfiles:
hadolint --format json Dockerfile* **/Dockerfile* 2>/dev/null
```

**Parse fields**:
- `[].code` — DL rule number (e.g., DL3006)
- `[].level` — error/warning/info/style
- `[].message` — description
- `[].file` — file path
- `[].line` — line number

**Severity mapping**:
| hadolint level | Mapped severity |
|---|---|
| error | **High** |
| warning | **Medium** |
| info, style | **Low** |

**Security-relevant rules** (always flag as High):
- DL3000 — `WORKDIR` should use an absolute path
- DL3002 — last user should not be root
- DL3004 — do not use sudo
- DL3006 — always tag the `FROM` image
- DL3009 — delete apt-get lists after install
- DL3018 — pin versions in apk add
- DL3019 — avoid apk upgrade

**Exit codes**: 0 = clean, 1 = findings.

**Timeout**: 30s.

---

## 12. semgrep — Multi-Language SAST

**What it checks**: Language-aware static analysis with pattern matching. Covers OWASP Top 10, injection, crypto, auth issues.

> **Warning**: Do **not** use the "opengrep" fork — it was subject to a supply
> chain compromise. Use the official semgrep package only.

**Invocation**:
```bash
semgrep scan --config=auto --json --quiet . 2>/dev/null
```

**For specific rulesets**:
```bash
# Security-focused only
semgrep scan --config=p/security-audit --json --quiet . 2>/dev/null

# OWASP Top 10
semgrep scan --config=p/owasp-top-ten --json --quiet . 2>/dev/null
```

**Parse fields**:
- `results[].check_id` — rule identifier (e.g., `python.lang.security.audit.exec-detected`)
- `results[].extra.severity` — ERROR/WARNING/INFO
- `results[].extra.message` — description
- `results[].path` — file path
- `results[].start.line` / `results[].end.line` — line range
- `results[].extra.lines` — code snippet
- `results[].extra.metadata.cwe` — CWE identifiers
- `results[].extra.metadata.owasp` — OWASP categories

**Severity mapping**:
| semgrep severity | Mapped severity |
|---|---|
| ERROR | **High** |
| WARNING | **Medium** |
| INFO | **Low** |

**Notes**:
- `--config=auto` fetches community rulesets (requires network)

**Exit codes**: 0 = clean, 1 = findings.

**Timeout**: 180s.

---

## Severity Normalization

All tools map to a unified 4-level scale:

| Level | Meaning | Report action |
|---|---|---|
| **Critical** | Actively exploitable, known CVE with exploit, exposed secrets | Must fix immediately |
| **High** | Likely exploitable, high-confidence findings | Fix before merge |
| **Medium** | Potential issue, moderate confidence or impact | Review and plan fix |
| **Low** | Best practice, informational, style | Track for later |

## Timeout Handling

If a tool exceeds its timeout:
1. Kill the process
2. Log a warning: `"⚠ {tool} timed out after {N}s — results incomplete"`
3. Continue with remaining tools
4. Report overall status as exit code 2 (tool error) if any tool failed
