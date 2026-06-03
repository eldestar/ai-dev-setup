# Security Notes & Trust Model

This is a **personal** AI dev environment installer. It is security-conscious by design.

## Trust model — what runs with what privilege

| Component | Runs as | Network | Notes |
|---|---|---|---|
| `setup-windows.ps1` (bootstrap) | your user | clones the repo over HTTPS | thin; ensures git, clones to `$HOME/ai-dev-setup`, runs `runners/install.ps1` |
| `runners/install.ps1` / `SETUP.md` | your user (no sudo) | package managers (scoop/brew), npm, uv | installs the toolchain; logs to `$HOME/.ai-dev-setup/logs/` |
| `scripts/install-skills.*` | your user | git fetch at **pinned commit SHAs** | installs ONLY `skills-lock.json`; SHA-256 verifies skill anchors |
| Skills / agents | loaded by Claude Code (shell + file access) | none at rest | instruction files — see the prompt-injection note below |

## What we deliberately do NOT do

- **No bulk skill/agent install.** The previous `antigravity-awesome-skills` (~1,443 files) and `agency-agents` (~184) bulk installs were removed — loading thousands of unvetted instruction files into an agent that has shell + secret access is a standing prompt-injection surface. Skills/agents now come from a **pinned, hash-verified allowlist** (`skills-lock.json`).
- **No credential-proxy / "free unlimited AI" gateways.** None are installed.
- **No `curl | bash` of unpinned remote installers** in the supported path (the lock fetches by commit SHA; bootstrap installers should be pinned + checksummed — see roadmap).

## Standing rules

- **Pinning:** everything in `skills-lock.json` is pinned to a commit SHA (these upstreams publish no tags). Re-pin deliberately; review the diff.
- **Prompt injection:** even first-party skills are *not* hardened against prompt injection. Treat any skill/agent with shell access as **trusted-input-only**. Review new persona/skill files before enabling.
- **Secrets:** managed by Infisical; never commit secrets. A global `gitleaks` pre-commit hook is installed, and CI runs gitleaks.
- **Audit:** `scripts/doctor.{sh,ps1}` reports installed skills/agents vs the lock — anything "UNPINNED/extra" is drift to review (e.g., a previously bulk-installed bundle still on disk).
- **License:** personal project, all rights reserved (see README). License-redistribution flags on dependencies are informational for personal use; revisit if ever shared.

## Reporting

Personal repo — open an issue or note it in the decision log (`docs/adr/`).
