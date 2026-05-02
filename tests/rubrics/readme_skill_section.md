# Rubric: README per-skill section completeness

**SPEC entry:** `RUBRIC-003`

## Scope

Apply to each per-skill section in the top-level `README.md` (one section per skill folder).

## Pass criteria

For each per-skill section, evaluate:

- [ ] **Motivation.** A one-or-two-sentence explanation of why this skill exists and what problem it solves. Not just a restated SKILL.md description.
- [ ] **Structure.** Lists the skill's directory layout (SKILL.md, bin/, references/, assets/) so a reader knows where to look.
- [ ] **CLI mini-help.** If the skill ships a CLI, the README shows abridged help (synopsis + key commands). Full help stays in `bin/<cli> --help`.
- [ ] **Integrated tools.** Names any external tools the skill depends on or orchestrates (e.g. gitleaks, trivy, envsubst, docker compose).
- [ ] **Reference summary.** A brief table or list of what each `references/*.md` covers, so a reader can decide which to open.
- [ ] **No duplication of SKILL.md.** The README is the public face; SKILL.md is the agent trigger. Different audiences, different content.
- [ ] **Up to date.** No mentions of removed CLIs, renamed flags, or stale paths. Cross-check against `bin/<cli> --help` and the actual file tree.

## How to apply

1. List every top-level skill folder.
2. For each, locate its README section. If missing entirely, that's a hard fail.
3. Walk the criteria and report pass/fail with a one-line justification.
4. Cross-check against the live CLI help and folder contents.

## How to record the result

- All criteria green across all skills → set `RUBRIC-003` `"passes": true`.
- Any failure → leave `"passes": false`, propose specific README edits.
