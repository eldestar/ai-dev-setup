# ai-dev-setup

Personal AI dev environment setup — deployable on any Mac or Windows device.

## What This Is

A single executable spec (`SETUP_V2.md`) that Claude Code reads and runs to configure a full AI-assisted development environment from scratch. Designed to be re-runnable: checks before installing, skips what's already present, fixes what's wrong.

## What Gets Installed

| Category | Tools |
|----------|-------|
| Shell | starship, fzf, bat, lazygit, zellij, mise |
| Runtimes | Node LTS, Python 3.12, Bun (via mise) |
| Package managers | uv, pipx, bun, npm |
| AI coding | Claude Code, Codex CLI, Aider, Ollama |
| Local LLMs | Auto-selected based on device RAM + GPU |
| Agent orchestration | Ruflo, ruv-swarm, flow-nexus |
| Skills & agents | 1,400+ skills, 200+ agent personas |
| Knowledge base | ~/vault/ structure + MCP server + Obsidian templates |
| Security | gitleaks (pre-commit hook), trivy, semgrep |
| Secrets | Infisical |
| App building | PocketBase, Caddy, spec-kit, newproject command |

## Quick Start (New Device)

### Prerequisites
```bash
# Mac — install Claude Code first
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
brew install node
npm install -g @anthropic-ai/claude-code
claude login
```

### Run Setup
```bash
git clone https://github.com/eldestar/ai-dev-setup.git
cd ai-dev-setup
claude "Read SETUP_V2.md, run system detection first and report findings,
then execute all phases in order. Ask me before each phase starts.
Collect all manual steps and present them together at the end.
Log everything to SETUP_LOG_V2.md."
```

### Re-run on Existing Device (fix / update)
```bash
git pull
claude "Read SETUP_V2.md, run system detection, check each phase and fix
only what's missing or wrong. Skip anything correctly installed.
Log changes to SETUP_LOG_V2.md."
```

## Platform Support

| Platform | Status | Path |
|----------|--------|------|
| macOS Apple Silicon | ✓ Primary | Homebrew + zsh |
| macOS Intel | ✓ Supported | Homebrew + zsh |
| Windows (WSL2) | ✓ Supported | Linuxbrew + bash |
| Windows (Native) | ⚠ Partial | Scoop + PowerShell |

## Local LLM Selection

Automatically detected from RAM + GPU at setup time:

| RAM | Apple Silicon | NVIDIA GPU | CPU Only |
|-----|--------------|------------|----------|
| 8 GB | llama3.2:3b | phi4-mini | llama3.2:3b |
| 16 GB | qwen3:8b | qwen3:8b | llama3.2:3b |
| 32 GB | qwen3:14b | qwen3:14b | qwen3:8b |
| 64 GB+ | qwen3:32b | qwen3:32b | qwen3:14b |

## Workflow Patterns

**Claude + Codex Dynamic Duo:**
```
/codex:adversarial-review [plan]   # stress-test before building
/codex:rescue --background         # full audit while you keep working
/codex:result                      # retrieve audit
```

**Full planning loop:** Claude plans → `/codex:adversarial-review` → Claude refines → repeat until Codex has no issues → implement.

## Files

| File | Purpose |
|------|---------|
| `SETUP_V2.md` | Executable setup spec — feed to Claude Code |
| `CHANGELOG.md` | What changed between versions |

## Economics

| Tool | Auth | Cost |
|------|------|------|
| Claude Code | Claude Pro OAuth | $20/mo |
| Codex CLI | ChatGPT Plus OAuth | $20/mo |
| Aider + Ollama | None | Free |

---

*Feed `SETUP_V2.md` to Claude Code. It does the rest.*
