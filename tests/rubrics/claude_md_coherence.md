# Rubric: CLAUDE.md coherence with repo state

**SPEC entry:** `RUBRIC-004`

## Scope

Apply to `CLAUDE.md` at the repo root.

## Pass criteria

Walk through CLAUDE.md section by section and verify:

- [ ] **Repo navigation table** lists paths that actually exist; no references to removed folders.
- [ ] **Skill conventions** (naming, progressive disclosure, CLIs over re-implementation, self-documenting CLIs, shell targets) match what the current skills actually do. If a skill drifts, either the skill or the convention is wrong; flag the mismatch.
- [ ] **Shell targets** statement is accurate (security-audit = bash 3.2+, gwt.sh = zsh).
- [ ] **TDD section** matches the current test layout (`tests/cli/` bats, `tests/content/` pytest, `tests/rubrics/` agent).
- [ ] **Security skill output discipline** mandates still hold: XDG default, no SARIF on public, two-document pattern.
- [ ] **Style** section matches what's actually in the repo (British spelling, no em/en-dashes, concise tone).
- [ ] **No dead instructions.** Anything that says "always update X when Y" should still be followable; if X has been deleted or renamed, fix the instruction.

## How to apply

1. Read CLAUDE.md.
2. For each claim, verify against the live repo (file tree, SKILL.md frontmatter, bin/<cli> --help, README sections).
3. List each section with pass/fail and a one-line justification per failure.

## How to record the result

- All criteria green → set `RUBRIC-004` `"passes": true`.
- Any drift → leave `"passes": false`, propose specific CLAUDE.md edits (or the corresponding repo fix if the convention is right and the code drifted).
