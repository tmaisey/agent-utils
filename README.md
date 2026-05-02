# Agent Skills

A personal collection of [agent skills](https://agentskills.io/). Reusable skill modules I use across projects.

## Skills

| Skill | Description |
|-------|-------------|
| [analysing-security](#analysing-security) | Prevention-first security for software projects. Two workflows: a **design review** for applying secure-by-design principles before writing code, and a **CLI-driven audit** for scanning existing code. |
| [managing-git-worktrees](#managing-git-worktrees) | Git worktree management CLI with automatic Docker port isolation. Covers worktree creation, cleanup, listing, and port deconfliction for parallel development. |

---

## analysing-security

[↑ back to top](#agent-skills)

### Motivation

Most security tooling is reactive: scanners that flag issues after code is written. The cheapest bug is the one prevented at design time. This skill pairs two complementary workflows so the agent picks the right one for the situation:

- **Design review (up-front).** Triggered when the user is proposing an architecture, designing a new feature, or asking about security considerations *before* code exists. The agent walks an 8-principle secure-by-design checklist, applies architecture-level patterns (auth, data protection, trust boundaries), and runs a lightweight threat model when warranted. No scanner runs.
- **Audit (after the fact).** Triggered when the user asks to scan, audit, or review an existing codebase. The agent invokes the `security-audit` CLI, then walks the 18 manual-review patterns in `references/agent-checks.md` to catch what static tools miss (logic flaws, auth bypasses, business-rule abuse).

### Built on established frameworks

The skill is grounded in industry-standard frameworks rather than ad-hoc rules:

| Framework | How it's used |
|-----------|---------------|
| [OWASP Top 10](https://owasp.org/www-project-top-ten/) | SAST coverage via the `p/owasp-top-ten` semgrep ruleset; agent-review patterns map to the same categories |
| [STRIDE](https://learn.microsoft.com/en-us/azure/security/develop/threat-modeling-tool-threats) | Threat-modelling process in `references/secure-design.md` (applied as "STRIDE-lite" for fast design-time review) |
| [CWE](https://cwe.mitre.org/) | Findings carry CWE identifiers where the underlying tool reports them, for cross-referencing with external advisories |
| [CVSS](https://www.first.org/cvss/) | Severity mapping for vulnerability findings (Critical/High/Medium/Low) |
| [SARIF 2.1.0](https://docs.oasis-open.org/sarif/sarif/v2.1.0/sarif-v2.1.0.html) | Unified output format, compatible with most CI security platforms |
| Classic secure-by-design principles | The 8 design-review principles (Least Privilege, Defense in Depth, Fail Closed, Secure Defaults, Don't Trust Input, Separation of Privilege, Minimize Attack Surface, Complete Mediation) draw on the long-established secure-design canon |

### ⚠️ Handle audit outputs carefully

Not all software is critical national infrastructure. It is legitimate to triage findings pragmatically and accept some risk, but the moment you publish *which* vulnerabilities exist and *where they are*, you've handed an attacker a roadmap. Audit outputs (markdown reports, JSON findings, SARIF) must stay private even when the codebase is public.

The skill enforces this by default:

- **Reports are stored outside the repo** at `~/.local/share/security-audit/<repo>/` (XDG data dir), so they cannot be accidentally committed.
- **A two-document pattern** is mandated in `SKILL.md`: a public `SECURITY.md` describes posture (what's in scope, how to report a vuln); a private `security_internal.md` (gitignored) tracks open findings and accepted risks.
- **CI guidance in `references/ci-integration.md`** is explicit: never upload SARIF to GitHub's Security tab on public repos. Despite GitHub's wording, those findings are visible to anyone with read access. The recommended pattern is to store SARIF as a workflow artifact (downloadable only by users with write access).
- **`assets/github-action.example.yml`** ships with the safe pattern wired up.

If you fork or adapt this skill, preserve these defaults.

### Skill structure

```
analysing-security/
├── SKILL.md                            entry point + design-review workflow
├── bin/
│   └── security-audit                  executable scanner CLI (bash 3.2+)
├── references/
│   ├── secure-design.md                8 principles, patterns, threat modelling
│   ├── agent-checks.md                 18 code-review patterns for post-scan review
│   ├── tool-catalog.md                 per-tool invocation, output parsing, severity
│   └── ci-integration.md               GitHub Actions / GitLab pipeline setup (incl. public-repo guardrails)
└── assets/
    └── github-action.example.yml       copy-ready CI workflow (artifact-based, public-repo-safe)
```

### `bin/security-audit` (the audit CLI)

A bash CLI that orchestrates third-party scanners, normalises their output into unified findings, and emits markdown / JSON / SARIF. Run `security-audit --help` for the full reference; mini help below.

```
security-audit [scan] [OPTIONS]      Run a security scan (default)
security-audit setup [--check-only]  Install/check required tools
security-audit report [OPTIONS]      View stored reports
security-audit version               Show version

Profiles
  quick        Secrets + dependency scan         (~1 min)
  standard     + SAST, container/IaC scanning    (~5 min)
  deep         + full git history, all tools     (~15 min)

Output
  --stdout     Print full markdown report
  --json       Print unified findings JSON
  --sarif      Print SARIF 2.1.0 (for CI artefacts; do NOT upload to public-repo Security tabs)

Storage
  Reports default to ~/.local/share/security-audit/<repo>/  (outside the repo)

Exit codes
  0  Clean (no Medium+ findings)
  1  Findings present
  2  Tool error
```

#### Integrated third-party tools

The CLI auto-detects the languages and infrastructure in the target repo and dispatches the relevant subset:

| Tool | Category | Triggered by |
|------|----------|--------------|
| [gitleaks](https://github.com/gitleaks/gitleaks) | Secrets in git history | Always |
| [trivy](https://github.com/aquasecurity/trivy) | SCA (deps), container image scan, IaC misconfig | Any project with deps, Dockerfiles, or Terraform |
| [pip-audit](https://github.com/pypa/pip-audit) | Python dependency vulns | Python project with venv |
| [npm audit](https://docs.npmjs.com/cli/commands/npm-audit) | Node dependency vulns | `package.json` |
| [govulncheck](https://pkg.go.dev/golang.org/x/vuln/cmd/govulncheck) | Go dependency vulns | `go.mod` |
| [cargo-audit](https://github.com/rustsec/rustsec) | Rust dependency vulns | `Cargo.toml` |
| [bundler-audit](https://github.com/rubysec/bundler-audit) | Ruby dependency vulns | `Gemfile` |
| [semgrep](https://semgrep.dev/) | Polyglot SAST (OWASP Top 10, security-audit rulesets) | `standard`+ profile |
| [bandit](https://github.com/PyCQA/bandit) | Python-specific SAST | Python project, `standard`+ |
| [hadolint](https://github.com/hadolint/hadolint) | Dockerfile linting | `Dockerfile*` present, `standard`+ |
| [checkov](https://github.com/bridgecrewio/checkov) | IaC misconfig (Terraform, K8s, CloudFormation) | Terraform present, `standard`+ |
| [shellcheck](https://github.com/koalaman/shellcheck) | Shell-script linting | Shell files present |

`security-audit setup` installs anything missing via `brew`, `uv`, `pip`, `go`, or curl, depending on the tool.

### Reference docs

| File | Purpose |
|------|---------|
| `references/secure-design.md` | The design-review reference: 8 core principles, architecture patterns, threat-modelling process. Read by the agent at the start of a design review. |
| `references/agent-checks.md` | 18 manual-review patterns the agent walks after a scan completes. |
| `references/tool-catalog.md` | Per-tool docs (flags, output parsing, severity mapping) for everything `security-audit` orchestrates. |
| `references/ci-integration.md` | How to wire the audit into CI without leaking findings (public-repo-safe artifact pattern, when GitHub Security tab is and isn't appropriate). |
| `assets/github-action.example.yml` | Drop-in GitHub Actions workflow template. |

---

## managing-git-worktrees

[↑ back to top](#agent-skills)

### Motivation

Running multiple feature branches in parallel breaks the moment two of them try to bind the same Docker host port. Git worktrees solve the filesystem side; this skill solves the port side. One CLI creates the worktree, allocates a contiguous port block from the project's `.env.template`, generates `.env`, and tears everything down on cleanup, including the Docker stack and the port-index entry that raw `git worktree remove` would miss.

### Skill structure

```
managing-git-worktrees/
├── skill.md                            entry point + CLI command reference
├── bin/
│   └── gwt.sh                          worktree + port-allocation CLI (zsh)
├── references/
│   ├── env-template-spec.md            .env.template conventions
│   └── docker-compose-spec.md          docker-compose.yml conventions
└── assets/
    ├── env-template.example            copy-ready .env.template starting point
    └── docker-compose.example.yml      copy-ready docker-compose.yml starting point
```

### `bin/gwt.sh` (the worktree CLI)

A zsh CLI that wraps `git worktree` with port allocation and Docker lifecycle. Run `gwt help` for the full reference; mini help below.

```
gwt <branch> [--claude|-c]   Create worktree with port isolation
gwt cleanup <branch> [-f]    Remove worktree, stop Docker, delete branch
gwt list                     List all worktrees with port ranges
gwt ports                    Show port assignments for current worktree
gwt help                     Show this help
```

How the port allocator works:

- Parses `${*_PORT}` variables from `.env.template`
- Scans `.gwt_index` files in every existing worktree to map allocated ranges
- Picks the first contiguous gap from `40000` upwards, big enough for the new worktree
- Writes the assignment to the new worktree's `.gwt_index` and renders `.env` via `envsubst`
- `COMPOSE_PROJECT_NAME` is set per-worktree, so Docker networks and volumes stay isolated

### Reference docs

| File | Purpose |
|------|---------|
| `references/env-template-spec.md` | Read when editing `.env.template`. Naming rules (`*_PORT`, `${VAR}` syntax) the allocator depends on. |
| `references/docker-compose-spec.md` | Read when editing `docker-compose.yml`. Host-port pattern (`"${VAR:-default}:internal"`) and `COMPOSE_PROJECT_NAME` isolation. |
| `assets/env-template.example` | Drop-in starter `.env.template`. |
| `assets/docker-compose.example.yml` | Drop-in starter `docker-compose.yml` with port-isolation pattern wired up. |
