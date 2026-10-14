# ai-dev-setup

Personal AI dev environment setup — deployable on any Mac or Windows device.

## What This Is

A single executable spec (`SETUP.md`) that Claude Code reads and runs to configure a full AI-assisted development environment from scratch. Designed to be re-runnable: checks before installing, skips what's already present, fixes what's wrong.

## What Gets Installed

| Category | Tools |
|----------|-------|
| Shell | starship, fzf, bat, lazygit, zellij, mise |
| Runtimes | Node LTS, Python 3.12, Bun (via mise) |
| Package managers | uv, pipx, bun, npm |
| AI coding | Claude Code, Codex CLI, Aider, Ollama |
| Local LLMs | Auto-selected based on device RAM + GPU |
| Agent orchestration | Ruflo |
| Skills & agents | Curated, pinned allowlist (see `skills-lock.json`) |
| Knowledge base | ~/vault/ structure + MCP server + Obsidian templates |
| Security | gitleaks (pre-commit hook), trivy, semgrep |
| Secrets | Infisical |
| App building | PocketBase, Caddy, spec-kit, newproject command (macOS and WSL; not installed on native Windows) |

## Quick Start (New Device)

### Mac

```bash
# 1. Install Homebrew (read the script first if you prefer): https://brew.sh
# 2. Install Claude Code using Anthropic's current instructions:
#    https://code.claude.com/docs/en/setup  (the native installer is the recommended route)
# 3. Start it once and sign in:
claude

# Then run setup
git clone https://github.com/eldestar/ai-dev-setup.git
cd ai-dev-setup
claude "Read SETUP.md, run system detection first and report findings,
then execute all phases in order. Ask me before each phase starts.
Collect all manual steps and present them together at the end.
Log everything to SETUP_LOG.md."
```

### Windows

```powershell
# Run in PowerShell (no admin required). Download it, read it, then run it:
Invoke-WebRequest https://raw.githubusercontent.com/eldestar/ai-dev-setup/main/setup-windows.ps1 -OutFile setup-windows.ps1
Get-Content .\setup-windows.ps1
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser   # allows running local scripts
.\setup-windows.ps1
```

The script detects your hardware (RAM + GPU), recommends the right local LLM, then asks:
- **WSL2** (recommended) — full Linux environment, all tools work identically to Mac
- **Native PowerShell** — installs everything via Scoop, works with reduced functionality on some tools

The manual steps that need a browser (Claude and Codex sign-in, plugin installs) are listed in `SETUP.md`. The native PowerShell path prints them at the end; the WSL path does not, so follow `SETUP.md` inside the WSL shell.

### Re-run on Existing Device (fix / update)
```bash
git pull
claude "Read SETUP.md, run system detection, check each phase and fix
only what's missing or wrong. Skip anything correctly installed.
Log changes to SETUP_LOG.md."
```

## Platform Support

| Platform | Status | Path |
|----------|--------|------|
| macOS Apple Silicon | Primary; the bash smoke test passes in CI | Homebrew + zsh |
| macOS Intel | Untested | Homebrew + zsh |
| Windows (WSL2) | Untested in CI | `setup-windows.ps1` → WSL2 → SETUP.md |
| Windows (Native) | Untested in CI | `setup-windows.ps1` → Scoop + PowerShell |

## Local LLM Selection

Auto-selected from RAM + GPU at setup time. The model tiers live in **one place** —
[`config/models.csv`](config/models.csv) — which both installers read (no duplicated tables).

## Workflow Patterns

**Claude + Codex Dynamic Duo:**
```
/codex:adversarial-review [plan]   # stress-test before building
/codex:rescue --background         # full audit while you keep working
/codex:result                      # retrieve audit
```

**Full planning loop:** Claude plans → `/codex:adversarial-review` → Claude refines → repeat until Codex has no issues → implement.

## Daily Usage

```bash
# Start a new project (full scaffold)
newproject my-app-name && cd my-app-name && claude

# Start coding in an existing project
cd my-project && claude

# Search your knowledge vault
rg "search term" ~/vault/

# Convert a PDF/doc to markdown for Claude
markitdown document.pdf > ~/vault/raw/document.md

# Claude + Codex planning loop (before writing any code)
# 1. Ask Claude to output a numbered plan
# 2. /codex:adversarial-review — stress-test it
# 3. Claude refines → repeat until Codex has no issues
# 4. Implement

# Background audit while you keep building
/codex:rescue --background
/codex:status
/codex:result

# Free local AI (no quota, no cost)
aider                        # uses auto-selected Ollama model
ollama run qwen3:8b          # direct REPL

# Security before every commit (also runs automatically via hook)
gitleaks git --staged
trivy fs .

# Runtime switching
mise use node@22             # per-project version pin
mise list                    # see what's installed

# Data exploration
duckdb -c "SELECT * FROM 'file.csv' LIMIT 10"
```

**When to use which AI tool:**

| Situation | Tool |
|-----------|------|
| Coding, design, architecture, writing | Claude Code |
| Auditing a plan before building | `/codex:adversarial-review` |
| Full codebase audit or pre-ship review | `/codex:rescue` |
| Quota is low / working offline | `aider` (local Ollama) |
| Quick one-off question | `ollama run qwen3:8b` |

→ What each component is and why it is there: **[docs/COMPONENT_MATRIX.md](docs/COMPONENT_MATRIX.md)**

## Files

| File | Purpose |
|------|---------|
| `SETUP.md` | Executable setup spec — feed to Claude Code |
| `config/tools.csv`, `config/models.csv` | The tool list and local-model tiers both installers read |
| `skills-lock.json` | Pinned skills and agents allowlist |
| `SECURITY.md` | Trust model and what is deliberately not done |
| `docs/COMPONENT_MATRIX.md` | Every component, why it is installed, and how to remove it |
| `docs/TROUBLESHOOTING.md`, `docs/UNINSTALL.md` | When something goes wrong, and how to undo |
| `docs/SKILL_TIERS.md`, `docs/VERIFIED_SKILLS_LIBRARY.md` | How skills are tiered and which are verified |
| `docs/adr/` | Decision records |
| `CHANGELOG.md` | What changed between versions |

## Economics

| Tool | Auth | Cost |
|------|------|------|
| Claude Code | Claude Pro OAuth | $20/mo |
| Codex CLI | ChatGPT Plus OAuth | $20/mo |
| Aider + Ollama | None | Free |

---

*Feed `SETUP.md` to Claude Code. It does the rest.*

## Known limitations

- No installer has been run end to end in CI. CI runs shellcheck and a bash smoke test, plus PowerShell analysis and a smoke test; the PowerShell installer path has not been exercised on a real Windows machine for this revision.
- Some bootstrap steps use the vendors' own install scripts (Homebrew, Claude Code, Ollama). This repo does not pin or checksum them; read them first.
- Several install steps use `@latest` (for example `ruflo`) or unpinned packages. `skills-lock.json` pins skills and agents by commit; agents carry no sha256.
- `skills-lock.json` still lists an MCP server (`@modelcontextprotocol/server-github`) that its publisher has deprecated, and two MCP entries (trivy, semgrep) whose launch commands were not re-verified.
- Some steps overwrite existing config (aider config, `core.hooksPath`) without asking.

## License

MIT, see `LICENSE`. Third-party skills and agents pinned in `skills-lock.json` keep their own licenses.
