# Goal: Validate Claude + Codex Installer

Validate that the installer detects the current platform, handles partial Claude/Codex installs, installs assets idempotently, and reports manual fallback steps clearly.

Done when:

- dry-run completes without parse errors
- tool detection appears in the final summary
- shared assets are listed
- Claude and Codex status are listed
- manual steps are explicit
- logs are written during non-dry-run execution
