# Changelog

## v2.0.0 — 2026-05-17
### Added
- Cross-platform support: macOS (Apple Silicon + Intel) and Windows (WSL2 + native PowerShell)
- System detection phase: auto-selects Ollama models based on RAM and GPU
- Phase 0b: Windows setup path (WSL2 recommended, Scoop native alternative)
- Phase 2.3a: Codex Plugin for Claude Code (`/codex:review`, `/codex:adversarial-review`, `/codex:rescue`)
- Phase 7: All manual steps batched and presented together at end of setup
- `add_if_missing()` function — prevents duplicate lines in shell config
- Idempotency: every install step checks before running
- Python 3.12 pinned explicitly (3.14 breaks scipy/numpy wheel installs)
- Aider auto-configured with device-appropriate Ollama model
- CLAUDE.md dynamically embeds detected RAM, CPU, primary model
- Economics section and LLM selection reference table
- `newproject` command includes `/codex:adversarial-review` reminder in CLAUDE.md template

### Changed
- Aider default model: `claude-sonnet-4-6` → `ollama/<auto-detected>` (free, no API key)
- npm prefix: `/usr/local` (root-owned) → `~/.npm-global` (user-owned, no sudo)
- Infisical install: removed dead tap, uses `brew install infisical` directly
- PocketBase: Homebrew instead of manual curl
- `newproject` command: `~/.local/bin/` instead of `/usr/local/bin/` (avoids sudo)

### Fixed
- Python 3.14 scipy/numpy incompatibility → pinned mise to Python 3.12
- npm global install permission errors → user-scoped prefix

## v1.0.0 — 2026-05-16
### Added
- Initial setup: Phases 1-6 (Foundation, AI Tools, Agent Orchestration, Knowledge Base, App Tools, CLAUDE.md)
- macOS Apple Silicon support
- Homebrew, mise, ripgrep, fzf, bat, lazygit, starship, zellij, duckdb, just, caddy
- Claude Code, Codex CLI, Aider, Ollama (qwen3:8b + llama3.2:3b)
- Ruflo MCP, ruv-swarm, vault MCP
- antigravity-awesome-skills (1,443 skills), agency-agents (184 agents)
- gitleaks global pre-commit hook, trivy, semgrep
- Infisical, PocketBase, spec-kit, markitdown
- ~/vault/ knowledge base structure + Obsidian templates
- Global ~/.claude/CLAUDE.md
