# Component / Platform Matrix

What installs where. The core toolchain is the same set on every platform (read from
`config/tools.csv`); install mechanism differs per OS.

| Component | macOS | Windows (native) | Linux / WSL2 | Source of truth |
|---|---|---|---|---|
| Core CLI (git, starship, fzf, bat, ripgrep, lazygit, zellij, duckdb, just, caddy, mise) | brew | scoop | brew | `config/tools.csv` |
| Runtimes (Node LTS, Python 3.12, Bun) | mise | mise | mise | — |
| uv, pipx | pip | pip | pip | — |
| Claude Code, Codex CLI | npm -g | npm -g | npm -g | — |
| Ollama + models | brew + pull | scoop + pull | curl installer + pull | model = `config/models.csv` |
| Aider | uv tool | uv tool | uv tool | — |
| gitleaks, trivy, semgrep, infisical, markitdown | brew / uv | scoop / uv / npm | brew / uv | — |
| Skills + agents (pinned allowlist) | `scripts/install-skills.sh` | `scripts/install-skills.ps1` | `scripts/install-skills.sh` | `skills-lock.json` |
| `~/.claude/CLAUDE.md` | rendered (sed) | rendered (Expand-Template) | rendered (sed) | `templates/CLAUDE.md.tmpl` |
| Vault `~/vault` + MCP | yes | yes | yes | — |

## Entry points
- **macOS / Linux / WSL2:** `claude "Read SETUP.md, run system detection, execute all phases."` (run from the cloned repo)
- **Windows native:** `irm https://raw.githubusercontent.com/eldestar/ai-dev-setup/main/setup-windows.ps1 | iex` → bootstrap clones the repo and runs `runners/install.ps1`

## Preflight & validation (read-only)
- `scripts/doctor.sh` / `scripts/doctor.ps1` — environment + skill/agent audit
- `runners/install.ps1 -Check` — preflight without changes (Windows)
- `tests/smoke.sh` / `tests/smoke.ps1` — config/lock/template validation gate (also CI)
