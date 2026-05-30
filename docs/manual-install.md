# Manual Installation Fallback

Use this guide when the installer reports a manual step or when you prefer to install prerequisites yourself.

## Windows

Recommended path: WSL2 for the most consistent Codex experience.

```powershell
wsl --install
wsl --status
```

Install Git:

```powershell
winget install --id Git.Git -e
git --version
```

Install Node.js LTS:

```powershell
winget install --id OpenJS.NodeJS.LTS -e
node --version
npm --version
```

Install Claude Code:

```powershell
npm install -g @anthropic-ai/claude-code@latest
claude --version
claude login
```

Install Codex CLI:

```powershell
npm install -g @openai/codex@latest
codex --version
codex login
```

## macOS

Install command line tools:

```bash
xcode-select --install
git --version
```

Install Homebrew:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
brew --version
```

Install Node.js:

```bash
brew install node
node --version
npm --version
```

Install Claude Code:

```bash
npm install -g @anthropic-ai/claude-code@latest
claude --version
claude login
```

Install Codex CLI:

```bash
npm install -g @openai/codex@latest
codex --version
codex login
```

## Linux / WSL2

Debian/Ubuntu prerequisites:

```bash
sudo apt-get update
sudo apt-get install -y git nodejs npm
git --version
node --version
npm --version
```

Install Claude Code:

```bash
npm install -g @anthropic-ai/claude-code@latest
claude --version
claude login
```

Install Codex CLI:

```bash
npm install -g @openai/codex@latest
codex --version
codex login
```

## Official References

- Claude Code installation: https://code.claude.com/docs/en/installation
- OpenAI Codex CLI getting started: https://help.openai.com/en/articles/11096431
- Codex CLI repository install docs: https://github.com/openai/codex/blob/main/docs/install.md
