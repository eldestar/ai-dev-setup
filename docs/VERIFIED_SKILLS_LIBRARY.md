# Verified Skills Library

> The source-of-truth provenance record referenced by `skills-lock.json`. Every entry in the lock must appear
> here with its upstream repo, pinned ref, license, trust tier, and verification notes.
> (This file was referenced by the lock but missing — created to close that gap.)

## Trust & pinning rules
- **Pin by commit SHA** unless the upstream publishes real version tags (then prefer `@version`).
- Record `sha256` anchors for file/dir skills (strongest pin); agents rely on git-commit integrity + per-file maps.
- "Source-available" / `NOASSERTION` / `personal-only` licenses are flagged but allowed for **personal** use.
- A bot's own approval never promotes an entry — a human curates into the lock.

---

## Currently pinned (skills-lock.json v3)

### Skills
| Name | Tier | Bundle | Source | Ref (pin) | License | Notes |
|---|---|---|---|---|---|---|
| `impeccable` | core | frontend-design | pbakaus/impeccable | `69b5f3a…` | Apache-2.0 | design/UI; SHA-256 anchor on SKILL.md |
| `emil-design-eng` | core | frontend-design | emilkowalski/skill | `ecf66bb…` | NOASSERTION | motion/design; **personal-only** scope |

### Agents
| Source | Tier | Bundle | Repo | Ref | License | Personas |
|---|---|---|---|---|---|---|
| wshobson | core | dev-loop-agents | wshobson/agents | `0818067…` | MIT | security-auditor, code-reviewer, architect-review, test-automator, docs-architect |
| dl-ezo | core | dev-loop-agents | dl-ezo/claude-code-sub-agents | `532213d…` | MIT | design-reviewer, test-suite-generator |
| voltagent | core | dev-loop-agents | VoltAgent/awesome-claude-code-subagents | `2f9cf8b…` | MIT | compliance-auditor, error-detective, dx-optimizer, dependency-manager, git-workflow-manager |

### Agents — Tier-0 specialists (curated, batch 1)
> From `wshobson/agents` @ `0818067` (same trusted source as the core agents). Pinned by commit + path (no sha256, per the agent model). Map to Benjamin's stack.

| Target file | Bundle | wshobson path |
|---|---|---|
| `wshobson-python-pro.md` | dev-core | plugins/python-development/agents/python-pro.md |
| `wshobson-typescript-pro.md` | dev-core | plugins/javascript-typescript/agents/typescript-pro.md |
| `wshobson-javascript-pro.md` | dev-core | plugins/javascript-typescript/agents/javascript-pro.md |
| `wshobson-rust-pro.md` | dev-core | plugins/systems-programming/agents/rust-pro.md |
| `wshobson-golang-pro.md` | dev-core | plugins/systems-programming/agents/golang-pro.md |
| `wshobson-fastapi-pro.md` | dev-core | plugins/python-development/agents/fastapi-pro.md |
| `wshobson-frontend-developer.md` | dev-core | plugins/frontend-mobile-development/agents/frontend-developer.md |
| `wshobson-ai-engineer.md` | ai-llm | plugins/llm-application-dev/agents/ai-engineer.md |
| `wshobson-prompt-engineer.md` | ai-llm | plugins/llm-application-dev/agents/prompt-engineer.md |

