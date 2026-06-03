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

## Currently pinned (skills-lock.json v2)

### Skills (Tier 0 — core)
| Name | Source | Ref (pin) | License | Notes |
|---|---|---|---|---|
| `impeccable` | pbakaus/impeccable | `69b5f3a…` | Apache-2.0 | design/UI; `.claude/skills/impeccable` dir; SHA-256 anchor on SKILL.md |
| `emil-design-eng` | emilkowalski/skill | `ecf66bb…` | NOASSERTION | motion/design; **personal-only** scope; SHA-256 anchor |

### Agents (Tier 0 — curated subset of 12)
| Source | Repo | Ref | License | Personas |
|---|---|---|---|---|
| wshobson | wshobson/agents | `0818067…` | MIT | security-auditor, code-reviewer, architect-review, test-automator, docs-architect |
| dl-ezo | dl-ezo/claude-code-sub-agents | `532213d…` | MIT | design-reviewer, test-suite-generator |
| voltagent | VoltAgent/awesome-claude-code-subagents | `2f9cf8b…` | MIT | compliance-auditor, error-detective, dx-optimizer, dependency-manager, git-workflow-manager |

### Plugins / MCP (install via `claude`)
| Name | Source | Ref | Notes |
|---|---|---|---|
| claude-plugins-official | anthropics/claude-plugins-official | `bf7e852…` | Anthropic-curated marketplace |
| superpowers | obra/superpowers-marketplace | `af4c8d8…` | methodology (Jesse Vincent) |
| codex | openai/codex-plugin-cc | `807e03a…` | cross-model review (installed locally, v1.0.4) |
| security-review | anthropics/claude-code-security-review | `0c6a49f…` | first-party `/security-review` |
| anthropics-skills | anthropics/skills | `da20c92…` | doc skills source-available; **make docx/pdf/pptx/xlsx explicit `sha256` entries** (see audit) |
| spec-kit | github/spec-kit | (uv tool) | spec-driven workflow |
| MCP: github / trivy / semgrep | official | — | ⚠ `github`/`semgrep` use unpinned `npx -y` — pin `@version` (latent gap) |

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
