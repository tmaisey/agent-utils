---
name: managing-git-worktrees
description: >
  Git worktree management CLI with automatic Docker port isolation.
  Use when creating, listing, or cleaning up git worktrees. Also use
  when modifying docker-compose.yml, .env.template, or .env files in
  worktree-based projects. Covers: worktree creation, worktree cleanup
  (removing worktrees, deleting branches, stopping Docker), worktree
  listing, and port deconfliction for parallel development.
---

# gwt, Git Worktree Management

## CLI

All worktree operations go through the gwt CLI. Run it directly via Bash:

```
/Users/twm/.claude/skills/gwt-docker/bin/gwt.sh <command> [args]
```

| Command | What it does |
|---------|-------------|
| `list` | Show all worktrees with branch, path, and port range |
| `cleanup <branch> [-f]` | Stop Docker, remove worktree directory, delete branch |
| `<branch> [--claude\|-c]` | Create worktree with port isolation, optionally launch Claude |
| `ports` | Show port assignments for current worktree |

Always use this CLI for worktree lifecycle operations. Do not use raw `git worktree` commands, the CLI handles Docker teardown, port index cleanup, and branch deletion that raw git commands miss.

## When to read child docs

Only read these when you are **editing Docker or env config**, not for routine worktree operations:

| Task | Read this |
|------|-----------|
| Creating or editing `.env.template` | `references/env-template-spec.md` |
| Creating or editing `docker-compose.yml` | `references/docker-compose-spec.md` |
| Need a copy-ready `.env.template` starting point | `assets/env-template.example` |
| Need a copy-ready `docker-compose.yml` starting point | `assets/docker-compose.example.yml` |

## Quick rules (for Docker port isolation)

These are the essential conventions. The child docs above have full detail.

- `.env.template` is committed; `.env` and `.gwt_index` are gitignored
- Port variables **must** end in `_PORT` and use `${VAR}` syntax
- In `docker-compose.yml`, never hardcode host ports, use `"${DB_PORT:-5432}:5432"`
- `COMPOSE_PROJECT_NAME` isolates networks and volumes automatically
- Root worktree keeps a manual `.env` with standard ports; gwt never overwrites it
