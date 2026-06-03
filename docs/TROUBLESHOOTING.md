# Troubleshooting

Start with the read-only health check:
```bash
scripts/doctor.sh        # macOS / Linux
```
```powershell
runners\install.ps1 -Check     # or: scripts\doctor.ps1
```

## Common issues

**A tool shows `[MISS]` after install**
Open a NEW terminal (PATH/profile changes only apply to new sessions), then re-check. On Windows,
the npm-global and `~/.local/bin` paths are added to `$PROFILE`.

**`claude` / `codex` not found**
They install to `~/.npm-global/bin`. New shell, then `claude login` / first-run `codex` for browser auth.

**Skills install fails: "fetch of pinned ref failed"**
The pinned commit SHA in `skills-lock.json` may be unreachable (force-push / deleted). Re-pin: resolve
a current SHA (`git ls-remote <repo> HEAD`), update the lock, and re-run `scripts/install-skills.*`.

**Skills install: "SHA-256 MISMATCH"**
The upstream file changed relative to the pinned hash. This is the integrity check doing its job —
review the change, then recompute and update the `sha256` in `skills-lock.json` if the change is expected.

**`doctor` shows many "UNPINNED/extra" skills**
A previous bulk install (e.g., `antigravity-awesome-skills`) is still on disk. Clear `~/.claude/skills`
and re-run `scripts/install-skills.*` to get only the allowlist.

**Python 3.14 breaks numpy/scipy (aider, markitdown)**
The installer pins Python 3.12 via mise on purpose. If you overrode it, `mise use python@3.12`.

**Ollama model too large / slow**
Model tiers are in `config/models.csv`. On CPU-only or low VRAM the installer picks a smaller model;
edit the CSV to change recommendations.

**Windows: script won't run**
`Set-ExecutionPolicy RemoteSigned -Scope CurrentUser`. The bootstrap is wrapped in a function so it
won't close your shell on early exit.

**Where are the logs?**
`$HOME/.ai-dev-setup/logs/install-<timestamp>.log` (Windows native installer, via Start-Transcript).
