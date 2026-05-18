# AI Dev Environment Setup v2
# Claude Code Executable Specification — Cross-Platform
# Supports: macOS (Apple Silicon + Intel) · Windows (WSL2 recommended · Native PowerShell)

---

## HOW TO USE THIS FILE

```
claude "Read SETUP_V2.md, run the system detection, then execute all phases.
Ask me before each phase. Prompt for manual actions only after all
automatable steps are done. Log everything to SETUP_LOG_V2.md."
```

### CLI vs App — Which to Use for Initial Setup

**Use the CLI (`claude` in terminal) for initial setup.** Reason:
- `/plugin` commands (Codex plugin, Ruflo plugins) only work in CLI
- Full shell environment with `~/.zshrc` sourced
- Interactive tools (flow-nexus, Ruflo wizard) work correctly
- Better error visibility and recovery

Once setup is complete, the Claude Code app works for everything else.

---

## IRON RULES
- ALWAYS check if a tool is installed before installing
- ALWAYS show user what will change before touching config files
- ALWAYS create a backup before editing `~/.zshrc`, `~/.bashrc`, or PowerShell profile
- NEVER use sudo unless flagged to user and confirmed
- ALWAYS verify each install succeeded before moving to the next
- If a step fails: log the error, skip it, continue — do not abort the phase
- Batch ALL manual steps and present them together at the very end
- Log all completed steps to SETUP_LOG_V2.md with timestamps

---

## STEP 0 — SYSTEM DETECTION

Run this first. Results drive LLM selection and platform-specific paths.

```bash
echo "=== System Detection ==="

# --- OS ---
OS=$(uname -s)
ARCH=$(uname -m)
echo "OS: $OS | Arch: $ARCH"

# --- macOS version ---
if [[ "$OS" == "Darwin" ]]; then
  sw_vers
  RAM_GB=$(( $(sysctl -n hw.memsize) / 1024 / 1024 / 1024 ))
  CPU_MODEL=$(sysctl -n machdep.cpu.brand_string 2>/dev/null || system_profiler SPHardwareDataType | grep "Chip:" | awk -F': ' '{print $2}')
  GPU_INFO=$(system_profiler SPDisplaysDataType 2>/dev/null | grep -E "Chipset|VRAM" | head -3)
fi

# --- Linux / WSL ---
if [[ "$OS" == "Linux" ]]; then
  RAM_GB=$(( $(grep MemTotal /proc/meminfo | awk '{print $2}') / 1024 / 1024 ))
  CPU_MODEL=$(grep "model name" /proc/cpuinfo | head -1 | cut -d: -f2 | xargs)
  # Check if WSL
  grep -qi microsoft /proc/version 2>/dev/null && echo "Environment: WSL2" || echo "Environment: Linux native"
fi

# --- GPU detection ---
if [[ "$ARCH" == "arm64" && "$OS" == "Darwin" ]]; then
  GPU_TYPE="apple_silicon"
  GPU_LABEL="Apple Silicon (unified memory)"
elif command -v nvidia-smi &>/dev/null; then
  VRAM_GB=$(nvidia-smi --query-gpu=memory.total --format=csv,noheader,nounits 2>/dev/null | head -1 | awk '{printf "%d", $1/1024}')
  GPU_TYPE="nvidia"
  GPU_LABEL="NVIDIA GPU — ${VRAM_GB}GB VRAM"
else
  GPU_TYPE="cpu_only"
  GPU_LABEL="CPU only (no dedicated GPU)"
fi

echo ""
echo "=== Summary ==="
echo "RAM:  ${RAM_GB}GB"
echo "CPU:  ${CPU_MODEL}"
echo "GPU:  ${GPU_LABEL}"

# --- LLM Recommendation ---
echo ""
echo "=== Recommended Ollama Models ==="

if [[ "$GPU_TYPE" == "apple_silicon" ]]; then
  if   (( RAM_GB >= 64 )); then PRIMARY="qwen3:32b";  FAST="qwen3:14b"
  elif (( RAM_GB >= 32 )); then PRIMARY="qwen3:14b";  FAST="qwen3:8b"
  elif (( RAM_GB >= 16 )); then PRIMARY="qwen3:8b";   FAST="llama3.2:3b"
  else                          PRIMARY="llama3.2:3b"; FAST="qwen3:1.7b"
  fi
elif [[ "$GPU_TYPE" == "nvidia" ]]; then
  if   (( VRAM_GB >= 24 )); then PRIMARY="qwen3:32b";  FAST="qwen3:14b"
  elif (( VRAM_GB >= 16 )); then PRIMARY="qwen3:14b";  FAST="qwen3:8b"
  elif (( VRAM_GB >= 8  )); then PRIMARY="qwen3:8b";   FAST="llama3.2:3b"
  else                           PRIMARY="llama3.2:3b"; FAST="phi4-mini"
  fi
else
  # CPU only — keep models small
  PRIMARY="llama3.2:3b"
  FAST="qwen3:1.7b"
fi

echo "Primary model: $PRIMARY"
echo "Fast/small model: $FAST"
echo ""
echo "These will be installed in Phase 2 and set as Aider defaults."
```

