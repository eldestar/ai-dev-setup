```markdown
# ai-dev-setup Development Patterns

> Auto-generated skill from repository analysis

## Overview

This skill covers the core development patterns, workflows, and coding conventions used in the `ai-dev-setup` repository. The project is written in TypeScript and focuses on cross-platform automation for AI developer environment setup, including configuration management, secure installation of skills/agents, and robust preflight/smoke testing. The repository is designed to ensure consistency, security, and maintainability across both Windows and Unix-like systems.

## Coding Conventions

- **File Naming:**  
  Use camelCase for file names.  
  *Example:*  
  ```
  config/models.csv
  runners/install.ps1
  setupWindows.ts
  ```

- **Import Style:**  
  Use relative imports for modules.  
  *Example (TypeScript):*  
  ```typescript
  import { getConfig } from './configLoader';
  ```

- **Export Style:**  
  Use named exports.  
  *Example (TypeScript):*  
  ```typescript
  export function installTools() { ... }
  export const TOOL_VERSION = '1.2.3';
  ```

- **Commit Messages:**  
  Freeform style, average length ~67 characters.  
  *Example:*  
  ```
  Refactor installer scripts to use unified config source
  ```

## Workflows

### Single Source of Truth Config Integration
**Trigger:** When adding or updating a core configuration (models, tools, templates) and ensuring all scripts and docs use the same source.  
**Command:** `/sync-config`

1. Add or update config files (e.g., `config/models.csv`, `config/tools.csv`, `templates/CLAUDE.md.tmpl`).
2. Refactor installer scripts (`runners/install.ps1`, `setup-windows.ps1`, `SETUP.md`) to consume the new config.
3. Update documentation (`config/README.md`, `README.md`, `SETUP.md`) to reference or explain the config.
4. Remove or deduplicate any inline or duplicated tables/lists in scripts and docs.
5. Test all installer paths to verify the config is correctly consumed.

*Example:*
```typescript
// Load models from single config source
import { loadModels } from '../config/modelsLoader';
const models = loadModels('config/models.csv');
```

---

### Cross-Platform Installer Refactor
**Trigger:** When introducing a new install step or config and ensuring both Windows and Unix installers behave identically.  
**Command:** `/update-installers`

1. Update or refactor `setup-windows.ps1` (Windows bootstrap) to delegate to `runners/install.ps1`.
2. Update `runners/install.ps1` to consume new config or logic.
3. Update `SETUP.md` (bash path) to consume the same config or logic.
4. Verify that both installer paths (PowerShell and bash) produce the same results.
5. Test parsing and selection logic on both platforms.

*Example:*
```powershell
# setup-windows.ps1
& "$PSScriptRoot\runners\install.ps1" -ConfigPath "config/models.csv"
```

---

### Secure Allowlist Skill/Agent Installation
**Trigger:** When changing which skills/agents are installed, or updating their pinned SHAs to ensure only reviewed code is installed.  
**Command:** `/update-allowlist`

1. Update `skills-lock.json` with new or changed allowlist entries and their commit SHAs.
2. Update or create install scripts (`scripts/install-skills.sh`, `scripts/install-skills.ps1`) to use the allowlist and verify hashes.
3. Wire the install scripts into both `runners/install.ps1` and `SETUP.md`.
4. Test end-to-end installation and hash verification on both platforms.
5. Document the changes in `CHANGELOG.md`.

*Example:*
```json
// skills-lock.json
{
  "skills": [
    { "name": "agent-foo", "sha": "abc123..." }
  ]
}
```
```bash
# scripts/install-skills.sh
verify_sha "$skill" "$sha"
```

---

### Preflight and Smoke Test Workflow
**Trigger:** When adding new validation checks, ensuring environment/tooling consistency, or expanding CI coverage.  
**Command:** `/add-smoke-test`

1. Add or update doctor scripts (`scripts/doctor.sh`, `scripts/doctor.ps1`) for preflight and audit checks.
2. Add or update smoke test scripts (`tests/smoke.sh`, `tests/smoke.ps1`) for validation gates.
3. Update `runners/install.ps1` to support preflight checks (e.g., `-Check` flag).
4. Update or add CI workflow files (`.github/workflows/ci.yml`) to run these checks.
5. Update or add relevant documentation (`SECURITY.md`, `docs/TROUBLESHOOTING.md`).

*Example:*
```bash
# scripts/doctor.sh
if ! command -v node; then
  echo "Node.js is not installed"
  exit 1
fi
```

## Testing Patterns

- **Test Framework:** Unknown (custom or not detected).
- **Test File Pattern:** Files matching `*.test.*`.
- **Typical Structure:**  
  - Place test files alongside or near the code they test, using the `.test.` infix.
  - Include smoke tests and preflight checks for both platforms.
- **Example:**
  ```
  src/configLoader.test.ts
  tests/smoke.sh
  tests/smoke.ps1
  ```

## Commands

| Command            | Purpose                                                         |
|--------------------|-----------------------------------------------------------------|
| /sync-config       | Integrate or update single-source-of-truth config and consumers |
| /update-installers | Refactor installers to ensure cross-platform parity             |
| /update-allowlist  | Update the allowlist for skills/agents and their pinned SHAs    |
| /add-smoke-test    | Add or update preflight and smoke test scripts and CI           |
```
