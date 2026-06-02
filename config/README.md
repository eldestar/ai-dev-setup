# config/ — single source of truth

These files are the **one place** the installers read shared facts from. Edit here; the
installers (and docs) consume them. This is what kills the SETUP.md ↔ setup-windows.ps1 drift.

| File | What | Consumed by |
|---|---|---|
| `models.csv` | Ollama model tiers: `gpu_type,min_gb,primary,fast` | model-selection in both installers |
| `tools.csv` | Core CLI tools: `id,check,scoop,brew` | tool install loop in both installers |
| `../templates/CLAUDE.md.tmpl` | The one CLAUDE.md template (`{{TOKENS}}`) | both installers render it |

## models.csv selection rule
For the detected `gpu_type` (nvidia uses VRAM; apple_silicon / cpu_only use RAM; amd → treated as cpu_only),
pick the **first row, scanning high→low `min_gb`, whose `min_gb` ≤ your capacity**.

> Reconciliation note: the two installers previously disagreed on the CPU-only tier
> (bash capped at `llama3.2:3b`; PowerShell scaled CPU up to `qwen3:32b`). Reconciled here to
> a moderate CPU ladder (`qwen3:8b` at ≥32 GB, else `llama3.2:3b`) to avoid recommending
> 32B models for CPU-only inference.

## tools.csv
`check` is the command used to test "already installed" (e.g. `rg` for the `ripgrep` package).
Only the package-manager-uniform core CLI tools live here. Bespoke installs (Claude Code, Ollama,
aider, Codex, gitleaks/trivy/semgrep, infisical, markitdown) remain in the installer until the
full component manifest lands in P1.