Report results to user. Ask: "Shall I proceed with Phase 1?"

---

## PHASE 0b — WINDOWS SETUP (skip on Mac/Linux)

**Only run this phase on Windows. Mac and Linux users skip to Phase 1.**

### Option A — WSL2 (Recommended for Windows)
WSL2 gives a full Linux environment. All subsequent phases run identically to Linux.

```powershell
# Run in PowerShell as Administrator:
wsl --install
# Restart when prompted, then:
wsl --set-default-version 2
# After restart, open Ubuntu from Start Menu and create a user
# Then run all remaining phases inside the WSL2 Ubuntu terminal
```

### Option B — Native Windows (PowerShell path)
Use this only if WSL2 is not available. Some tools have reduced functionality.

```powershell
# Install Scoop (user-level package manager, no admin needed)
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
irm get.scoop.sh | iex

# Install Git for Windows (includes Git Bash)
scoop install git

# Install core tools
scoop install nodejs python mise fzf ripgrep bat lazygit starship

# Install Ollama (Windows native installer)
# Download from: https://ollama.com/download/windows
# Or:
scoop bucket add extras
scoop install ollama

# Note: mise on Windows — add to PowerShell profile:
# Invoke-Expression (&mise activate powershell)
```

**Windows users:** After Phase 0b, continue with Phase 1 inside your chosen environment (WSL2 terminal or PowerShell).

---

## PHASE 1 — Foundation
**Estimated time: 15 minutes**
**Ask user for confirmation before starting.**

### 1.1 Package Manager

#### Mac
```bash
if ! command -v brew &>/dev/null; then
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  # Apple Silicon path:
  if [[ "$ARCH" == "arm64" ]]; then
    echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zshrc
    eval "$(/opt/homebrew/bin/brew shellenv)"
  fi
fi
brew --version
```

#### Linux / WSL2
```bash
if ! command -v brew &>/dev/null; then
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> ~/.bashrc
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi
brew --version
```

### 1.2 Core CLI Tools

```bash
# Check and install only what's missing
TOOLS=(ripgrep fzf bat lazygit starship mise just caddy zellij duckdb)
MISSING=()
for t in "${TOOLS[@]}"; do
  command -v $t &>/dev/null || MISSING+=($t)
done

if [[ ${#MISSING[@]} -gt 0 ]]; then
  echo "Installing: ${MISSING[*]}"
  brew install "${MISSING[@]}"
else
  echo "✓ All core tools already installed"
fi

# fzf shell integration
[[ -f "$(brew --prefix)/opt/fzf/install" ]] && \
  "$(brew --prefix)/opt/fzf/install" --all --no-update-rc 2>/dev/null || true
```

### 1.3 Shell Configuration

Show user the following additions and ask permission before writing:

```bash
# Detect shell config file
if [[ "$OS" == "Darwin" ]]; then
  SHELL_RC="$HOME/.zshrc"
else
  SHELL_RC="$HOME/.bashrc"
fi

# Lines to add (only if not already present)
add_if_missing() {
  local line="$1"
  grep -qF "$line" "$SHELL_RC" 2>/dev/null || echo "$line" >> "$SHELL_RC"
}

add_if_missing 'eval "$(starship init zsh)"'        # or bash
add_if_missing 'eval "$(mise activate zsh)"'         # or bash
add_if_missing 'source <(fzf --zsh)'                 # or --bash
add_if_missing 'alias cat="bat"'
add_if_missing 'alias grep="rg"'
add_if_missing 'export PATH="$HOME/.npm-global/bin:$PATH"'
add_if_missing 'export PATH="$HOME/.local/bin:$PATH"'

echo "✓ Shell config updated"
```

