---
name: installer-maintenance
description: Maintain the Claude + Codex installer scripts, native assets, compatibility checks, and docs.
---

# Installer Maintenance

Use this skill when changing installer behavior or extension assets.

1. Inspect the relevant entry point and platform helper.
2. Keep reusable logic in `scripts/common/`.
3. Keep Claude and Codex discovery paths distinct.
4. Update docs when behavior changes.
5. Run parser checks and isolated sandbox validation.
6. Summarize changed paths, validation, and remaining platform risks.
