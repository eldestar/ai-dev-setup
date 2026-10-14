# Security Notes & Trust Model

This is a **personal** AI dev environment installer. It is security-conscious by design.

## Trust model — what runs with what privilege

| Component | Runs as | Network | Notes |
|---|---|---|---|
| `setup-windows.ps1` (bootstrap) | your user | clones the repo over HTTPS | thin; ensures git, clones to `$HOME/ai-dev-setup`, runs `runners/install.ps1` |
| `runners/install.ps1` / `SETUP.md` | your user (no sudo) | package managers (scoop/brew), npm, uv | installs the toolchain; logs to `$HOME/.ai-dev-setup/logs/` |
| `scripts/install-skills.*` | your user | git fetch at **pinned commit SHAs** | installs ONLY `skills-lock.json`; SHA-256 verifies skill anchors (agents are pinned by commit and path only) |
| Skills / agents | loaded by Claude Code (shell + file access) | none at rest | instruction files — see the prompt-injection note below |

## What we deliberately do NOT do

- **No bulk skill/agent install.** The previous `antigravity-awesome-skills` (~1,443 files) and `agency-agents` (~184) bulk installs were removed — loading thousands of unvetted instruction files into an agent that has shell + secret access is a standing prompt-injection surface. Skills/agents now come from a **pinned allowlist** (`skills-lock.json`): skills carry SHA-256 anchors, agents are pinned by commit and path.
- **No credential-proxy / "free unlimited AI" gateways.** None are installed.
- **Bootstrap installers are not pinned.** Skills are fetched by commit SHA, but the bootstrap uses the vendors' own install scripts (Homebrew, Claude Code, Ollama; NodeSource on the Windows WSL path). They are not checksummed by this repo. Read them before running, and do not run this on a machine you do not control.

## Standing rules

- **Pinning:** everything in `skills-lock.json` is pinned to a commit SHA (these upstreams publish no tags). Re-pin deliberately; review the diff.
- **Prompt injection:** even first-party skills are *not* hardened against prompt injection. Treat any skill/agent with shell access as **trusted-input-only**. Review new persona/skill files before enabling.
- **Secrets:** managed by Infisical; never commit secrets. A global `gitleaks` pre-commit hook is installed, and CI runs gitleaks.
- **Audit:** `scripts/doctor.{sh,ps1}` reports installed skills/agents vs the lock — anything "UNPINNED/extra" is drift to review (e.g., a previously bulk-installed bundle still on disk).
- **License:** MIT for this repo's own code (see `LICENSE`). Pinned third-party skills and agents keep their own licenses.

## Reporting

Use GitHub's private vulnerability reporting (the Security tab, "Report a vulnerability") for anything sensitive, or open an issue for everything else.
