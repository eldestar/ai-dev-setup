# Installer Architecture

## Recommendation

Use a feature branch in `eldestar/ai-dev-setup` rather than a standalone repository.

Reasons:

- The existing repo already targets AI development environment bootstrap workflows.
- The requested outcome is an evolution from an AI-executed setup spec to an external installer.
- Keeping the work on `feature/claude-codex-installer` preserves the current `main` behavior while making review straightforward.
- The new directory structure cleanly separates installer logic, platform logic, assets, templates, and docs.

## Entry Points

- `install.ps1`: Windows-first entry point for PowerShell 5.1+ and PowerShell 7+.
- `install.sh`: bash/zsh-compatible entry point for macOS, Linux, and WSL2.

Both entry points support dry-run mode, verbose logging, confirmation prompts, non-interactive `yes` mode, final summary output, and local logs under `logs/`.

## Installer Flow

1. Detect operating system, architecture, shells, package managers, Git, Node/npm, Claude Code, and Codex CLI.
2. Install or guide platform prerequisites.
3. Install shared assets.
4. Install or validate Claude Code.
5. Install Claude-specific assets.
6. Install or validate Codex CLI.
7. Install Codex-specific assets.
8. Print manual fallback steps, errors, and validation status.

## Asset Destinations

| Asset type | Destination |
| --- | --- |
| Shared config/templates | `~/.ai-dev-setup/` |
| Project instructions | `AGENTS.md` in target root or installer root |
| Claude assets | `~/.claude/ai-dev-setup/`, `~/.claude/agents/ai-dev-setup/`, `~/.claude/skills/ai-dev-setup/` |
| Codex assets | `${CODEX_HOME:-~/.codex}/ai-dev-setup/`, `${CODEX_HOME:-~/.codex}/agents/`, `${CODEX_HOME:-~/.codex}/goals/` |

Existing destinations are backed up before replacement unless the user skips the action.
