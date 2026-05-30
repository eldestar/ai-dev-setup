# Claude Code Project Guidance

This project builds and maintains a cross-platform setup installer for Claude Code + Codex developer environments.

## Priorities

- Keep setup outside Claude/Codex where possible.
- Make installer behavior idempotent and auditable.
- Prefer official install paths and clear manual fallback steps.
- Keep Windows support first-class while recommending WSL2 when a tool behaves better there.
- Preserve existing user configuration with backups and confirmations.

## Before Editing

- Inspect the current platform helper before adding new platform logic.
- Update docs and validation checklist when setup behavior changes.
- Run dry-run validation after modifying installer logic.
