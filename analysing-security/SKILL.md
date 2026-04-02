---
name: analyising-security
description: >
  Prevention-first security for software projects. Two workflows: a **design
  review** for applying secure-by-design principles before writing code, and a
  **CLI-driven audit** for scanning existing code. Use when designing features
  that need security consideration, or when asked to audit, scan, or review a
  repository for security issues.
---

# secure-design

This skill covers two complementary workflows: **designing secure software** and
**auditing existing code**. Prevention comes first — catching a design flaw
before implementation is cheaper than finding it in a scan afterward.

## Skill Contents

| Path | What it is |
|------|------------|
| `bin/security-audit` | **Executable CLI** (bash) — the scanner. Run it directly or copy into target repos for CI. |
| `references/secure-design.md` | Design-time principles, architecture patterns, threat modeling process |
| `references/agent-checks.md` | 18 code-review patterns for agent manual review (post-scan) |
| `references/tool-catalog.md` | Per-tool invocation, output parsing, severity mapping |
| `references/ci-integration.md` | CI/CD pipeline setup (GitHub Actions, GitLab) |
| `assets/github-action.example.yml` | Copy-ready GitHub Actions workflow template |

---

The following section covers the **design review workflow** — applying the
principles and patterns from `references/secure-design.md` to architecture
proposals and new features before code is written. That reference contains 8
core security principles, architecture-level patterns (auth, data protection,
trust boundaries), and a lightweight threat modeling process.

## Design Review Workflow

Use this workflow when reviewing an architecture proposal, designing a new
feature, or when the user asks about security considerations before writing
code.

### 1. Identify Security-Relevant Scope

Determine whether the design touches security-sensitive areas:
- Authentication or authorization changes
- New API endpoints or trust boundaries
- Handling of PII, credentials, or sensitive data
- New dependencies or third-party integrations
- Infrastructure changes (ports, network, containers)
- AI agent permissions or tool configurations

If none apply, a design review is not needed — proceed normally.

### 2. Apply Design Principles

Read `references/secure-design.md` §Core Principles. For each of the 8
principles, check whether the proposed design respects or violates it.
Flag any gaps.

### 3. Threat Model (if warranted)

If the design introduces new trust boundaries or data flows, run the
lightweight threat model from `references/secure-design.md` §Lightweight Threat Modeling:
1. Identify assets, actors, and trust boundaries
2. Enumerate threats using STRIDE-lite
3. Map threats to principles and architecture patterns
4. Produce a threat-mitigation table

### 4. Present Design Recommendations

Deliver findings to the user:
- Which principles apply and whether the design satisfies them
- Relevant checklists from `references/secure-design.md` §Architecture-Level Security Patterns
- Threat-mitigation table (if threat modeling was performed)
- Specific, actionable recommendations — not generic advice

### 5. Post-Implementation Audit

After the feature is implemented, run the standard audit workflow (§Audit
Workflow below) to verify that the design recommendations were correctly applied
in code.

---

The following sections cover the **audit workflow** — running the CLI scanner
and agent code review against an existing codebase.

## The CLI: `bin/security-audit`

The audit workflow is driven by `bin/security-audit` — a bash script located
**in this skill folder**. It is not installed globally; run it by its path.

**Prerequisites** (must be available before running the CLI):
- **git** — the CLI detects the repo root via `git rev-parse`; it will refuse to
  run outside a git repository
- **bash 3.2+** — compatible with macOS default bash
- **jq** — required for JSON processing (`security-audit setup` will install it)
- **Scan tools** — gitleaks, semgrep, bandit, etc. are installed on first run
  via `security-audit setup`; the CLI auto-detects which tools apply to the repo

### Quick Reference

```
bin/security-audit [scan] [-p quick|standard|deep] [--stdout] [--json] [--sarif]
bin/security-audit setup [--check-only]
bin/security-audit report [--latest|--list] [--stdout]
bin/security-audit version
```

| Flag | Purpose |
|------|---------|
| `-p, --profile` | `quick` (secrets+deps), `standard` (default, +SAST/IaC), `deep` (+full history) |
| `-t, --tool <name>` | Run only specific tool(s), repeatable (accepts internal or common names, e.g. `semgrep`) |
| `--stdout` | Print full markdown report to terminal |
| `--json` | Print unified findings JSON to terminal |
| `--sarif` | Print SARIF 2.1.0 to stdout (for CI artifacts or tooling; excludes Low findings) |
| `--no-parallel` | Run tools sequentially instead of in parallel |
| `-v, --verbose` | Show tool commands and raw output |
| `-q, --quiet` | Suppress progress output, exit code only |

Reports are stored in `~/.local/share/security-audit/<repo>/` — never in the repo tree.

