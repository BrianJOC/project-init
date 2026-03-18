---
name: start
description: "Bootstrap a new project with Hermit, Justfile, agents, and CLAUDE.md. Use when the user runs /start or asks to set up a new project."
---

# /start — Project Bootstrap

Sets up a new repository with the full Claude dev environment. Run this in any new project directory.

Work through each phase in order. Ask exactly one question per message. Do not skip phases.

---

## Pre-flight: git check

```bash
git rev-parse --is-inside-work-tree 2>/dev/null
```

If not a git repo: run `git init` before proceeding. Phase 4 depends on git.

---

## Phase 1 — Infrastructure (automatic, no questions)

**Run init.sh if needed**

Check for `bin/hermit.hcl` and `Justfile`. If either is missing:

```bash
bash <(curl -s https://raw.githubusercontent.com/YOU/bootstrap/main/init.sh)
```

If both exist: print "Infrastructure already in place." and continue.

**Scan the repo for stack signals**

Look for: `package.json`, `pyproject.toml`, `go.mod`, `Cargo.toml`, `requirements.txt`, `README.md`. Note detected languages, frameworks, and any stack descriptions in README. Use this in Phase 2 to make confirmations instead of open questions.

---

## Phase 2 — Three questions

**Q1: "What are we building?"**

If the repo scan makes the answer obvious, confirm it: _"Looks like [X] — is that right?"_ Otherwise ask openly. Record the answer as `PROJECT_DESCRIPTION`.

**Q2: "Does this project have a UI?"**

- **Yes** → Mark: UI project. Activate UI agent pool (ui-designer, ux-architect, brand-guardian, accessibility-auditor). Add `mcp__pencil` to settings.
- **Yes** → Ask follow-up (separate message): _"Do you want the full design + evidence pipeline? This adds Pencil design files, Playwright browser automation for screenshots, and the evidence-collector/reality-checker quality gate loop."_
  - **Yes** → Mark: evidence pipeline. Run:
    ```bash
    pnpm exec playwright install chromium
    playwright-cli install --skills
    ```
    Note: `pnpm exec playwright install chromium` requires a pnpm project with `@playwright/test` installed. `playwright-cli install --skills` installs Claude Code browser automation skills. If pnpm/frontend is not set up yet, add a note to CLAUDE.md to run these after frontend setup. Add evidence-collector and reality-checker to agent pool. Add `"Bash(playwright-cli:*)"` to settings. Add to Justfile:
    ```justfile
    # Run E2E Playwright tests
    test-e2e:
        cd frontend && pnpm test:e2e
    ```
- **No** → Skip UI agents.

**Q3: "Will this use a database?"**

- **Yes** → Ask follow-up: _"Which database? (SQLite / Postgres / other)"_ Record answer.
  - Add backend-architect to agent pool.
  - Add to Justfile:
    ```justfile
    # ── Database ───────────────────────────────────────────────────────────────

    # Apply all pending migrations
    migrate:
        cd backend && uv run alembic upgrade head

    # Generate a new migration: just migration "describe change"
    migration msg:
        cd backend && uv run alembic revision --autogenerate -m "{{ msg }}"

    # Show current migration state
    migrate-status:
        cd backend && uv run alembic current

    # Roll back one migration
    migrate-down:
        cd backend && uv run alembic downgrade -1
    ```
  - If Python project: add `"Bash(alembic:*)"` to settings.
- **No** → Skip.

---

## Phase 3 — Agent selection and adaptation

**Default pool** (always proposed, regardless of Q2/Q3):
- code-reviewer
- agents-orchestrator
- spec-writer
- workflow-architect
- product-manager

**Conditional additions:**
- UI project → ui-designer, ux-architect, brand-guardian, accessibility-auditor
- Evidence pipeline → evidence-collector, reality-checker
- Database → backend-architect
- Backend/API detected (pyproject.toml, go.mod, etc.) → software-architect, api-tester, security-engineer

For **each agent in the pool**, one at a time:

