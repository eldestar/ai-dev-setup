# Claude + Codex Installer

Repo-based installer and setup system for a combined Claude Code + Codex development environment. The installer handles repeatable setup work from PowerShell or a POSIX shell so Claude/Codex credits are reserved for planning, implementation, code review, and validation.

This branch evolves the existing `eldestar/ai-dev-setup` repo instead of creating a standalone repo because this repository already owns the broader AI development environment setup story. The new installer structure keeps the changes isolated and makes the project usable without first asking an AI tool to execute `SETUP.md`.

## What This Repo Does

- Detects Windows, macOS, Linux, WSL2, available shells, package managers, Node/npm, Git, Claude Code, and Codex CLI.
- Installs or guides installation for Claude Code and Codex CLI.
- Supports partial installs: Claude-only, Codex-only, both installed, or neither installed.
- Installs shared instructions, handoff templates, reusable prompts, Claude assets, and Codex assets.
- Backs up existing destination files/directories before replacing them.
- Writes setup logs to `logs/`.
- Produces a final summary with detected OS/shells, tool status, configured assets, manual steps, and errors.

## Supported Platforms

| Platform | Entry point | Notes |
| --- | --- | --- |
| Windows 10/11 | `install.ps1` | Native PowerShell supported; WSL2 recommended for best Codex compatibility. |
| macOS 12+ | `install.sh` | Homebrew is used when available for prerequisites. |
| Linux | `install.sh` | `apt-get` automation is supported initially; other distros get explicit manual steps. |
| WSL2 | `install.sh` | Preferred Windows path for parity with Linux/macOS tooling. |

## Prerequisites

- Git, if cloning rather than downloading a zip.
- PowerShell 5.1+ on Windows.
- Bash or zsh on macOS/Linux.
- Node.js LTS and npm are recommended. The installer can attempt to install them on common platforms, or give manual fallback steps.

## Quick Start

### Windows

```powershell
git clone https://github.com/eldestar/ai-dev-setup.git
cd ai-dev-setup
git switch feature/claude-codex-installer
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
.\install.ps1
```

Preview changes without writing:

```powershell
.\install.ps1 -DryRun -VerboseLogging
```

Run an isolated asset-copy test without writing to your real config folders:

```powershell
.\install.ps1 -Yes -UserHome .\work\test-home -TargetRoot .\work\test-project
```

Run without confirmation prompts:

```powershell
.\install.ps1 -Yes
```

### macOS / Linux / WSL2

```bash
git clone https://github.com/eldestar/ai-dev-setup.git
cd ai-dev-setup
git switch feature/claude-codex-installer
chmod +x install.sh
./install.sh
```

Preview changes without writing:

```bash
./install.sh --dry-run --verbose
```

Run an isolated asset-copy test without writing to your real config folders:

```bash
./install.sh --yes --user-home="$PWD/work/test-home" --target-root="$PWD/work/test-project"
```

Run without confirmation prompts:

```bash
./install.sh --yes
```

## Repo Structure

```text
ai-dev-setup/
  README.md
  install.ps1
  install.sh
  scripts/
    common/
    windows/
    macos/
    linux/
  config/
    shared/
    claude/
    codex/
  agents/
    claude/
    codex/
    shared/
  skills/
    claude/
  templates/
    handoffs/
    goals/
    prompts/
  docs/
    architecture.md
    manual-install.md
    troubleshooting.md
    supported-platforms.md
    validation-checklist.md
  logs/
    .gitkeep
```

## Updating Installed Assets

Pull the latest repo changes and rerun the installer:

```bash
git pull
./install.sh
```

On Windows:

```powershell
git pull
.\install.ps1
```

Existing destination files are backed up before replacement. Use dry-run first when reviewing larger updates.

## Adding Assets Later

- Shared coding standards and instructions: add files under `config/shared/`.
- Claude commands/settings/project instructions: add files under `config/claude/`.
- Claude agents: add files under `agents/claude/`.
- Claude skills: add skill folders under `skills/claude/`.
- Codex instructions/config/templates: add files under `config/codex/`, `agents/codex/`, and `templates/goals/`.
- Handoff templates and prompts: add files under `templates/handoffs/` and `templates/prompts/`.

Then rerun the installer to copy the new assets into the standard user-level locations.

## Manual Fallback

If automation cannot complete a step, the installer records an explicit manual action in the final summary. The full fallback guide is in [docs/manual-install.md](docs/manual-install.md), with verification commands for each platform.

## Troubleshooting

See [docs/troubleshooting.md](docs/troubleshooting.md). Most setup failures are caused by missing Node/npm, shell `PATH` refresh issues after a package install, or authentication still needing a browser login.
