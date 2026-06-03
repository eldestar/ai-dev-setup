# Skill & Agent Audit (document-only)

> Audit of the **reference environment**: `~/.claude/skills` (1460 dirs) + `~/.claude/agents` (184 files),
> installed out-of-band via the `antigravity-awesome-skills` aggregator + `msitarzewski/agency-agents`.
>
> **Constraints honored:** nothing here removes/modifies/relocates any local asset. Every recommendation is a
> change to the **installer framework** (`skills-lock.json` tiers, `scripts/install-skills.*`, docs) to apply on
> *future* installs/upgrades. Bias = **retain + curate**, never delete. "Deprecate" = demote a tier in the lock.

---

## The core structural finding

`skills-lock.json` currently pins **2 skills + 12 agents + 6 plugins + 3 MCP**. The 1460 skills / 184 agents on disk were installed *outside* the verified path. The fix is **tiering**, not deletion:

| Tier | Meaning | Install default |
|---|---|---|
| **Core** (Tier 0) | pinned + SHA-256-verified | always |
| **Curated bundles** (Tier 1) | vetted source + pinned ref, grouped by theme | opt-in per bundle |
| **Community / aggregator** (Tier 2) | the bulk of the 1460; unverified provenance | reproducible via `--include-experimental`, never default |

This lets you keep everything's value (curation lives in *tier assignment*, not in what's removed). The live machine is the (intentionally larger) reference superset.

---

## Skills audit — category level (1460)