### 1.4 Runtime Versions (via mise)

```bash
mise install node@lts    2>&1 | tail -3
mise install python@3.12 2>&1 | tail -3   # 3.12 not 3.14 — best wheel compatibility
mise install bun@latest  2>&1 | tail -3

echo "--- Verification ---"
mise list
```

> **Note:** Python 3.12 is specified intentionally. Python 3.14 breaks numpy/scipy wheel installs (affects aider, markitdown).

### 1.5 Python Package Tools

```bash
# Use the mise-managed python 3.12
PYTHON=$(mise which python 2>/dev/null || command -v python3)
PIP="$PYTHON -m pip"

command -v uv   &>/dev/null || $PIP install uv   --break-system-packages
command -v pipx &>/dev/null || $PIP install pipx --break-system-packages
pipx ensurepath 2>/dev/null || true

uv --version
pipx --version
```

**Phase 1 complete. Log to SETUP_LOG_V2.md.**

---

## PHASE 2 — AI Tools
**Estimated time: 15 minutes**
**Requires: Phase 1 complete**

### 2.1 Claude Code

```bash
if ! command -v claude &>/dev/null; then
  npm install -g @anthropic-ai/claude-code
fi
claude --version
echo "→ Manual step queued: claude login"
```

### 2.2 Ollama + Auto-Selected Models

```bash
# Install Ollama
if ! command -v ollama &>/dev/null; then
  if [[ "$OS" == "Darwin" ]]; then
    brew install ollama
  else
    curl -fsSL https://ollama.com/install.sh | sh
  fi
fi

# Start service
if [[ "$OS" == "Darwin" ]]; then
  brew services start ollama
else
  systemctl --user start ollama 2>/dev/null || ollama serve &>/dev/null &
fi

sleep 3

# Pull auto-selected models (PRIMARY and FAST set during Step 0)
# If Step 0 wasn't run, default to safe 16GB profile
PRIMARY=${PRIMARY:-"qwen3:8b"}
FAST=${FAST:-"llama3.2:3b"}

echo "Pulling primary model: $PRIMARY"
ollama pull "$PRIMARY"

echo "Pulling fast model: $FAST"
ollama pull "$FAST"

ollama list
```

### 2.3 Codex CLI

```bash
# Set npm global prefix to avoid sudo
mkdir -p ~/.npm-global
npm config set prefix ~/.npm-global

if ! command -v codex &>/dev/null && [[ ! -f ~/.npm-global/bin/codex ]]; then
  npm install -g @openai/codex
fi
~/.npm-global/bin/codex --version 2>/dev/null || codex --version
echo "→ Manual step queued: codex login (run 'codex' and sign in via browser)"
```

### 2.3a Codex Plugin for Claude Code

```bash
echo "=== Codex Plugin for Claude Code ==="
echo "→ MANUAL STEP QUEUED — must run inside a 'claude' CLI session:"
echo "   /plugin marketplace add openai/codex-plugin-cc"
echo "   /plugin install codex@openai-codex"
echo "   /reload-plugins"
echo "   /codex:setup"
echo "(Requires Codex CLI installed and authenticated first)"
```

### 2.4 Aider

```bash
if ! command -v aider &>/dev/null; then
  # Use uv with Python 3.12 — avoids scipy/numpy wheel issues on 3.14
  uv tool install aider-chat --python 3.12
fi
aider --version

# Write aider config using auto-detected primary model
PRIMARY=${PRIMARY:-"qwen3:8b"}
cat > ~/.aider.conf.yml << EOF
# Aider config — local Ollama (free, no API key needed)
model: ollama/$PRIMARY
auto-commits: false
pretty: true
EOF
echo "✓ Aider configured with ollama/$PRIMARY"
```

### 2.5 API Keys (placeholders — subscription auth preferred)

