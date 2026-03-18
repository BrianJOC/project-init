#!/usr/bin/env bash
# bootstrap/init.sh — deterministic project infrastructure setup
# Idempotent: safe to run multiple times. No Claude required.
# Usage: bash <(curl -s https://raw.githubusercontent.com/YOU/bootstrap/main/init.sh)

set -euo pipefail

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

info()  { echo -e "${GREEN}✓${NC} $*"; }
skip()  { echo -e "${YELLOW}→${NC} $* — already exists, skipping"; }
abort() { echo "✗ $*" >&2; exit 1; }

# ── Hermit ──────────────────────────────────────────────────────────────────

setup_hermit() {
  if [ -f "bin/hermit.hcl" ]; then
    skip "Hermit"
    return
  fi

  echo "Bootstrapping Hermit..."
  mkdir -p bin

  if ! curl -fsSL https://github.com/cashapp/hermit/releases/latest/download/install.sh | bash -s -- bin/; then
    abort "Failed to install Hermit. Check network connectivity."
  fi

  info "Hermit initialized"

  if [ -f "bin/just" ]; then
    skip "just"
  else
    echo "Installing just via Hermit..."
    bin/hermit install just
    info "just installed"
  fi
}

# ── Justfile ────────────────────────────────────────────────────────────────

setup_justfile() {
  if [ -f "Justfile" ]; then
    skip "Justfile"
    return
  fi

  cat > Justfile << 'JUSTFILE_EOF'
# Task runner — run `just` to see available commands
# Requires: hermit activated (source bin/activate-hermit)

set dotenv-load := true

# Show available commands
default:
    @just --list --list-heading $'Available commands:\n\n'

# ── Dev Ports ───────────────────────────────────────────────────────────────

# Show what is using the dev ports (read-only diagnostic)
ports:
    #!/bin/bash
    for port in 8000 5173; do
        info=$(lsof -i :"$port" -sTCP:LISTEN 2>/dev/null | tail -n +2)
        if [ -n "$info" ]; then
            echo "Port $port — IN USE"
            echo "$info" | awk '{printf "  %-12s PID %s\n", $1, $2}'
        else
            echo "Port $port — free"
        fi
    done

# Kill whatever is holding the dev ports
free-ports:
    #!/bin/bash
    killed=0
    for port in 8000 5173; do
        pids=$(lsof -ti :"$port" -sTCP:LISTEN 2>/dev/null)
        if [ -n "$pids" ]; then
            for pid in $pids; do
                name=$(ps -p "$pid" -o comm= 2>/dev/null || echo "unknown")
                echo "Killed $name (PID $pid) on port $port"
                kill "$pid" 2>/dev/null
                killed=$((killed + 1))
            done
        else
            echo "Port $port — already free"
        fi
    done
    [ $killed -gt 0 ] && echo "" && echo "Ports cleared."
JUSTFILE_EOF

  info "Justfile created"
}

# ── Main ────────────────────────────────────────────────────────────────────

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  echo ""
  echo "Bootstrap — initializing project infrastructure"
  echo "────────────────────────────────────────────────"

  setup_hermit
  setup_justfile

  echo ""
  echo "Done. Next steps:"
  echo "  source bin/activate-hermit   # activate hermit for this shell"
  echo "  just                         # see available commands"
  echo ""
  echo "If Claude Code is installed, run /start to complete configuration."
  echo ""
fi
