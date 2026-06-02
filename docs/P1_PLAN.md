# P1 Implementation Plan

> Builds on P0. The wound P1 closes: install *logic* is still duplicated between `SETUP.md` prose (LLM-executed)
> and `runners/install.ps1` code. P0 made the *data* single-source (CSVs, template, lock); P1 makes the
> *component list + per-OS install mechanics* data too.

## Architecture decision: manifest + thin runners (NOT a Python engine)
1. **Bootstrap paradox** — Python is one of the things this repo installs; it can't be the installer of itself. PowerShell 5.1 (Windows) and bash (mac/Linux) are guaranteed-present.
2. The Windows thin-runner pattern already works — generalize it, don't rewrite.
3. **Boring/reliable** — a manifest + two ~150-line interpreters is auditable; an engine grows needless abstractions for ~25 components.

**Format: JSON manifest** (`config/manifest.json`) — reuses the exact parsing already proven in `install-skills.*` (`ConvertFrom-Json` / embedded-python). No new dependency. `SETUP.md` stops being executable and becomes a human guide that points at the runner — finally giving the **bash side a real, testable program** (`runners/install.sh`).

### Manifest schema (sketch)
```jsonc
{ "version": 1, "components": [
  { "id": "ripgrep", "name": "ripgrep", "profiles": ["minimal","full","work"],
    "check": "rg",                          // idempotency contract (skip if it passes)
    "install":   { "windows": "scoop install ripgrep", "macos": "brew install ripgrep", "linux": "brew install ripgrep" },
    "uninstall": { "windows": "scoop uninstall ripgrep", "macos": "brew uninstall ripgrep", "linux": "brew uninstall ripgrep" },
    "requires": [] },
  { "id": "claude-md", "profiles": ["minimal","full","work"], "check": "@file:~/.claude/CLAUDE.md",
    "install": { "all": "@render-template templates/CLAUDE.md.tmpl ~/.claude/CLAUDE.md" } }
]}
```
- `check` is mandatory = the idempotency + `--dry-run` contract.
- install/uninstall = literal shell strings keyed by platform. Non-shell actions are a **closed set of `@handlers`** (`@model-pull`, `@model-rm`, `@render-template`, `@file:`, `@rm`, `@profile-line`) — that's the entire abstraction budget. A 7th handler = signal a component should be a literal string instead.
- **Keep `tools.csv`/`models.csv`** (they own tool→pkg and model tiers, already smoke-covered). The manifest owns only the *bespoke* components. Minimal-diff migration.

### Migration (strangler, not big-bang)
Each `Write-Header` block in `install.ps1` (12 of them) → one manifest component (install string = the command already there). Rewrite `install.ps1` to load→filter→topo-order→check/install/post loop (~320 → ~120 lines, **net behavior identical** = acceptance bar). Write the bash twin `runners/install.sh`. Convert `SETUP.md` PHASE 1–3 to a guide; extend the smoke drift-guard to assert no `scoop/brew install` literals remain in `SETUP.md`.

---

## Sprints (each independently shippable; CI green throughout)

### Sprint 1 — Manifest + thin runners
Files: `config/manifest.json` + `config/manifest.schema.json` (new); `runners/lib/common.ps1` (+`Get-Manifest`/`Select-Components`/`Invoke-Component`/`@handlers`); `runners/lib/common.sh` (new, extract the JSON parser from `install-skills.sh`); `runners/install.ps1` (rewrite to interpreter); `runners/install.sh` (new); `SETUP.md` (PHASE 1–3 → guide); `docs/COMPONENT_MATRIX.md` + `config/README.md` (edit).
**Accept:** `doctor` output identical before/after on a clean Windows VM; `install.sh` passes shellcheck (extend CI glob to `runners/*.sh`); re-run = no-op; smoke validates manifest schema, every component has `check`+`install`, no `requires` cycle; no `scoop/brew install` literals left in `SETUP.md`.

### Sprint 2 — Profiles + selective + non-interactive
Profiles: **minimal** (working dev box, no local LLM), **full** (everything), **work** (full minus `scope: personal-only` lock entries — honors the lock's `scope` field). Flags: `-Profile`, `-Only id,id`, `-Skip id,id`, `-Yes`, `-DryRun`. Neutralize the one real interactive prompt (`setup-windows.ps1:39` WSL-vs-native) under `-Yes` so `irm|iex` runs unattended.
**Accept:** `--profile minimal --yes` runs prompt-free; `--only`/`--skip` exact; `work` installs no `personal-only` asset; smoke asserts `minimal ⊆ full` and the `work`/`full` delta == the personal-only set.

### Sprint 3 — Uninstall + `--dry-run`
`runners/uninstall.{ps1,sh}` iterate manifest in reverse `requires` order; `null` uninstall = "leave it" (package managers, **never auto-delete `~/vault`** without `--include-vault`). `docs/UNINSTALL.md` → "run `runners/uninstall.sh [--dry-run]`" (replaces hand-maintained `rm -rf` lists that drift). Smoke: every component with an `install` has a declared `uninstall` (null = conscious opt-out).
**Accept:** `--dry-run` changes nothing (doctor identical); idempotent/safe on partial systems; vault + external pkg-mgrs never removed without opt-in.

### Sprint 4 — `/self-review` loop (plan-only, never self-applies)
Implements `docs/SELF_IMPROVEMENT.md` literally. `.claude/commands/self-review.md` (4 steps: scan→judge→write→stop); `scripts/self-review-scan.{sh,ps1}` (deterministic scan emits JSON evidence); `docs/self-review/TEMPLATE.md`; optional `.github/workflows/self-review.yml` that runs **only the scan** and opens an **issue** (never a commit/PR — a bot writing+approving docs violates the human-review rule).
**Accept:** invoking `/self-review` touches only `docs/self-review/` + `docs/adr/` (asserted via throwaway-worktree `git status`); never runs install/uninstall or edits `runners/`/`config/`/`skills-lock.json`/`.github/`/`.claude/`; CI job opens an issue, never pushes.

---

## Cross-cutting
- Keep the CSVs in P1 (folding them into the manifest is a P2 nicety; keeps the diff reviewable).
- Biggest reliability win: the bash path becomes a real, shellcheck'd, smoke-tested program for the first time — do the manifest **before** profiles/uninstall (both depend on it). Sprint 4 is independent (docs/scripts/.claude only) and parallelizable.
- The **skill-framework** work ([SKILL_FRAMEWORK_PLAN.md](SKILL_FRAMEWORK_PLAN.md)) — tiers, `update-lock`, catalog, schema — is also P1 and additive; sequence it alongside.
