---
name: cross-platform-installer-refactor
description: Workflow command scaffold for cross-platform-installer-refactor in ai-dev-setup.
allowed_tools: ["Bash", "Read", "Write", "Grep", "Glob"]
---

# /cross-platform-installer-refactor

Use this workflow when working on **cross-platform-installer-refactor** in `ai-dev-setup`.

## Goal

Refactor both Windows and Unix (bash) installer paths to consume shared logic or config, ensuring feature parity and eliminating drift.

## Common Files

- `setup-windows.ps1`
- `runners/install.ps1`
- `SETUP.md`
- `runners/lib/common.ps1`

## Suggested Sequence

1. Understand the current state and failure mode before editing.
2. Make the smallest coherent change that satisfies the workflow goal.
3. Run the most relevant verification for touched files.
4. Summarize what changed and what still needs review.

## Typical Commit Signals

- Update or refactor setup-windows.ps1 (Windows bootstrap) to delegate to runners/install.ps1.
- Update runners/install.ps1 to consume new config or logic.
- Update SETUP.md (bash path) to consume the same config or logic.
- Verify that both installer paths (PowerShell and bash) produce the same results.
- Test parsing and selection logic on both platforms.

## Notes

- Treat this as a scaffold, not a hard-coded script.
- Update the command if the workflow evolves materially.