```bash
# Detect shell config file
SHELL_RC="${HOME}/.zshrc"
[[ "$OS" == "Linux" ]] && SHELL_RC="${HOME}/.bashrc"

add_if_missing() {
  grep -qF "$1" "$SHELL_RC" 2>/dev/null || echo "$1" >> "$SHELL_RC"
}

# Only add if not already present
if ! grep -q "ANTHROPIC_API_KEY" "$SHELL_RC" 2>/dev/null; then
  add_if_missing '# AI API Keys (only needed for aider API mode — Claude Code uses OAuth)'
  add_if_missing 'export ANTHROPIC_API_KEY="your_anthropic_key_here"'
  add_if_missing 'export OPENAI_API_KEY="your_openai_key_here"'
  echo "⚠️  Placeholder API key lines added to $SHELL_RC"
  echo "    Claude Code and Codex use subscription OAuth — keys only needed for aider API mode"
fi
```

**Phase 2 complete. Log to SETUP_LOG_V2.md.**

---

## PHASE 3 — Agent Orchestration
**Estimated time: 15 minutes**
**Requires: Phase 2 complete**

### 3.1 Ruflo MCP

```bash
# Register Ruflo as MCP server
claude mcp list 2>/dev/null | grep -q "ruflo" && \
  echo "✓ Ruflo MCP already registered" || \
  claude mcp add ruflo -- npx ruflo@latest mcp start

# Initialize Ruflo (non-interactive swarm template)
npx ruflo@latest init -n "dev-environment" -t swarm 2>/dev/null || \
  echo "→ Manual step queued: npx ruflo@latest init wizard (if ruflo init needed)"

claude mcp list 2>/dev/null | grep ruflo
```

### 3.2 Ruflo Plugins

```bash
echo "=== Ruflo Plugins ==="
echo "→ MANUAL STEP QUEUED — must run inside a 'claude' CLI session:"
echo "   /plugin marketplace add ruvnet/ruflo"
echo "   /plugin install ruflo-core@ruflo"
echo "   /plugin install ruflo-swarm@ruflo"
echo "   /plugin install ruflo-rag-memory@ruflo"
echo "   /plugin install ruflo-cost-tracker@ruflo"
echo "   /plugin install ruflo-observability@ruflo"
echo "   /plugin install ruflo-aidefence@ruflo"
echo "   /plugin install ruflo-docs@ruflo"
echo "   /plugin install ruflo-autopilot@ruflo"
```

### 3.3 autoskills

```bash
command -v autoskills &>/dev/null || npm install -g autoskills
echo "✓ autoskills available — run 'npx autoskills' in any project"
```

### 3.4 antigravity-awesome-skills

```bash
if [[ ! -d ~/.claude/skills ]] || [[ $(ls ~/.claude/skills 2>/dev/null | wc -l) -lt 100 ]]; then
  npx antigravity-awesome-skills --claude 2>&1 | tail -5
else
  echo "✓ Skills already installed ($(ls ~/.claude/skills | wc -l) dirs)"
fi
```

### 3.5 agency-agents

```bash
if [[ ! -d ~/.claude/agents ]] || [[ $(ls ~/.claude/agents 2>/dev/null | wc -l) -lt 10 ]]; then
  git clone https://github.com/msitarzewski/agency-agents /tmp/agency-agents 2>&1 | tail -3
  bash /tmp/agency-agents/scripts/install.sh --tool claude-code 2>&1 | tail -5
else
  echo "✓ Agents already installed ($(ls ~/.claude/agents | wc -l) agents)"
fi
```

### 3.6 Design Skills

```bash
npx skills add pbakaus/impeccable  2>&1 | tail -3
npx skills add emilkowalski/skill  2>&1 | tail -3
echo "→ Manual step queued: run /teach-impeccable once per new project"
```

### 3.7 flow-nexus MCP

```bash
echo "=== Flow Nexus ==="
echo "→ MANUAL STEP QUEUED — run in terminal:"
echo "   npx flow-nexus@latest init -n 'dev-environment' -t swarm --claude"
echo "   Select: Local development only (no account)"
```

**Phase 3 complete. Log to SETUP_LOG_V2.md.**

---

## PHASE 4 — Knowledge Base
**Estimated time: 10 minutes**

### 4.1 Vault Structure

```bash
VAULT="$HOME/vault"
mkdir -p "$VAULT"/{raw,wiki,playbooks,templates,agents,daily,projects}
echo "✓ Vault at $VAULT"
ls "$VAULT"
```