| # | Category | ~Count | Judgement | Action in framework |
|---|---|---|---|---|
| 1 | Azure SDK (`azure-*`, per-service × 4 langs) | ~116 | **Merge/consolidate** — biggest fan-out dup | Tier 1 bundle `azure-sdk`; core-pin only the few used (`azure-ai-projects-py`, `azure-identity-py`) |
| 2 | Odoo (`odoo-*`) | 24 | Keep-as-is, niche | Tier 1 `odoo` |
| 3 | SEO/AEO/GEO | ~35 | **Merge** — most redundant in bundle (5+ near-clones of "seo content") | Promote **4** to core (keyword/meta/schema/audit); rest → Tier 1 `seo-extended` |
| 4 | UI engines (`threejs-*`, `makepad-*`, `hig-*`, swiftui) | ~50 | Keep — sensible decomposition, low overlap | Tier 1 bundles, niche |
| 5 | SaaS connectors (`*-automation`) | 88 | **Low-value to promote** — overlaps your first-party MCP (Slack/Notion/Gmail…) | Tier 2; flag overlap |
| 6 | Apify scrapers | 12 | Niche, vendor-locked | Tier 1 `apify` |
| 7 | **Language/framework specialists** (`*-pro`, fastapi/django/next/react) | ~26 | **Highest core value** — maps to your stack | Core-pin `python-pro`, `typescript-pro`, `javascript-pro`, `rust-pro`, `golang-pro`, `fastapi-pro`, one React ref |
| 8 | fp-ts (`fp-*`) | 15 | Deep, very niche | Tier 1 `fp-ts` |
| 9 | **Security** (defensive + offensive) | ~20+ | **Split** | Core-pin defensive (`security-auditor`, `semgrep-rule-creator`, `sast-configuration`, `secrets-management`); offensive → Tier 1 `offensive-security` (provenance-flagged) |
| 10 | **AI/LLM engineering** (rag/llm/prompt/agents) | ~40 | **Core to your use case**; high overlap | Core-pin one each: `rag-implementation`, `prompt-engineering`, `llm-structured-output`, `claude-api`. (`mcp-builder` already a pinned plugin — reference, don't dup) |
| 11 | Context/agent-memory (`context-*`) | 11 | Low — overlaps **ruflo** (rag-memory/intelligence) | Tier 2; flag ruflo overlap |
| 12 | Marketing/sales/CRO psychology | ~30+ | Coherent, off dev-core; internal CRO dup | Tier 1 `marketing` |
| 13 | Scientific Python (polars/sklearn/plotly…) | ~15 | Keep, well-scoped | Tier 1 `scientific-python` |
| 14 | DevOps/k8s/terraform/observability | ~20 | Keep; some Terraform dup (4 variants) | Core-pin `docker-expert`, one Terraform, one k8s; rest Tier 1 |
| 15 | Localized verticals (legal-pt, health analyzers, regional) | ~25 | Low fit | Tier 2 |
| 16 | Persona/"thinker" (steve-jobs, karpathy…) | ~12 | Novelty | Tier 2 |
| 17 | Skill-management meta (`skill-*`) | 14 | Overlaps pinned `anthropic-skills:skill-creator` | Tier 1; don't dup-pin |

**Recommended Tier-0 promotions (~25–30):** languages (`python-pro`, `typescript-pro`, `javascript-pro`, `rust-pro`, `golang-pro`, `fastapi-pro`, one React) · AI/LLM (`rag-implementation`, `prompt-engineering`, `llm-structured-output`, `claude-api`) · security (`security-auditor`, `semgrep-rule-creator`, `sast-configuration`, `secrets-management`) · devops (`docker-expert`, 1×Terraform, 1×k8s) · SEO core (4) · keep `impeccable`, `emil-design-eng`. Each needs repo + commit SHA + SHA-256 anchor, recorded in `VERIFIED_SKILLS_LIBRARY.md`.

**Tier-1 bundles:** `azure-sdk`, `odoo`, `threejs`, `makepad`, `apple-hig`/`swiftui`, `apify`, `fp-ts`, `scientific-python`, `marketing`, `seo-extended`, `offensive-security`, `devops-extended`.

---

## Agents audit — category level (184 `agency-agents`)

The pinned 12 (wshobson/dl-ezo/voltagent) already own the **dev-loop axis** (review/test/security/DX/git) at higher curation quality. So:

| Group | ~Count | Judgement |
|---|---|---|
| `engineering-*` | 29 | **Redundant for promotion** — shadow-copies the pinned set. Only `ai-engineer`, `rapid-prototyper`, `mobile-app-builder`, `voice-ai`, `minimal-change-engineer`, `solidity` are additive |
| `marketing-*` | 30 | **Keep as opt-in bundle** — zero baseline overlap; split `marketing-core` vs `marketing-china` (~14 China-platform agents) |
| `testing-*` | 8 | Keep — **promote** `accessibility-auditor`, `performance-benchmarker` (fill gaps the pinned set lacks) |
| `design-*` | 8 | Keep bundle — complements your impeccable/emil skills |
| `sales-/paid-media-/product-/finance-/support-/project-management-` | ~39 | One opt-in `business-ops` bundle; no baseline overlap |
| `academic-*` (5), game/XR cluster (~24), vertical-business singletons (~22) | ~51 | **Low fit** — document as "installed-but-unpinned, install-on-demand"; never promote |
| `compliance-auditor` (root) | 1 | **Merge** — duplicate of pinned `voltagent-compliance-auditor` |

**Agent promotions (only the genuine gap-fillers):** `testing-accessibility-auditor`, `testing-performance-benchmarker`, `engineering-ai-engineer`, `engineering-rapid-prototyper` — pinned to SHA + sha256, matching the trust bar of the existing 12. **Do not promote any engineering review/security/architect/git persona** (baseline already covers them). `agency-agents` is a *personal-account aggregator* — record that provenance caveat; pin individual personas, never trust the source wholesale.

---

## New skills/plugins worth adding (verified, highest leverage first)

| # | Addition | Fills | Source / pin | Tier |
|---|---|---|---|---|
| 1 | **OSV-Scanner MCP** (Google) | **dependency-review gap** (OSV-grade CVE matching, reachability) — uncovered by trivy/semgrep | `google/osv-scanner`, pin tool version + `osv-scanner mcp` | core security |
| 2 | **wshobson `plugin-eval`** | **self-improvement / skill quality** — objective scoring to data-drive allowlist promotion (scores, humans promote; nothing deleted) | same `wshobson/agents` repo (already pinned), add at SHA | platform/quality |
| 3 | **Context7 MCP** (Upstash) | **prompt/context management** — version-specific lib docs on demand, cuts hallucinated APIs | `upstash/context7`, **tagged** `@version` (stronger pin) | core DX |
| 4 | **Sentry MCP** (official) | **prod observability** (errors/traces) — ruflo observes the agent side, not the shipped app | `getsentry/sentry-mcp`, marketplace+ref | optional, account-gated |
| 5 | **git-mcp-server** (cyanheads) | **repo review / git automation** — 28 git tools incl. blame/worktree/signing | tagged `@cyanheads/git-mcp-server@version`; sandbox it | optional |
| 6 | **superpowers-chrome** (obra) | **env diagnostics / webapp testing** — live Chrome introspection; same trusted maintainer as pinned superpowers | `obra/superpowers-marketplace` (already pinned) | optional DX |
| 7 | **Anthropic doc skills** (docx/pptx/pdf/xlsx) | **doc generation** — *already* reachable via the pinned `anthropics/skills`; make them **explicit `sha256` entries** for deterministic upgrades | `anthropics/skills` (pinned `da20c92`) | core, make explicit |

**Deliberately NOT recommended:** Langfuse/Helicone for *in-harness* cost (ruflo already does it — they're for app-level telemetry, belongs in the services layer); more bulk "N-skill" cybersecurity aggregators (same provenance class as antigravity); and `antigravity-awesome-skills` as a *trusted source* (pin individual upstreams instead).

> Latent finding to record: the pinned `github`/`semgrep` MCP commands use unpinned `npx -y` — a supply-chain gap. Pin `@pkg@version` where the upstream publishes tags (Context7, OSV, git-mcp-server do).

---

## Cross-references
- Installer-framework mechanics to support all of this (tiers, `update-lock`, catalog, schema, `skill-audit`, safe deprecation) → [SKILL_FRAMEWORK_PLAN.md](SKILL_FRAMEWORK_PLAN.md)
- Source provenance + pins for every promoted item → [VERIFIED_SKILLS_LIBRARY.md](VERIFIED_SKILLS_LIBRARY.md)
- Nothing in this document changes `skills-lock.json` yet — it is the **plan** to review before the curation PR.
