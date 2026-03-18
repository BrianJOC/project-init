# bootstrap

Claude Code plugin for bootstrapping new repositories with a full dev environment.

## One-time machine setup

```bash
claude plugin install github:YOU/bootstrap
```

## Starting a new project (Claude present)

Open Claude Code in any new project directory and run:

```
/start
```

## Starting a new project (no Claude)

```bash
bash <(curl -s https://raw.githubusercontent.com/YOU/bootstrap/main/init.sh)
```

Then run `/start` later to complete configuration.

## What gets set up

- **`init.sh`**: Hermit tooling + baseline Justfile (no Claude required)
- **`/start`**: Agent selection + adaptation, CLAUDE.md, `.claude/settings.local.json`

## After setup

1. Create a GitHub repository
2. `git remote add origin <url> && git push -u origin main`
3. `claude plugin install github:YOU/bootstrap` on each machine
