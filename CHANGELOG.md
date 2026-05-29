# Changelog

## v2.1.0 — 2026-05-29
### Added
- `setup-windows.ps1` — standalone Windows bootstrap script (no prerequisites needed)
  - System detection: RAM, CPU, GPU/VRAM → auto-selects Ollama primary + fast model
  - WSL2 path: clones repo + installs Node/Claude Code inside WSL2, then hands off to SETUP.md
  - Native PowerShell path: full end-to-end install via Scoop (all phases, no partial coverage)
  - Native installs: Scoop, mise, Node LTS, Python 3.12, Bun, uv, pipx, Claude Code, Codex CLI,
    Ollama (with model pulls), Aider, gitleaks, trivy, semgrep, infisical, markitdown
  - PowerShell profile: starship, mise, bat/rg aliases, PATH setup
  - Global git hooks: gitleaks pre-commit (Git for Windows sh.exe compatible)
  - MCP registration: vault + ruflo after `claude login`
  - Skills + agents install (antigravity-awesome-skills, agency-agents)
  - CLAUDE.md generated with device-specific hardware specs (CPU, RAM, GPU, VRAM)
  - Validation sweep at end; manual-steps checklist printed with all browser-auth steps
- README: Windows quick-start section with one-liner PowerShell install command
- Platform Support table updated: Windows native promoted from ⚠ Partial to ✓ Supported

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
