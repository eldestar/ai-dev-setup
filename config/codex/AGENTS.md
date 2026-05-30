# Codex Project Instructions

When working in this repository, prioritize installer correctness, idempotency, and platform-specific validation.

## Review Focus

- Cross-platform command compatibility.
- Rerun behavior and backups.
- Clear manual fallback steps.
- Avoiding unnecessary Claude/Codex usage for basic setup.
- Shell quoting and path handling.

## Validation Commands

```bash
./install.sh --dry-run --verbose
```

```powershell
.\install.ps1 -DryRun -VerboseLogging
```
