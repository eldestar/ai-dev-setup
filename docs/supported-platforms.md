# Supported Platforms

| Platform | Status | Entry point | Notes |
| --- | --- | --- | --- |
| Windows 10/11 native PowerShell | Supported | `install.ps1` | Uses `winget` or Scoop when available for prerequisites. |
| Windows 11 WSL2 | Recommended | `install.sh` inside WSL2 | Best parity with Linux and Codex CLI workflows. |
| macOS 12+ Apple Silicon | Supported | `install.sh` | Uses Homebrew when available. |
| macOS 12+ Intel | Supported | `install.sh` | Uses Homebrew when available. |
| Ubuntu/Debian Linux | Supported | `install.sh` | Can automate `apt-get` installs after confirmation. |
| Fedora/RHEL/Arch/openSUSE | Guided | `install.sh` | Detection works; package installation is currently manual fallback. |

## Shell Detection

The installers report detected shells:

- PowerShell / `pwsh`
- Windows PowerShell
- bash
- zsh
- fish where present
- WSL where present on Windows

## Tool Detection

The installers validate:

- `git --version`
- `node --version`
- `npm --version`
- `claude --version`
- `codex --version`
