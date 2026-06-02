# Changelog

## v2.4.0 — 2026-06-02 — P0 Sprint 3 (preflight, tests, CI, docs)
### Added
- `scripts/doctor.{sh,ps1}`: read-only preflight + skill/agent audit vs the lock. `runners/install.ps1 -Check` runs it.
- `tests/smoke.{sh,ps1}`: fast validation gate (JSON / CSV headers / PS parse / template render / model selection / single-source drift). Green on both shells.
- `.github/workflows/ci.yml`: shellcheck + bash smoke, PSScriptAnalyzer + pwsh smoke, gitleaks.
- File logging: the Windows installer tees to `~/.ai-dev-setup/logs/install-<timestamp>.log` (Start-Transcript).
- Docs: `SECURITY.md`, `docs/COMPONENT_MATRIX.md`, `docs/UNINSTALL.md`, `docs/TROUBLESHOOTING.md`, `docs/SELF_IMPROVEMENT.md`, `docs/adr/0001-p0-foundation.md`.
### Notes
- P0 foundation complete (Sprints 0–3). End-to-end install validation still depends on a real run / CI execution.

## v2.3.0 — 2026-06-02 — P0 Sprint 1-2 (single source of truth + pinned skill allowlist)
### Added
- Single source of truth: `config/models.csv`, `config/tools.csv`, `templates/CLAUDE.md.tmpl` — consumed by BOTH installers (SETUP.md ↔ setup-windows.ps1 drift eliminated).
- `setup-windows.ps1` is now a thin bootstrap that ensures git, clones the repo to `$HOME/ai-dev-setup`, and runs `runners/install.ps1`.
- `skills-lock.json` v2: authoritative pinned allowlist (skills, agents, plugins, MCP) at commit SHAs.
- `scripts/install-skills.{sh,ps1}`: install ONLY the allowlist — clone at pinned SHA, copy, **SHA-256 verify** skills; print plugin/MCP commands. Tailored per OS (`shasum`/`sha256sum` vs `Get-FileHash`). Verified end-to-end on both, incl. a hash-mismatch negative test.
- `.gitattributes` for line-ending consistency.
### Changed
- Both installers read model tiers / tool list / CLAUDE.md from the single-source files instead of inline copies; the curated allowlist replaces the removed bulk install.

## v2.2.0 — 2026-06-01 — P0 Sprint 0 (stop the bleeding)
### Removed
- Bulk skill install (`antigravity-awesome-skills`, ~1,443 unvetted files) — replaced by a curated, pinned, SHA-verified allowlist (`skills-lock.json`).
- Bulk agent install (`agency-agents`, ~184 unpinned personas) — replaced by a reviewed, pinned subset.
- `flow-nexus` (cloud/credits MCP that was failing to connect).
### Fixed
- Stale doc claiming Python 3.14.5 installed (the design pins 3.12).
- PowerShell `cat`/`grep` aliases no longer use `-Option AllScope -Force` (could override commands inside scripts).
### Notes
- Personal-use project; see the P0 review docs for the full hardening plan. Skills/agents allowlist wiring lands in Sprint 2.

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
