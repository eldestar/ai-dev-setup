# Uninstall

The installer is user-scoped (no sudo). Removal is manual and safe. Pick what you want to remove.

## Skills & agents (from the pinned allowlist)
```bash
# macOS / Linux
rm -rf ~/.claude/skills/emil-design-eng ~/.claude/skills/impeccable
rm -f  ~/.claude/agents/wshobson-*.md ~/.claude/agents/dlezo-*.md ~/.claude/agents/voltagent-*.md
```
```powershell
# Windows
Remove-Item "$HOME\.claude\skills\emil-design-eng","$HOME\.claude\skills\impeccable" -Recurse -Force
Remove-Item "$HOME\.claude\agents\wshobson-*.md","$HOME\.claude\agents\dlezo-*.md","$HOME\.claude\agents\voltagent-*.md" -Force
```
> Run `scripts/doctor.*` first to see exactly what is installed (and any older bulk-installed
> skills not in the lock — those can be removed by clearing `~/.claude/skills`).

## MCP servers
```bash
claude mcp remove vault
claude mcp remove ruflo
```

## CLAUDE.md and vault
```bash
rm -f  ~/.claude/CLAUDE.md          # global context (regenerate by re-running the installer)
rm -rf ~/vault                       # WARNING: your knowledge base — back up first
```

## Tools
```bash
brew uninstall <tool>                # macOS / Linux
scoop uninstall <tool>               # Windows
uv tool uninstall aider-chat semgrep markitdown
npm -g uninstall @anthropic-ai/claude-code @openai/codex
```

## Git hook, profile, logs
```bash
git config --global --unset core.hooksPath   # remove the global gitleaks pre-commit hook
rm -rf ~/.ai-dev-setup/logs                   # install logs
# Remove the starship/mise/alias lines added to your shell profile (~/.zshrc, ~/.bashrc, or $PROFILE)
```

## The repo itself
```bash
rm -rf ~/ai-dev-setup
```