## Audit Workflow

### 1. Run the CLI

Run `bin/security-audit` from this skill folder by its full path:

```bash
# First time — install required scan tools
/path/to/secure-design/bin/security-audit setup

# Scan the repository (run from within the target git repo)
/path/to/secure-design/bin/security-audit -p standard
```

The CLI auto-detects languages, runs applicable tools in parallel, normalizes
findings to a unified severity scale, deduplicates, and prints a summary.

### 2. Review the Report

Read the summary printed to terminal. For full details:

```bash
/path/to/secure-design/bin/security-audit report --stdout    # print latest report
```

Or read `findings.json` directly for structured data:

```bash
/path/to/secure-design/bin/security-audit report --latest    # shows file path
```

### 3. Agent Code Review

After the CLI scan, perform manual code review for patterns that tools miss.
Use `references/agent-checks.md` — it contains 18 patterns with grep hints,
vulnerable code examples, and remediation guidance.

| Profile | Patterns to check |
|---------|-------------------|
| quick | None (CLI only) |
| standard | 1–5 (traditional) + 13–15 (AI/agent) |
| deep | All 18 patterns |

### 4. Present Combined Findings

Combine CLI findings and agent review into a single summary for the user:
- Group by severity (Critical → Low)
- Highlight top actionable items with file:line references
- Note tools skipped and any limitations

## Exit Codes

| Code | Meaning |
|------|---------|
| 0 | Clean — no findings at Medium or above |
| 1 | Findings — at least one Medium+ finding |
| 2 | Tool error — one or more tools failed/timed out |

Priority: exit code 2 (tool error) takes precedence over exit code 1 (findings).
If a scan has both tool errors and findings, exit code 2 is returned to signal
incomplete results.

## Severity Scale

| Level | Meaning |
|-------|---------|
| Critical | Actively exploitable: known CVE with exploit, exposed secrets, RCE |
| High | Likely exploitable: high-confidence injection, auth bypass |
| Medium | Potential issue: moderate confidence, limited impact |
| Low | Best practice: informational, style, minor hardening |

## CI / GitHub Actions

The `security-audit` CLI is **not installed globally** on CI runners. When setting up a GitHub Actions workflow or any CI security check, you **must** copy the latest version of `bin/security-audit` from this skill into the target repository (e.g. as `.github/scripts/security-audit`). The workflow should then run it from that path.

```yaml
- name: Security audit
  run: .github/scripts/security-audit -p quick -q --sarif > results.sarif
```

Use `assets/github-action.example.yml` as the starting template. See `references/ci-integration.md` for artifact configuration, caching, and threshold configuration. Note: GitHub's Security tab is only suitable for **private repositories** — on public repos, findings are visible to anyone with read access.

## Security Documentation

Maintain two complementary documents — a public security posture doc and a private findings tracker. These are not duplicative: `SECURITY.md` describes *what the security posture is*, `security_internal.md` describes *where it falls short and what's being done about it*.

### SECURITY.md (version controlled, committed to the repo)

- Security policy and strategy for the project
- Architecture decisions and controls in place (auth model, data protection, trust boundaries)
- Threat model summary (assets, actors, boundaries — from the design review workflow)
- Dependency management policy
- Vulnerability disclosure/reporting process

Apply `references/secure-design.md` principles to tailor this document to the specific project.

### security_internal.md (private, never committed to a public repo)

- References `SECURITY.md` for the baseline — does NOT duplicate it
- Current known vulnerabilities and their status (open, mitigating, accepted risk)
- Specific remediation plans with timelines
- Scan findings that haven't been resolved yet
- Risk acceptance decisions with justification
- Add to `.gitignore` to prevent accidental commit

### Populating findings into internal docs

Three CLI output patterns for getting findings into the private tracker:

1. **Local report library** (`~/.local/share/security-audit/<repo>/`) — the default. Stored outside the project tree, zero risk of accidental commit.
2. **SARIF** (`--sarif`) — structured format for tooling. Store as CI artifacts, never upload to GitHub Security tab on public repos.
3. **Stdout piping** (`--stdout`, `--json`) — agent can direct output into `security_internal.md` or any private system.

## Reference Files

**CLI**
- `bin/security-audit` — executable scanner CLI (bash); run by path, requires git + jq

**Design (prevention)**
- `references/secure-design.md` — secure-by-design principles, architecture-level security patterns, lightweight threat modeling process

**Audit (detection)**
- `references/tool-catalog.md` — per-tool invocation, parsing, severity mapping
- `references/agent-checks.md` — 18 code-review patterns with examples

**CI/CD**
- `references/ci-integration.md` — CI/CD pipeline setup guide
- `assets/github-action.example.yml` — GitHub Actions workflow template
