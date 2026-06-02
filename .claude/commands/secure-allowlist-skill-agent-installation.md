---
name: secure-allowlist-skill-agent-installation
description: Workflow command scaffold for secure-allowlist-skill-agent-installation in ai-dev-setup.
allowed_tools: ["Bash", "Read", "Write", "Grep", "Glob"]
---

# /secure-allowlist-skill-agent-installation

Use this workflow when working on **secure-allowlist-skill-agent-installation** in `ai-dev-setup`.

## Goal

Add or update a hash-pinned allowlist for skills/agents, and wire it into both platform installers with cross-platform verification.

## Common Files

- `skills-lock.json`
- `scripts/install-skills.sh`
- `scripts/install-skills.ps1`
- `runners/install.ps1`
- `SETUP.md`
- `CHANGELOG.md`

## Suggested Sequence

1. Understand the current state and failure mode before editing.
2. Make the smallest coherent change that satisfies the workflow goal.
3. Run the most relevant verification for touched files.
4. Summarize what changed and what still needs review.

## Typical Commit Signals

- Update skills-lock.json with new or changed allowlist entries (skills, agents, plugins, MCPs) and their commit SHAs.
- Update or create install scripts for both platforms (scripts/install-skills.sh, scripts/install-skills.ps1) to use the allowlist and verify hashes.
- Wire the install scripts into both runners/install.ps1 and SETUP.md.
- Test end-to-end installation and hash verification on both platforms.
- Document the changes in CHANGELOG.md.

## Notes

- Treat this as a scaffold, not a hard-coded script.
- Update the command if the workflow evolves materially.