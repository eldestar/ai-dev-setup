# Extension Compatibility

Claude Code and Codex support overlapping concepts but use different native discovery paths.

## Installed Directly

| Extension | Claude Code | Codex |
| --- | --- | --- |
| Shared skill | `~/.claude/skills/installer-maintenance/SKILL.md` | `~/.agents/skills/installer-maintenance/SKILL.md` |
| Subagent | `~/.claude/agents/setup-orchestrator.md` | `${CODEX_HOME:-~/.codex}/agents/installer-reviewer.toml` |
| Project instructions | `CLAUDE.md` | `AGENTS.md` |
| Command | `~/.claude/commands/adversarial-codex-review.md` | Use the shared skill or a prompt template. |

## Optional Plugin Bundles

Plugin bundles are packaged under `plugins/` for explicit opt-in testing and future distribution. The installer does not silently register plugins or mutate a Codex marketplace.

- Claude plugin: `plugins/claude/ai-dev-setup/`
- Codex plugin: `plugins/ai-dev-setup/`

The Codex plugin manifest can be validated with:

```powershell
uv run --with pyyaml python "$HOME\.codex\skills\.system\plugin-creator\scripts\validate_plugin.py" .\plugins\ai-dev-setup
```

The shared skill can be validated with:

```powershell
uv run --with pyyaml python "$HOME\.codex\skills\.system\skill-creator\scripts\quick_validate.py" .\skills\shared\installer-maintenance
```

Validate Claude's plugin bundle natively:

```powershell
claude plugin validate .\plugins\claude\ai-dev-setup
claude --plugin-dir .\plugins\claude\ai-dev-setup plugin details ai-dev-setup
```

Register and install the Codex plugin bundle from this repo:

```powershell
codex plugin marketplace add .
codex plugin list
codex plugin add ai-dev-setup@ai-dev-setup
```

## Reference-Only Files

Recommended settings and configuration notes are copied under `~/.ai-dev-setup/reference/`. They are not automatically merged into tool config because user-level configuration should remain deliberate and version-aware.