### 4.2 vault/AGENTS.md

```bash
cat > "$HOME/vault/AGENTS.md" << 'EOF'
# Vault Agent Guide

## What This Vault Is
Personal knowledge base. Plain markdown. Git-versionable. MCP-accessible to Claude.

## Folder Structure
- raw/       → Source documents, imported PDFs (never edit)
- wiki/      → Processed notes, research summaries
- playbooks/ → Claude-executable SKILL.md workflows
- templates/ → Note templates with frontmatter
- agents/    → Agent persona definitions
- daily/     → Daily notes, capture inbox
- projects/  → One subfolder per project — CONTEXT.md as entry point

## Frontmatter Standard
---
title: Note Title
date_added: YYYY-MM-DD
tags: []
status: draft | active | archived
type: research | runbook | project | reference
importance: low | medium | high
source: filename or URL
---

## Naming
- wiki/: kebab-case (my-research-topic.md)
- projects/: project-name/CONTEXT.md
- templates/: TEMPLATE-name.md

## Rules
- Never modify raw/ — source documents only
- Never delete daily/ — they are the research log
- Check with user before modifying projects/
EOF
echo "✓ vault/AGENTS.md written"
```

### 4.3 MCP Server — Vault

```bash
claude mcp list 2>/dev/null | grep -q "vault" && \
  echo "✓ Vault MCP already registered" || \
  claude mcp add vault --scope user -- npx -y @modelcontextprotocol/server-filesystem "$HOME/vault"
```

### 4.4 Note Templates

```bash
cat > "$HOME/vault/templates/TEMPLATE-research.md" << 'EOF'
---
title: {{title}}
date_added: {{date}}
tags: []
status: draft
type: research
importance: medium
source:
---

## Summary

## Key Findings

## Open Questions

## Sources
-

## Related Notes
-
EOF

cat > "$HOME/vault/templates/TEMPLATE-project.md" << 'EOF'
---
title: {{title}} — Project Context
date_added: {{date}}
tags: []
status: active
type: project
importance: high
source:
---

## What We're Building

## Tech Stack

## Key Decisions

## Current Status

## Next Steps

## Reference Links
-
EOF

echo "✓ Templates created"
```

### 4.5 markitdown

```bash
command -v markitdown &>/dev/null && \
  echo "✓ markitdown already installed" || \
  pip3 install markitdown --break-system-packages 2>&1 | tail -3
markitdown --version 2>/dev/null || echo "markitdown installed"
```

**Phase 4 complete. Log to SETUP_LOG_V2.md.**

---

## PHASE 5 — App Building & Security Tools
**Estimated time: 10 minutes**

### 5.1 Security Scanners

```bash
SECURITY_TOOLS=(gitleaks trivy semgrep)
MISSING=()
for t in "${SECURITY_TOOLS[@]}"; do
  command -v $t &>/dev/null || MISSING+=($t)
done
[[ ${#MISSING[@]} -gt 0 ]] && brew install "${MISSING[@]}" || echo "✓ Security tools already installed"

gitleaks version && trivy --version | head -1 && semgrep --version
```

### 5.2 Global gitleaks Pre-Commit Hook

```bash
if [[ ! -f ~/.git-hooks/pre-commit ]]; then
  git config --global core.hooksPath ~/.git-hooks
  mkdir -p ~/.git-hooks
  cat > ~/.git-hooks/pre-commit << 'HOOK'
#!/bin/sh
gitleaks protect --staged --no-banner
HOOK
  chmod +x ~/.git-hooks/pre-commit
  echo "✓ gitleaks pre-commit hook installed globally"
else
  echo "✓ Pre-commit hook already installed"
fi
```

### 5.3 Infisical (Secrets Management)

```bash
if ! command -v infisical &>/dev/null; then
  brew install infisical 2>/dev/null || npm install -g @infisical/cli
fi
infisical --version
echo "→ Manual step queued: infisical login (run once, then 'infisical init' per project)"
```

### 5.4 spec-kit

```bash
command -v specify &>/dev/null && echo "✓ spec-kit already installed" || \
  uv tool install specify-cli --from git+https://github.com/github/spec-kit.git 2>&1 | tail -3
```

