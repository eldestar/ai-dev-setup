# Skill Tiers

> How `skills-lock.json` tiers work and how to promote or deprecate entries.

## Tiers

| Tier | Default install | Description |
|---|---|---|
| **core** | always | Pinned + SHA-256 verified. Highest trust bar. |
| **curated** | yes (opt-out) | Vetted source + pinned ref, grouped by bundle. |
| **experimental** | no (opt-in via `--include-experimental`) | Trial entries; not yet fully verified. |
| **archived** | no (opt-in via `--include-archived`) | Deprecated-but-retained. Never deleted; reproducible. |

## Bundles

Bundles group related entries within a tier. The installer supports `--bundle <name>` to install
only a specific bundle (curated tier), or `--exclude-bundle <name>` to skip one.

Current bundles are defined in the `"bundles"` registry at the top of `skills-lock.json`.

## How to promote a skill to Tier 0 (core)

1. Find the original upstream repo (not the aggregator).
2. Record the latest commit SHA (`git ls-remote <repo> HEAD`).
3. Compute `sha256` of the anchor file (`sha256sum <anchor-file>`).
4. Add the entry to `skills` in `skills-lock.json` with `"tier": "core"`.
5. Add a row to `docs/VERIFIED_SKILLS_LIBRARY.md`.
6. Open a PR — CI validates the lock; human reviews before merge.

## How to deprecate (never delete)

1. Change `"tier"` from `"core"`/`"curated"` to `"archived"`.
2. Add a `"deprecation"` field:
   ```json
   { "since": "YYYY-MM-DD", "reason": "superseded by X", "replacedBy": "new-skill" }
   ```
3. Archived entries are excluded from default installs but remain in the lock for reproducibility.