1. Print one sentence: what this agent does and when it gets used.
2. Ask: _"Include this agent? (yes / no / yes with changes)"_
3. If yes or yes-with-changes, run the adaptation conversation:
   - Ask about stack-specific references to update (CSS framework version, runtime, language)
   - Ask about workflow integration (does this project use the full Pencil design pipeline?)
   - Ask about project-specific behavioral changes
   - Show proposed adapted content before writing to disk
   - Loop until the user approves
4. If user wants an agent not in the pool: fetch from upstream:
   - URL: `https://raw.githubusercontent.com/msitarzewski/agency-agents/main/agents/<name>.md`
   - If fetch fails (network/404): inform user, offer to skip or retry
   - Run full adaptation (also covers: Pencil MCP tool wiring, SuperPowers skill references, pipeline diagram integration)

No agent is copied verbatim. All go through the review.

---

## Phase 4 — Generate and commit

Create directories first:

```bash
mkdir -p .claude/agents
```

Write files in this order:

**1. Agent files**

For each approved agent, write to `.claude/agents/<name>.md`. The file content is the adapted version from Phase 3. Prepend provenance into the YAML front matter (after the opening `---`):

```yaml
---
# upstream: msitarzewski/agency-agents @ <sha-or-unknown>
# modified: <today's date> — adapted for <PROJECT_DESCRIPTION>
name: ...
```

**2. .claude/settings.local.json**

Start from the base permissions list. Add conditional entries per Phase 2 answers. Write as valid JSON to `.claude/settings.local.json`.

Base allow list:
```json
[
  "Bash(*)", "Bash(git:*)", "Bash(just:*)", "Bash(curl:*)", "Bash(bash:*)",
  "Bash(ls:*)", "Bash(find:*)", "Bash(cp:*)", "Bash(mkdir:*)", "Bash(chmod:*)",
  "Bash(stat:*)", "Bash(source:*)", "Bash(export:*)", "Bash(cd:*)",
  "Bash(python3:*)", "Bash(uv:*)", "Bash(pnpm:*)", "Bash(npm:*)", "Bash(npx:*)",
  "Bash(jq:*)", "Bash(gh api:*)",
  "WebSearch",
  "WebFetch(domain:raw.githubusercontent.com)",
  "WebFetch(domain:github.com)",
  "WebFetch(domain:api.github.com)"
]
```

Conditional additions:
- UI project: `"mcp__pencil"`
- Evidence pipeline: `"Bash(playwright-cli:*)"`
- Database + Python: `"Bash(alembic:*)"`

**3. CLAUDE.md**

Generate using this structure:

```markdown
# CLAUDE.md

## Project

**<project name>** — <PROJECT_DESCRIPTION>. Stack: <detected + confirmed stack>.

## Agent Pipeline

<list selected agents with one-line role descriptions; use pipeline arrow format matching agency-agents conventions>

## Testing Strategy

| Layer | Tool | Location | When to write |
|-------|------|----------|---------------|
<populate based on what was set up — backend pytest, Vitest, Playwright as applicable>

## Permissions

See `.claude/settings.local.json` for allowed commands. Run `just` to see available tasks.
```

**4. Commit**

```bash
git add .claude/ CLAUDE.md
git commit -m "chore: bootstrap project with /start"
```

---

## Re-run detection

If `.claude/agents/` or `CLAUDE.md` already exists when `/start` is invoked, do not run the full flow. Ask:

_"This project is already bootstrapped. What would you like to do?"_

Options:
1. **Add a new agent** — Phase 3 for one agent only. Commit: `chore: add <name> agent via /start`
2. **Re-adapt an existing agent** — Pick an agent, re-run adaptation, overwrite. Commit: `chore: re-adapt <name> agent via /start`
3. **Regenerate CLAUDE.md** — Re-run Q1 only, regenerate CLAUDE.md. Commit: `chore: regenerate CLAUDE.md via /start`
4. **Full re-bootstrap** — Full Phase 2→3→4. Show diffs of existing files; user approves each overwrite. Commit: `chore: re-bootstrap project with /start`
