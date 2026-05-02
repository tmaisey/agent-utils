# Rubric: reference doc clarity

**SPEC entry:** `RUBRIC-002`

## Scope

Apply to every `*/references/*.md` in the repo.

## Pass criteria

For each reference doc, evaluate:

- [ ] **One concern per doc.** A reference covers a single topic (one tool, one workflow, one concept). If it covers two unrelated things, it should be split.
- [ ] **Loaded on demand, not by default.** SKILL.md should point to the reference with a clear "read X when Y" cue, not inline its contents.
- [ ] **Self-contained.** A reader landing here without prior context can act on it. No dangling pronouns referring to SKILL.md.
- [ ] **No duplication of SKILL.md.** SKILL.md gives the trigger and the shape; the reference gives the detail. Repeating the SKILL.md prose here means the SKILL.md is too long or the reference is redundant.
- [ ] **Examples are concrete and copy-ready.** Not "you might do X" but "run `tool --flag`".
- [ ] **Stale-resistant.** Avoid hard-coded version numbers, dates, or "as of" claims unless they're load-bearing. Where they are, mark them clearly.

## How to apply

1. List every reference doc grouped by skill.
2. For each, walk the criteria and report pass/fail with a one-line justification.
3. Cross-check: does the parent SKILL.md actually link to this reference, and is the link contextual ("read X when Y") or just a bare link?
4. Flag any doc that should be split, merged, or deleted.

## How to record the result

- All criteria green across all references → set `RUBRIC-002` `"passes": true`.
- Any failure → leave `"passes": false`, propose specific edits.
