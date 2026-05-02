# Rubric: SKILL.md description quality

**SPEC entry:** `RUBRIC-001`

## Scope

Apply to the `description:` frontmatter field of every `*/SKILL.md` in the repo.

## Pass criteria

For each SKILL.md, evaluate:

- [ ] **Names the workflow or output**, not just the topic. ("Run a complete experiment lifecycle..." beats "Experiments.")
- [ ] **Contains an explicit trigger phrase** ("Use when…", "Use to…", "TRIGGER when…"). The harness matches on this when deciding to load the skill.
- [ ] **Distinguishes itself from sibling skills** in this repo. No two descriptions should fire on the same trigger; if they would, sharpen the boundary.
- [ ] **States what it skips**, where ambiguity is likely (e.g. "SKIP: provider-neutral code"). Optional but valuable for skills with adjacent surface area.
- [ ] **Under 1024 chars.** Frontmatter is loaded into every conversation; long descriptions tax context.
- [ ] **No marketing fluff.** No "powerful", "comprehensive", "seamlessly". Concrete verbs only.

## How to apply

1. Read every `*/SKILL.md` frontmatter.
2. For each one, list the criteria with pass/fail and a one-line justification.
3. If any fail, propose a tighter rewrite (don't apply it without user approval).
4. Output as a markdown report.

## How to record the result

- All criteria green across all skills → set `RUBRIC-001` `"passes": true` in `docs/SPEC.json`.
- Any failure → leave `"passes": false`, attach the report path or inline summary in the commit/PR that would address it.