### 5.5 PocketBase

```bash
command -v pocketbase &>/dev/null && echo "✓ PocketBase already installed" || \
  brew install pocketbase 2>/dev/null || echo "PocketBase: manual install at pocketbase.io"
pocketbase --version 2>/dev/null
```

### 5.6 newproject Command

```bash
mkdir -p ~/.local/bin
if [[ ! -f ~/.local/bin/newproject ]]; then
cat > ~/.local/bin/newproject << 'SCRIPT'
#!/bin/bash
NAME=${1:-my-project}
mkdir -p "$NAME" && cd "$NAME"
git init
npx autoskills 2>/dev/null || true
specify init . --integration claude-code 2>/dev/null || true
mkdir -p .claude
cat > .claude/CLAUDE.md << EOF
# $NAME

## Project Overview
[Describe what this project does]

## Tech Stack
[List technologies used]

## IRON RULES
- Never commit API keys or secrets
- Always run tests before marking tasks complete
- Use uv for Python, bun for JS
- Run /codex:adversarial-review on any plan before implementing
EOF
infisical init 2>/dev/null || true
echo "✓ Project $NAME initialized — cd $NAME && claude"
SCRIPT
chmod +x ~/.local/bin/newproject
echo "✓ newproject command installed"
else
  echo "✓ newproject already installed"
fi
```

**Phase 5 complete. Log to SETUP_LOG_V2.md.**

---

## PHASE 6 — Global CLAUDE.md
**Ask user: name, role, and primary use cases before writing.**

```bash
# Claude: collect from user before running:
# - NAME (first name)
# - ROLE (e.g. Developer / Researcher / Builder)
# - USE_CASE_1, USE_CASE_2, USE_CASE_3
# Then substitute below.

# Detect primary and fast models from Step 0 (or use defaults)
PRIMARY=${PRIMARY:-"qwen3:8b"}
FAST=${FAST:-"llama3.2:3b"}
RAM_GB=${RAM_GB:-16}

mkdir -p ~/.claude
cat > ~/.claude/CLAUDE.md << EOF
# Global Claude Code Context

## Who I Am
Name: [NAME]
Role: [ROLE]
Primary use cases:
1. [USE_CASE_1]
2. [USE_CASE_2]
3. [USE_CASE_3]

## My Machine
- $(uname -m) — $(sysctl -n machdep.cpu.brand_string 2>/dev/null || uname -s)
- RAM: ${RAM_GB}GB
- OS: $(uname -s) $(uname -r)
- Shell: $(basename $SHELL) with starship prompt

## My Tech Stack
- Runtimes: Node LTS, Python 3.12, Bun (via mise)
- Package managers: uv (Python), bun/npm (JS)
- AI tools: Claude Code, Codex CLI, Aider (local Ollama), Ollama
- Agent orchestration: Ruflo + ruv-swarm
- Knowledge base: Obsidian vault at ~/vault/
- Secrets: Infisical (replaces .env files)
- Version control: git with gitleaks pre-commit hook

## Available MCP Servers
- vault: ~/vault/ — personal knowledge base
- ruflo: multi-agent orchestration
- ruv-swarm: swarm-mode agent coordination

## Installed Skills
- antigravity-awesome-skills: 1,400+ skills across security, DevOps, observability
- impeccable: typography, layout, anti-pattern enforcement
- emilkowalski/skill: motion and animation
- agency-agents: 200+ specialized agent personas at ~/.claude/agents/

## How I Work Best
- Show me what you're going to do before doing it
- Ask before modifying existing files
- Batch related tasks into one message
- Use /goal for autonomous tasks with a clear finish line
- Prefer uv for Python deps, bun for JS deps
- Spec-kit workflow for new projects: specify → clarify → plan → tasks → implement

## IRON RULES
- Never commit secrets, API keys, or credentials
- Never run destructive operations without confirmation
- Always run gitleaks protect --staged before committing
- Run /codex:adversarial-review on any plan longer than 5 steps before implementing
- Spend 30-90 minutes planning before writing code — implementation is the easy part

## Model Selection Guide
- Claude Code: copywriting, design thinking, architecture, creative coding patterns (Claude Pro subscription)
- Codex: surgical precision, targeted changes, auditing, plan review (ChatGPT Plus subscription)
- Aider: ollama/${PRIMARY} by default — free, local, no quota
- Free fallback: ollama run ${FAST} — fastest local inference

## Claude + Codex Dynamic Duo Patterns
- Pattern 1 — Code Review: /codex:review (read-only, non-steerable)
- Pattern 2 — Adversarial Planning: /codex:adversarial-review [plan] (devil's advocate before building)
- Pattern 3 — Background Audit: /codex:rescue --background (Codex audits, Claude keeps building)
- Pattern 4 — Pre-Ship Gate: /codex:rescue (security, privacy, data exposure before shipping)
- Pattern 5 — Full Loop: Claude plans → Codex reviews → Claude refines → repeat → implement

## Codex Slash Commands
- /codex:review — read-only code audit
- /codex:adversarial-review — targeted plan review
- /codex:rescue — full codebase audit (add --background to run async)
- /codex:status / /codex:result — check and retrieve background jobs

## Auth Notes
- Claude Code: Claude Pro OAuth (not API key)
- Codex CLI: ChatGPT Plus OAuth (not API key)
- Aider: local Ollama (free) — API keys optional
- Subscription quotas shared with web usage — heavy web chat reduces CLI quota

## Knowledge Base
Vault at ~/vault/ — use MCP server to read/write notes
AGENTS.md at ~/vault/AGENTS.md describes vault structure

## Ruflo Integration
When working on multi-file tasks, use ToolSearch to find and invoke ruflo MCP tools.
Key tools: memory_store, memory_search, hooks_route, swarm_init, agent_spawn.
EOF

echo "✓ ~/.claude/CLAUDE.md written"
```