### Agents — Tier-0 specialists (curated, batch 2: DevOps + security)
> From `wshobson/agents` @ `0818067`. DevOps + defensive-security specialists (Terraform/k8s satisfy the audit's IaC/k8s targets; security-coder agents complement the pinned security-auditor without duplicating it).

| Target file | Bundle | wshobson path |
|---|---|---|
| `wshobson-terraform-specialist.md` | devops | plugins/cloud-infrastructure/agents/terraform-specialist.md |
| `wshobson-kubernetes-architect.md` | devops | plugins/cloud-infrastructure/agents/kubernetes-architect.md |
| `wshobson-deployment-engineer.md` | devops | plugins/cloud-infrastructure/agents/deployment-engineer.md |
| `wshobson-devops-troubleshooter.md` | devops | plugins/incident-response/agents/devops-troubleshooter.md |
| `wshobson-observability-engineer.md` | devops | plugins/observability-monitoring/agents/observability-engineer.md |
| `wshobson-backend-security-coder.md` | security-defensive | plugins/backend-api-security/agents/backend-security-coder.md |
| `wshobson-frontend-security-coder.md` | security-defensive | plugins/frontend-mobile-security/agents/frontend-security-coder.md |

### Plugins / MCP (install via `claude`)
| Name | Tier | Bundle | Source | Ref | Notes |
|---|---|---|---|---|---|
| claude-plugins-official | core | platform-dx | anthropics/claude-plugins-official | `bf7e852…` | Anthropic-curated marketplace |
| superpowers | core | platform-dx | obra/superpowers-marketplace | `af4c8d8…` | methodology (Jesse Vincent) |
| codex | core | platform-dx | openai/codex-plugin-cc | `807e03a…` | cross-model review (installed locally, v1.0.4) |
| security-review | core | security-defensive | anthropics/claude-code-security-review | `0c6a49f…` | first-party `/security-review` |
| anthropics-skills | core | platform-dx | anthropics/skills | `da20c92…` | doc skills source-available; **make docx/pdf/pptx/xlsx explicit `sha256` entries** (see audit) |
| spec-kit | core | platform-dx | github/spec-kit | (uv tool) | spec-driven workflow |
| MCP: github / trivy / semgrep | core | platform-dx + security-defensive | official | `github` pinned `@2025.4.8` | github now pinned `@2025.4.8` (no longer unpinned); trivy/semgrep security tooling |
| MCP: osv-scanner | core | security-defensive | google/osv-scanner | binary (installed separately) | OSV-grade dep review — fills CVE-reachability gap |

### Experimental — mined from ECC (bundle `agentic-ecc`, tier `experimental`, opt-in)
> Reviewed individually from `affaan-m/ECC` @ `99baa825` (2026-06-02). Pinned per-file with SHA-256 anchors; the ECC aggregator itself is NOT trusted wholesale (see `docs/ECC_TOOLS_TRUST_REVIEW.md` in the eval project). Experimental = not installed by default.

| Skill | True origin | sha256 anchor (SKILL.md) | Why |
|---|---|---|---|
| `agentic-engineering` | ECC | `fdd1c187…` | eval-first agent dev doctrine |
| `context-budget` | ECC | `445cde88…` | audit token/context overhead across components |
| `agent-architecture-audit` | oh-my-agent-check (vendored) | `1a3d77ff…` | 12-layer agent-stack failure diagnostic |
| `mcp-server-patterns` | ECC | `be3ba4f4…` | Node/TS MCP server build patterns |
| `skill-scout` | community/redminwang (vendored) | `20117f09…` | search before creating a skill |
| `prompt-optimizer` | community/YannJY02 (vendored) | `5dc5e8b5…` | advisory prompt rewriting |
| `security-review` | ECC | `2243713f…` | security checklist/patterns skill |
| `strategic-compact` | ECC | `0852364a…` | context-compaction strategy |
| `agent-eval` | ECC | `d1c64d44…` | head-to-head coding-agent benchmarking |

---

## Proposed additions (from the audit — review before adding to the lock)

### New net-value pins (verified, see [SKILL_AUDIT.md](SKILL_AUDIT.md))
| Item | Source | Pin style | Tier |
|---|---|---|---|
| OSV-Scanner MCP | google/osv-scanner | tool version + `osv-scanner mcp` | core security |
| `plugin-eval` | wshobson/agents (subtree) | SHA (repo already pinned) | quality/self-improve |
| Context7 MCP | upstash/context7 | **tagged** `@version` (exemplar pin) | core DX |
| Sentry MCP | getsentry/sentry-mcp | marketplace+ref | optional (account-gated) |
| git-mcp-server | cyanheads/git-mcp-server | tagged `@version`, sandboxed | optional |
| superpowers-chrome | obra/superpowers-marketplace | marketplace ref bump | optional DX |
| Anthropic doc-skills (explicit) | anthropics/skills | per-file `sha256` anchors | core (make explicit) |

### Tier-0 skill promotions from the installed bundle (pin at original upstreams, not the aggregator)
Languages: `python-pro`, `typescript-pro`, `javascript-pro`, `rust-pro`, `golang-pro`, `fastapi-pro`, one React ref ·
AI/LLM: `rag-implementation`, `prompt-engineering`, `llm-structured-output`, `claude-api` ·
Security: `security-auditor`, `semgrep-rule-creator`, `sast-configuration`, `secrets-management` ·
DevOps: `docker-expert`, 1×Terraform, 1×k8s · SEO core (4).

### Tier-1 bundles (opt-in)
`azure-sdk`, `odoo`, `threejs`, `makepad`, `apple-hig`/`swiftui`, `apify`, `fp-ts`, `scientific-python`, `marketing` (split core/china), `seo-extended`, `offensive-security`, `devops-extended`, `business-ops` (agents), `design` (agents), `gamedev` (agents, dormant).

### Provenance caveats (record permanently)
- `antigravity-awesome-skills` = personal-account aggregator (`sickn33`). **Never a trusted source** — pin individual skills at their *original* repos. The 1460 on disk stay as the reference superset.
- `agency-agents` = personal-account aggregator (`msitarzewski`). Pin individual personas at SHA + sha256 before promotion; do not trust wholesale.
