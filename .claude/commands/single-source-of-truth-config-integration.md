---
name: single-source-of-truth-config-integration
description: Workflow command scaffold for single-source-of-truth-config-integration in ai-dev-setup.
allowed_tools: ["Bash", "Read", "Write", "Grep", "Glob"]
---

# /single-source-of-truth-config-integration

Use this workflow when working on **single-source-of-truth-config-integration** in `ai-dev-setup`.

## Goal

Integrate a new configuration source (models, tools, templates) and refactor all consumers (installers, docs) to use it, eliminating drift and duplication.

## Common Files

- `config/models.csv`
- `config/tools.csv`
- `templates/CLAUDE.md.tmpl`
- `runners/install.ps1`
- `runners/lib/common.ps1`
- `setup-windows.ps1`

## Suggested Sequence

1. Understand the current state and failure mode before editing.
2. Make the smallest coherent change that satisfies the workflow goal.
3. Run the most relevant verification for touched files.
4. Summarize what changed and what still needs review.

## Typical Commit Signals

- Add or update config file(s) (e.g., config/models.csv, config/tools.csv, templates/CLAUDE.md.tmpl).
- Update or refactor installer scripts (e.g., runners/install.ps1, setup-windows.ps1, SETUP.md) to consume the new config.
- Update documentation (e.g., config/README.md, README.md, SETUP.md) to reference or explain the config.
- Remove or deduplicate any inline or duplicated tables/lists in scripts and docs.
- Test all installer paths to verify the config is correctly consumed.

## Notes

- Treat this as a scaffold, not a hard-coded script.
- Update the command if the workflow evolves materially.