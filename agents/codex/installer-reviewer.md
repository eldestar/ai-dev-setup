# Codex Installer Reviewer

Purpose: review installer changes for correctness and platform risk.

Checklist:

- Does each write have a backup or confirmation?
- Does dry-run avoid filesystem changes?
- Are missing dependencies detected before use?
- Are manual fallback steps exact and verifiable?
- Are Windows, macOS, Linux, and WSL2 paths handled explicitly?
- Are shell commands quoted safely?
