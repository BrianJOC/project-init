# project-init

Claude Code plugin for bootstrapping new projects with Hermit, Justfile, agents, and CLAUDE.md.

## One-time machine setup

```bash
claude plugin marketplace add github:BrianJOC/project-init
claude plugin install project-init@brianjoc
```

## Starting a new project (Claude present)

Open Claude Code in any new project directory and run:

```
/start
```

## Starting a new project (no Claude)

```bash
bash <(curl -s https://raw.githubusercontent.com/BrianJOC/project-init/main/init.sh)
```

Then run `/start` later to complete configuration.

## What gets set up

- **`init.sh`**: Hermit tooling + baseline Justfile (no Claude required)
- **`/start`**: Agent selection + adaptation, CLAUDE.md, `.claude/settings.local.json`

## Updating

```bash
claude plugin marketplace update brianjoc
claude plugin update project-init
```