**Phase 6 complete. Log to SETUP_LOG_V2.md.**

---

## PHASE 7 — MANUAL STEPS (batched)
**All manual actions collected here — present to user after all automated phases complete.**

Claude: Display this checklist to the user and do not proceed until acknowledged.

```bash
echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║          MANUAL STEPS REQUIRED — Complete in Order           ║"
echo "╠══════════════════════════════════════════════════════════════╣"
echo "║  All automated steps are done. These require your input:     ║"
echo "╠══════════════════════════════════════════════════════════════╣"
echo "║                                                              ║"
echo "║  1. Open a fresh terminal tab (activates mise, starship,     ║"
echo "║     bun, fzf, aliases from ~/.zshrc)                        ║"
echo "║                                                              ║"
echo "║  2. claude login                                             ║"
echo "║     → Browser opens → sign in with Claude Pro account        ║"
echo "║                                                              ║"
echo "║  3. codex  (first run)                                       ║"
echo "║     → Select 'Sign in with ChatGPT' → browser auth          ║"
echo "║                                                              ║"
echo "║  4. infisical login                                          ║"
echo "║     → Then: infisical init (once per project)                ║"
echo "║                                                              ║"
echo "║  5. Open terminal → run: claude                              ║"
echo "║     Then paste these slash commands one at a time:           ║"
echo "║     /plugin marketplace add openai/codex-plugin-cc           ║"
echo "║     /plugin install codex@openai-codex                       ║"
echo "║     /reload-plugins                                          ║"
echo "║     /codex:setup                                             ║"
echo "║                                                              ║"
echo "║  6. Same claude session — Ruflo plugins:                     ║"
echo "║     /plugin marketplace add ruvnet/ruflo                     ║"
echo "║     /plugin install ruflo-core@ruflo                         ║"
echo "║     /plugin install ruflo-swarm@ruflo                        ║"
echo "║     /plugin install ruflo-rag-memory@ruflo                   ║"
echo "║     /plugin install ruflo-cost-tracker@ruflo                 ║"
echo "║     /plugin install ruflo-observability@ruflo                ║"
echo "║     /plugin install ruflo-aidefence@ruflo                    ║"
echo "║     /plugin install ruflo-autopilot@ruflo                    ║"
echo "║                                                              ║"
echo "║  7. Flow Nexus (in terminal, not inside claude):             ║"
echo "║     npx flow-nexus@latest init -n dev -t swarm --claude      ║"
echo "║     → Select: Local development only (no account)            ║"
echo "║                                                              ║"
echo "║  8. Obsidian: download from obsidian.md                      ║"
echo "║     → Open ~/vault/ as vault                                 ║"
echo "║     → Install plugins: Dataview, Templater, Git, QuickAdd    ║"
echo "║                                                              ║"
echo "║  9. ~/.zshrc: replace API key placeholders with real values  ║"
echo "║     (only needed for aider API mode — not for Claude/Codex)  ║"
echo "║                                                              ║"
echo "║  10. /teach-impeccable (once per new project, in claude)     ║"
echo "║                                                              ║"
echo "╚══════════════════════════════════════════════════════════════╝"
```

