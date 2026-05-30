# Troubleshooting

## Command installed but not found

Open a new terminal and check `PATH`:

```bash
node --version
npm --version
claude --version
codex --version
```

On Windows, close and reopen PowerShell after installing Node.js with `winget`.

## npm global install permission errors

Avoid `sudo npm install -g` when possible. Prefer a user-level Node manager or platform package manager.

macOS:

```bash
brew install node
npm config get prefix
```

Linux:

```bash
npm config get prefix
```

If the prefix is a system path, install Node through a user-level manager or fix npm's global prefix before rerunning the installer.

## Claude or Codex validates but is not authenticated

Run the login command directly:

```bash
claude login
codex login
```

Then rerun:

```bash
claude --version
codex --version
```

## Windows native Codex issues

Use WSL2 when possible:

```powershell
wsl --install
wsl --status
```

Then run `install.sh` inside the WSL2 Linux shell.

## Existing config was replaced unexpectedly

The installer creates timestamped backups before replacement. Look for sibling paths ending in `.backup-YYYYMMDD-HHMMSS`.

## Review logs

Each run writes a log under:

```text
logs/setup-YYYYMMDD-HHMMSS.log
```
