# CLAUDE.md

Guidance for Claude Code when working in this repo.

## What this repo is

A personal collection of [agent skills](https://agentskills.io/). Each top-level
folder is one self-contained skill, intended to be symlinked into
`~/.claude/skills/<skill-name>` for global use. The repo bundles documentation,
reference material, and CLIs that agents invoke.

## Repo navigation

| Path | What it is |
|------|-----------|
| `README.md` | User-facing index. Skill table at the top, per-skill section below with motivation, structure, CLI mini-help, integrated tools, and reference-doc summary. **Always update this when a skill is added, removed, or its CLI surface changes.** |
| `<skill>/SKILL.md` | Entry point Claude reads when the skill triggers. Frontmatter `description` is the trigger pattern, keep it specific. |
| `<skill>/bin/` | Executable CLIs. Run via Bash; `--help` (or `help`) is the source of truth for usage. |
| `<skill>/references/` | Long-form docs. Loaded on demand from SKILL.md, not in default context. |
| `<skill>/assets/` | Copy-ready templates the agent drops into target repos. Not read for context. |

## Skill conventions

- **Naming.** `verb-noun`, lowercase, hyphenated (`analysing-security`,
  `managing-git-worktrees`). Folder name === `name:` field in frontmatter.
- **Progressive disclosure.** SKILL.md should be short and trigger cleanly. Do
  not inline reference content; point to it. References stay out of context
  until needed.
- **CLIs over re-implementation.** Where a deterministic command can do the
  work (port allocation, scanner orchestration), put it in `bin/` rather than
  asking the model to recompute every call.
- **Self-documenting CLIs.** Every `bin/` CLI must support `--help` (or `help`)
  with full reference. README only carries mini-help.
- **Shell targets.** `security-audit` is bash 3.2+ (macOS default, no
  associative arrays). `gwt.sh` is zsh. Don't mix.

## TDD is the default

This repo ships CLIs (`security-audit`, `gwt.sh`) and is developed test-first
going forwards, per the global mandatory development workflow:

1. Add or update the entry in `docs/SPEC.json` with `"passes": false`.
2. Write a failing test that covers the new CLI behaviour. Run it and prove it
   fails.
3. Implement until the test passes.
4. Set `"passes": true` in the SPEC entry.
5. Commit implementation, test, and SPEC update together. All tests must pass.

Pure documentation edits (SKILL.md prose, references, assets, README) don't
need a SPEC entry, but if a doc change asserts CLI behaviour, the assertion
must already be covered by a test.

### Three runners, by design

Don't try to consolidate these, each one fits its target:

- **`tests/cli/`** uses **bats** (bash/zsh CLIs are sourced and called natively;
  pytest-via-subprocess loses shell semantics and forces a fresh shell per
  assertion).
- **`tests/content/`** uses **pytest** (markdown parsing, frontmatter checks,
  cross-file structural assertions, Python's ecosystem is the right tool).
- **`tests/rubrics/`** are **markdown checklists applied by an agent** (Claude
  Code or equivalent). Run on demand, not on every commit. SPEC entries with
  `runner: agent` flip `"passes": true` when an applied rubric report is clean.

`make test` runs bats + pytest. Rubrics are out-of-band: `make rubrics-list`.

Functional `security-audit` tests that exercise real scanners (gitleaks, trivy,
semgrep) `skip` when the scanner isn't on PATH. The test exists and runs the
moment the dep is installed; suite stays green on a fresh machine. SPEC entries
declare these gates via a `requires:` list.

## When updating a skill

1. Follow the TDD sequence above for any CLI change.
2. If CLI surface changed, update its `--help` first; treat that as the spec.
3. Update the relevant section of `README.md` (skill index row + per-skill
   detail). The README is the public face of this repo.

## Security skill, output discipline (non-negotiable)

`analysing-security/bin/security-audit` produces vulnerability reports. These
must never land in this repo or in any public repo:

- Reports default to `~/.local/share/security-audit/<repo>/` (XDG data dir),
  outside any working tree. Don't override this default unless writing to a
  gitignored path.
- Never upload SARIF to GitHub's Security tab on public repos. The
  artifact-based pattern in `assets/github-action.example.yml` is the safe
  default; preserve it if you edit the asset.
- The skill's two-document pattern (`SECURITY.md` public, `security_internal.md`
  gitignored) is mandated in SKILL.md. Don't dilute it.

## Style

- British spelling (behaviour, optimisation, centred).
- No em-dashes or en-dashes in user-facing text. Use commas, full stops, or
  parentheses.
- Concise, content-dense. Tables and lists over prose where the structure fits.
- Match existing tone in README.md and SKILL.md files.
