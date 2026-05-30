# Final Validation Checklist

Run this after setup on each target machine.

## Environment

```bash
git --version
node --version
npm --version
```

## Claude Code

```bash
claude --version
claude login
```

Confirm assets exist:

```bash
ls ~/.claude/agents/setup-orchestrator.md
ls ~/.claude/skills/installer-maintenance
ls ~/.claude/commands/adversarial-codex-review.md
```

## Codex CLI

```bash
codex --version
codex login
```

Confirm assets exist:

```bash
ls "${CODEX_HOME:-$HOME/.codex}/agents/installer-reviewer.toml"
ls "$HOME/.agents/skills/installer-maintenance"
```

## Shared Assets

```bash
ls ~/.ai-dev-setup/shared/config
ls ~/.ai-dev-setup/shared/templates
```

## Rerun Safety

Run the installer twice:

```bash
./install.sh --dry-run --verbose
./install.sh
```

On Windows:

```powershell
.\install.ps1 -DryRun -VerboseLogging
.\install.ps1
```

Confirm the second run skips or backs up existing destinations instead of silently overwriting them.

Automated Windows sandbox scenarios:

```powershell
.\scripts\tests\test-install.ps1
.\scripts\tests\test-extensions.ps1
```

The first test uses mocked commands and isolated temporary home/project paths to exercise neither-installed, Claude-only, Codex-only, and both-installed states without touching real user configuration. The second runs native Claude/Codex extension validators and exercises Codex marketplace installation in an isolated temporary `CODEX_HOME`.

## Isolated Sandbox Install

Use a temporary home and project directory to exercise real asset copying without touching existing user configuration.

```bash
./install.sh --yes --user-home="$PWD/work/test-home" --target-root="$PWD/work/test-project"
```

On Windows:

```powershell
.\install.ps1 -Yes -UserHome .\work\test-home -TargetRoot .\work\test-project
```
