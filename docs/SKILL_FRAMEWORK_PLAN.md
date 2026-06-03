# Skill Framework — Maintainability Plan

> How the installer framework should manage skills/agents over time so you can **keep many without losing
> curation**. All changes are to the framework (`skills-lock.json`, `scripts/`, `schema/`, `docs/`, CI) — never to
> deployed `~/.claude` assets. The lock should in fact be **expanded** to describe what's already on the machine,
> so curation is additive, not subtractive.

---

## 1. Tiered model (`skills-lock.json` v3)

Add a `tier` field to every entry + a top-level registry. Tiers are **install-selectable, never deletion gates.**

```jsonc
{
  "version": 3,
  "tiers": {
    "core":         { "default": true,  "description": "pinned + SHA-verified; always installed" },
    "curated":      { "default": true,  "description": "vetted bundles; opt-out per bundle" },
    "experimental": { "default": false, "description": "trial; opt-in only" },
    "archived":     { "default": false, "description": "deprecated-but-retained; --include-archived" }
  },
  "bundles": {
    "security": { "tier": "curated", "members": ["wshobson-security-auditor", "..."] },
    "aggregator-antigravity": { "tier": "experimental", "source": "antigravity-awesome-skills",
      "note": "1460-skill personal aggregator; bulk reference of current machine state" }
  },
  "skills": [ { "name": "impeccable", "tier": "core", "bundle": "frontend", "...": "..." } ]
}
```

Installer flags (both `.ps1`/`.sh`): `--tiers core,curated` (default) · `--bundle security` · `--exclude-bundle X` · `--include-experimental` · `--include-archived`. The runner filters lock entries by tier/bundle *before* the existing clone→copy→verify loop. Default = `core` + `curated`. Document semantics in `docs/SKILL_TIERS.md`.

## 2. Versioning + upgrade flow — `scripts/update-lock.{ps1,sh}`

The single most important addition (re-pinning is fully manual today). Subcommands:
- **`check`** — `git ls-remote <repo> HEAD` per entry, compare to pinned `ref`, print a drift report (read-only).
- **`plan [--name|--bundle|--all]`** — fetch candidate refs, recompute anchor `sha256`, write `skills-lock.proposed.json` + a unified diff. **Never writes the live lock.**
- **`apply`** — promote proposed→live after approval (interactive, or `--yes` for CI-gated PRs); stamp `CHANGELOG.md` + `lockUpdatedAt`.

Per-entry provenance fields: `pinnedAt`, `lastVerifiedAt`, `upstreamDefaultBranch`, `supersedes` (previous ref for audit trail). SHA is the version primitive (these repos publish no tags); `update-lock` makes "re-pin → diff → approve" a one-command reviewable PR.

## 3. Portability hardening

- **`.ps1` paths:** drop the manual `'/'→'\'` conversion; `Join-Path`/git accept forward slashes on Windows.
- **`.sh` python dep:** document `python3` as required in `config/tools.csv`; have `doctor` flag it (today it only "skips").
- **Line endings:** `.gitattributes` already set (`*.sh` LF, `*.ps1` CRLF) — keep; critical for WSL2 clones.
- **`--offline`:** reuse the clone cache without network (air-gapped reinstall + CI pin verification).
- **Shared logic:** implement the catalog generator + lock-updater + JSON parsing once in `scripts/lib/lock.py`, called by thin `.ps1`/`.sh` wrappers — avoids the drift we already guard against for the model table.

## 4. Generated catalog — `scripts/gen-catalog.*` → `docs/CATALOG.md`

Render a human-readable inventory from the lock (grouped tier→bundle): skills `name|tier|bundle|repo|ref|license|scope|lastVerifiedAt`; agents `target|source|repo|ref|license`; plugins/MCP sections; counts-by-tier header. "DO NOT EDIT — generated" header + a CI check that the committed catalog matches a fresh render. This also resolves the dangling `VERIFIED_SKILLS_LIBRARY.md` reference.

## 5. Testing — schema + integrity in smoke/CI

- **`schema/skills-lock.schema.json`** (JSON Schema 2020-12): required fields per section; `ref` matches `^[0-9a-f]{40}$`; `sha256` matches `^[0-9a-f]{64}$`; valid `tier` enum. Smoke validates the lock (Python `jsonschema`).
- **Offline checks (every PR, in smoke):** well-formed hashes/refs; unique skill `name`/agent `target`; every `bundle`/`tier` reference resolves; no `requires` cycle.
- **Reachability check (new CI job, network, on lock-touching PRs + weekly cron):** `git ls-remote <repo> <ref>` confirms each pinned SHA still exists (catches force-push/rebase breakage).
- **Hash re-verify (new CI job, network, `core` tier):** fetch anchor at pinned ref, recompute SHA-256, assert == locked value. Matrix `ubuntu` + `windows` to also prove cross-platform install parity.

## 6. Maintainability — `scripts/skill-audit.*` (extends `doctor`)

Beyond installed-vs-lock, report: (1) **installed-vs-tier** + **unmanaged** assets (on machine, absent from lock — the bulk of the 1460), framed as "candidates to curate," never "delete"; (2) **dedup** (identical anchor SHA-256 / identical name stems); (3) **overlap** clustering of name families (`seo-*`, `azure-*`, `fp-*`); (4) a **coverage KPI** — "% of installed assets that are pinned/tiered" — that trends as curation proceeds. Clustering in `scripts/lib/lock.py` (shared).

## 7. Safe deprecation — mark, never delete

Deprecation = a **tier transition** (`core`/`curated` → `archived`) + an optional, reversible, dry-run-first on-disk move:
```jsonc
{ "name": "old-skill", "tier": "archived",
  "deprecation": { "since": "2026-06-02", "reason": "superseded by X", "replacedBy": "new-skill" } }
```
- `update-lock deprecate <name> --reason ... --replaced-by ...` → proposed-lock diff (same approve flow).
- Archived entries excluded from default installs, installable via `--include-archived` (reproducibility preserved).
- On-disk: a **separate, explicit** `skill-audit deprecate-local --apply` (default `--dry-run`) that **renames** `~/.claude/skills/<name>` → `~/.claude/skills/.archived/<name>` (move, not delete; restore instructions printed). The default installer never touches deployed assets — this is opt-in only.

---

## Suggested sequencing (all P1, additive)

1. `schema/skills-lock.schema.json` + smoke schema/dedup checks (cheapest, highest safety).
2. `scripts/lib/lock.py` + `gen-catalog` → `docs/CATALOG.md` (fixes the dangling `VERIFIED_SKILLS_LIBRARY.md` ref).
3. Lock v3 `tier`/`bundle`/provenance fields + installer tier filtering (backfill all entries; register the 1460-aggregator as `experimental`).
4. `update-lock check/plan/apply` + CI reachability & hash-reverify jobs.
5. `skill-audit` (overlap/dedup/coverage) + `update-lock deprecate` + reversible local-archive command.

Every step changes only the framework. The deployed `~/.claude` environment is read as the reference and modified only through an explicit, reversible, dry-run-gated opt-in.