---

## VALIDATION — Run after all phases + manual steps complete

```bash
echo "=== Setup Validation ==="

TOOLS=(brew node bun python3 uv mise rg fzf bat lazygit starship zellij
       duckdb just caddy gitleaks trivy semgrep infisical pocketbase
       markitdown claude aider ollama)
PASS=0; FAIL=0
for t in "${TOOLS[@]}"; do
  if command -v $t &>/dev/null; then
    echo "✓ $t"
    (( PASS++ ))
  else
    echo "✗ $t — NOT FOUND"
    (( FAIL++ ))
  fi
done

echo ""
echo "=== MCP Servers ==="
claude mcp list 2>/dev/null

echo ""
echo "=== Ollama Models ==="
ollama list 2>/dev/null

echo ""
echo "=== Vault ==="
ls ~/vault/ 2>/dev/null

echo ""
echo "=== CLAUDE.md ==="
[[ -f ~/.claude/CLAUDE.md ]] && echo "✓ Global CLAUDE.md exists" || echo "✗ Missing"

echo ""
echo "=== Skills & Agents ==="
echo "Skills: $(ls ~/.claude/skills/ 2>/dev/null | wc -l)"
echo "Agents: $(ls ~/.claude/agents/ 2>/dev/null | wc -l)"

echo ""
echo "Results: $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]] && echo "✓ Setup complete!" || echo "⚠ $FAIL tools missing — check errors above"
```

---

## QUICK REFERENCE — Daily Commands

```bash
# New project (full scaffold)
newproject my-app-name && cd my-app-name && claude

# Convert any file to markdown for Claude
markitdown document.pdf > ~/vault/raw/document.md

# Search vault
rg "search term" ~/vault/

# Claude + Codex dynamic duo
/codex:adversarial-review [plan]  # review plan before building
/codex:rescue --background        # full audit in background
/codex:status                     # check background job
/codex:result                     # get results

# Security before commit
gitleaks protect --staged
trivy fs .
semgrep --config=p/security .

# Local AI (free, no quota)
aider                             # uses auto-selected Ollama model
ollama run qwen3:8b               # direct REPL

# Runtime management
mise list
mise use node@22                  # switch version for current project

# Packages
uv pip install X                  # Python
bun add X                         # JavaScript

# Data
duckdb -c "SELECT * FROM 'file.csv' LIMIT 10"
```

---

## ECONOMICS

| Tool | Auth | Monthly | Primary use |
|------|------|---------|-------------|
| Claude Code | Claude Pro OAuth | $20 | Daily driver — coding, design, architecture |
| Codex CLI | ChatGPT Plus OAuth | $20 | Auditing, adversarial review, surgical edits |
| Aider | None (local Ollama) | $0 | Free fallback when quota is low |
| Ollama | None | $0 | Always-free local inference |
| **Total** | | **$40** | |

Codex is used primarily for auditing — the $20 plan is sufficient.
API keys in `~/.zshrc` are for aider API mode only — Claude Code and Codex use OAuth.

---

## LLM SELECTION REFERENCE

| RAM | Apple Silicon | NVIDIA GPU | CPU Only |
|-----|--------------|------------|----------|
| 8 GB | llama3.2:3b | phi4-mini | llama3.2:3b |
| 16 GB | **qwen3:8b** + llama3.2:3b | **qwen3:8b** + llama3.2:3b | llama3.2:3b |
| 32 GB | **qwen3:14b** + qwen3:8b | **qwen3:14b** + qwen3:8b | qwen3:8b |
| 64 GB+ | **qwen3:32b** + qwen3:14b | **qwen3:32b** + qwen3:14b | qwen3:14b |

Bold = primary model set in `~/.aider.conf.yml` and CLAUDE.md.
