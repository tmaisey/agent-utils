# tests/

Test layout for this repo. Three runners, each doing what it's best at.

| Path | Runner | What it covers |
|------|--------|----------------|
| `cli/` | bats | Shell CLIs (`security-audit`, `gwt.sh`). Native sourcing, exit codes, scanner orchestration. |
| `content/` | pytest | Markdown structure: SKILL.md frontmatter, README index, references linkage, README mini-help vs `--help` parity, no em/en-dashes. |
| `rubrics/` | agent (Claude Code) | Prose quality checklists. Applied on demand, not on every commit. |

## Running

```sh
make test           # bats + pytest
make test-cli       # bats only
make test-content   # pytest only
make rubrics-list   # show available rubrics for agent application
```

## Adding a test

Per `CLAUDE.md` mandatory TDD sequence:

1. Add an entry to `docs/SPEC.json` with `"passes": false` and the appropriate `runner`.
2. Write the failing test/rubric.
3. Implement until green.
4. Flip `"passes": true`.
5. Commit implementation + test + SPEC update together.

## Fixtures

`tests/cli/fixtures/` holds tiny synthetic repos used by bats tests. Keep them minimal, deterministic, and self-documenting (a `README.md` per fixture explains what it's planted with and which test consumes it).

## Scanner-gated tests

Functional `security-audit` tests that exercise real scanners (gitleaks, trivy, semgrep) use `bats` `skip` when the scanner isn't on PATH. The test exists and runs the moment the dep is installed; suite stays green on a fresh machine.
