# Self-Improvement — Rules of Engagement

This repo may **analyze itself and propose** changes freely. It may **never apply** a
non-trivial change to itself without a written plan, human review, and explicit approval.
Model: terraform `plan` → human reads → `apply`. Or: *Renovate, not auto-merge.*

## Hard rules

1. A self-review may **write only** to `docs/self-review/` and `docs/adr/`. Everything else is read-only to it.
2. It **must not** modify `runners/`, `config/`, `templates/`, `scripts/`, `skills-lock.json`, `.github/`, or `.claude/`.
3. Any proposed change to those paths must be expressed as a **findings + plan doc** in `docs/self-review/`, plus (if architectural) a **Proposed ADR** in `docs/adr/`. It is applied only after a human approves.
4. The agent's own review/approval **does not** satisfy the human-review requirement (OpenSSF Scorecard logic: a bot's self-approval is not review).
5. Changes to this rule set, to CI, or to branch protection are maximally protected — human review, never proposed-and-applied in one step.

## The loop (when implemented)

1. **Scan (deterministic, cheap):** `tests/smoke.*`, `scripts/doctor.*`, gitleaks, the single-source drift check.
2. **Judge (LLM):** cluster + prioritize findings, draft a remediation plan.
3. **Write** `docs/self-review/YYYY-MM-DD-findings.md` (+ Proposed ADR if needed). Stop.
4. **Human** reviews → approves → changes go through the normal PR/commit gate.

## Decision log

Architecture decisions live in `docs/adr/NNNN-title.md` (Nygard format: Context / Decision / Consequences),
append-only, immutable once accepted. Superseding decisions get a new ADR referencing the old one.
