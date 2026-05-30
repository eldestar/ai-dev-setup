# Project Instructions

Use this repository as an external installer for Claude Code + Codex setup work.

## Working Rules

- Prefer making installation and validation repeatable in scripts instead of asking an AI tool to perform manual setup.
- Keep platform-specific behavior in `scripts/windows/`, `scripts/macos/`, or `scripts/linux/`.
- Keep reusable logic in `scripts/common/`.
- Do not overwrite existing user configuration without a backup and confirmation.
- Every installer path should be safe to rerun.
- When automation is not safe or not possible, emit a manual step with an exact verification command.

## Validation

Before shipping setup changes, run:

```bash
./install.sh --dry-run --verbose
```

On Windows, run:

```powershell
.\install.ps1 -DryRun -VerboseLogging
```
