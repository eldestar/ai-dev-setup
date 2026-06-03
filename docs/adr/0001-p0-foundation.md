# 1. P0 foundation: single source of truth + pinned, hash-verified skill allowlist

Date: 2026-06-02 · Status: Accepted

## Context
Two installers (`SETUP.md`, `setup-windows.ps1`) independently encoded the tool list, model
table, and `CLAUDE.md`, causing drift. The installer also bulk-installed ~1,627 unvetted
skill/agent instruction files into the agent trust boundary (prompt-injection surface), and
used unpinned `curl|bash`/`@latest` fetches.

## Decision
- Single source of truth: `config/models.csv`, `config/tools.csv`, `templates/CLAUDE.md.tmpl`, consumed by both installers.
- `setup-windows.ps1` becomes a thin bootstrap that clones the repo and runs `runners/install.ps1`.
- Skills/agents come from a pinned, SHA-256-verified allowlist (`skills-lock.json`); no bulk install.
- Cross-platform tailored installers, a `doctor` preflight, `smoke` test gate, and CI.

## Consequences
- Editing a tool/model/CLAUDE.md fact is a one-file change; Windows and macOS install the same core.
- Skill/agent supply-chain surface shrinks from ~1,627 anonymous files to a reviewed, pinned set.
- The Windows native one-liner now lands the repo on disk (needed to read shared config).
- Full end-to-end install validation depends on the smoke tests + a real run (the installers can't be fully executed in review).
