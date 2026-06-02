# AI OS Services Layer — Build Plan (`ai-os-services`)

> A **separate repo** delivering the long-running services (model router, vector DB, RAG, observability) as a
> local-first Docker Compose stack. The workstation installer (`ai-dev-setup`) stays "what's on my laptop";
> services get their own lifecycle, volumes, and release cadence. The two meet at **one contract**: a LiteLLM
> endpoint URL + a local key.
>
> **Constraint:** this plan installs **zero** skills/agents and touches nothing in `~/.claude`. Every
> skill/agent implication is an *additive, pinned* `skills-lock.json` entry for future installs.

## MVP services (verified/maintained images, loopback-only)
| Service | Image | Role | Host port |
|---|---|---|---|
| **LiteLLM** | `ghcr.io/berriai/litellm:main-stable` | OpenAI-compatible router over host Ollama + cloud | `127.0.0.1:4000` |
| **Qdrant** | `qdrant/qdrant` (pin digest) | vector DB | `127.0.0.1:6333/6334` |
| **RAG** | built `./rag` (LlamaIndex, `python:3.12-slim`) | RAG API over local KB | `127.0.0.1:8088` |
| **Langfuse** | `langfuse/langfuse:2` (MVP) → `:3` (hardening) | LLM observability/traces/eval | `127.0.0.1:3000` |
| Postgres / Redis | `postgres:16-alpine` / `redis:7-alpine` | metadata / queue | **internal only** |

> **Ollama is NOT containerized** — it stays native on the host (`:11434`, GPU-direct). LiteLLM reaches it via `host.docker.internal`. Your existing models (`qwen3-coder:30b`, `deepseek-r1:32b`, …) are the local backends.
>
> **Langfuse fork:** v2 = Postgres-only (ideal MVP); v3 adds ClickHouse+MinIO+worker (analytics/eval store, hardening phase). Start v2.

## Repo shape (mirrors `ai-dev-setup` conventions)
```
ai-os-services/
  docker-compose.yml            # pinned image digests; secrets are ${VAR} placeholders
  .env.example                  # NON-secret defaults only
  config/litellm.config.yaml    # model_list (ollama + cloud), router policy
  rag/                          # Dockerfile + FastAPI app (/ingest /query /healthz)
  knowledge_base/               # MOUNTED :ro, gitignored — your corpus
  scripts/bringup.{sh,ps1}      # `infisical run -- docker compose up`
  scripts/doctor.{sh,ps1}       # health preflight (same convention as installer)
  justfile                      # just up / down / doctor / logs / ingest
  tests/smoke.{sh,ps1}          # compose-config lint + endpoint health (CI)
  docs/{ARCHITECTURE,INTEROP,HARDENING}.md  docs/adr/0001-services-split.md
  .github/workflows/ci.yml      # smoke + trivy image scan + gitleaks
```

## Security / local-first posture (the non-negotiables)
- **Every host port bound to `127.0.0.1`** — never `0.0.0.0`. Data stores have **no host port** (internal network only). Stack is invisible to the LAN by default.
- **Secrets via Infisical, never on disk** — `scripts/bringup.*` = `infisical run --path=/ai-os-services -- docker compose up -d`; `.env*` gitignored; global gitleaks hook covers it. `LITELLM_MASTER_KEY` minted into Infisical, never typed.
- **Authn on every service** (LiteLLM master key, Qdrant API key, Langfuse/Redis/PG passwords).
- **No phone-home** (`TELEMETRY_ENABLED=false`); 100% local if you omit cloud keys.
- **RAG corpus `:ro` + gitignored** — readable, not mutable, never leaks via git.
- **All model traffic flows through LiteLLM** → Langfuse is the single audit log of what was sent where (the governance hook).
- **Supply chain:** official images, **pinned by `@sha256` digest** + `trivy image` scan in CI before "trusted" (extends the installer's trivy posture).

## Interop with `ai-dev-setup` (installer-framework changes only)
Contract is one-directional and tiny — services *publish* an endpoint, the installer *renders* clients at it:
1. **`config/services.csv`** (new, in `ai-dev-setup`) — `service,host,port,health,secret_ref` (same single-source pattern as tools/models).
2. **`templates/CLAUDE.md.tmpl`** (edit) — an "AI OS Services" section rendered from `services.csv` (existing deployed `CLAUDE.md` untouched; next render picks it up).
3. **`~/.aider.conf.yml`** rendering → point Aider at `http://localhost:4000` (LiteLLM) so even local coding is routed + traced; launched as `infisical run -- aider`.
4. **Claude Code / Codex** stay on their OAuth for interactive use; only *scripted SDK/API* calls get `ANTHROPIC_BASE_URL`/OpenAI base → the router. Document in `INTEROP.md` (interactive CLI sessions won't appear in Langfuse — only SDK traffic).
5. **`doctor` `-ServicesCheck`** — optionally curls `services.csv` endpoints and reports up/down. The workstation install **never hard-depends** on the services layer (a Docker-less laptop still installs cleanly).
6. **Additive `skills-lock.json` pins** so future installs *can* lay down services-relevant skills you already have (`litellm`, `langfuse`, `rag-engineer`, `vector-database-engineer`, `llm-ops`, `embedding-strategies`) — pinned + SHA-verified, retain-biased.

## MVP → hardening
- **Phase 0 (MVP):** LiteLLM + host Ollama (prove routing) → +Qdrant+RAG (ingest KB, grounded `/query`) → +Langfuse v2 (traces) → point Aider at LiteLLM.
- **Phase 1 (interop):** land the `ai-dev-setup` changes (services.csv, CLAUDE.md section, aider render, doctor check, additive pins); add cloud keys + LiteLLM router policy (cheap-local-first, cloud-fallback, per-model budgets — pairs with `ruflo-cost-tracker`).
- **Phase 2 (hardening):** pin every image `@sha256` + trivy-gate CI; graduate Langfuse v3; LiteLLM guardrails + **scoped virtual keys** per client (least privilege); scheduled `pg_dump` + Qdrant snapshots; optional Caddy for local TLS.
- **Phase 3 (governance):** `agent-governance-toolkit` as a policy/reporting layer over the Langfuse trace store + LiteLLM budgets (egress allow/deny, audit export) — bolts on because everything already routes through LiteLLM. Add governance skills as additive pinned lock entries.

## Decisions to verify at build time
Langfuse v2-vs-v3 (the one real fork) · embeddings model pulled into host Ollama + exposed as a LiteLLM alias so RAG embeds *through* the router · `host.docker.internal` (works on Docker Desktop; `host-gateway` line keeps it portable) · no GPU-container dep in MVP (GPU stays native) · the two repos stay **decoupled** (installer only optionally detects the services).
