# Codex Configuration Notes

Codex reads project instructions from `AGENTS.md`. The installer places a project-level `AGENTS.md` in the selected target root.

This repo intentionally does not merge a generated `config.toml` into `~/.codex/config.toml`. Codex configuration keys should only be added for a concrete user requirement and must match the current official Codex configuration reference.

Native user-level extensions installed by this repo:

- skill: `~/.agents/skills/installer-maintenance/SKILL.md`
- subagent: `~/.codex/agents/installer-reviewer.toml`

Optional plugin bundle:

- `plugins/ai-dev-setup/`
