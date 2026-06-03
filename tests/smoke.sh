#!/usr/bin/env bash
# smoke.sh — fast validation gate (no installs). Exits non-zero on any failure.
# Run locally or in CI. Validates the single-source config, lock, and templates.
set -u
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PY="$(command -v python3 || command -v python || true)"
fail=0
pass() { printf '  [PASS] %s\n' "$*"; }
bad()  { printf '  [FAIL] %s\n' "$*"; fail=$((fail+1)); }

echo "=== smoke tests (bash) ==="

# 1. skills-lock.json valid JSON
if [ -n "$PY" ]; then
  if "$PY" -c "import json,sys;json.load(open(sys.argv[1],encoding='utf-8'))" "$REPO_ROOT/skills-lock.json" 2>/dev/null; then pass "skills-lock.json valid JSON"; else bad "skills-lock.json invalid JSON"; fi
else
  echo "  [skip] JSON check (no python)"
fi

# 1b. skills-lock.json v3 schema: tiers+bundles registries, every entry has tier
if [ -n "$PY" ]; then
  if "$PY" - "$REPO_ROOT/skills-lock.json" <<'PYEOF'
import json, sys
lock = json.load(open(sys.argv[1], encoding="utf-8"))
assert lock.get("version") == 3, "version != 3"
assert "tiers" in lock, "missing 'tiers' registry"
assert "bundles" in lock, "missing 'bundles' registry"
for s in lock.get("skills", []):
    assert "tier" in s, "skill '%s' missing 'tier'" % s.get("name")
for a in lock.get("agents", []):
    assert "tier" in a, "agent source '%s' missing 'tier'" % a.get("source")
for p in lock.get("plugins", []):
    assert "tier" in p, "plugin '%s' missing 'tier'" % p.get("name")
for m in lock.get("mcp", []):
    assert "tier" in m, "mcp '%s' missing 'tier'" % m.get("name")
print("ok")
PYEOF
  then pass "skills-lock.json v3 schema (tiers/bundles/tier fields)"; else bad "skills-lock.json v3 schema invalid"; fi
else
  echo "  [skip] v3 schema check (no python)"
fi

# 2. config CSV headers
if head -1 "$REPO_ROOT/config/models.csv" | grep -q '^gpu_type,min_gb,primary,fast'; then pass "models.csv header"; else bad "models.csv header"; fi
if head -1 "$REPO_ROOT/config/tools.csv"  | grep -q '^id,check,scoop,brew';        then pass "tools.csv header";  else bad "tools.csv header";  fi

# 3. template tokens are all well-formed {{...}} and render leaves nothing
tmp="$(mktemp)"
sed -E 's/\{\{[A-Z0-9_]+\}\}/X/g' "$REPO_ROOT/templates/CLAUDE.md.tmpl" > "$tmp"
if grep -q '{{' "$tmp"; then bad "template has malformed/unrenderable tokens"; else pass "template tokens all render"; fi
rm -f "$tmp"

# 4. single-source drift: the table-only model qwen3:32b must appear ONLY under config/
#    (exclude tests/ — these scripts reference it on purpose — and the config/ docs/data)
hits="$(grep -rl 'qwen3:32b' "$REPO_ROOT" --include='*.md' --include='*.ps1' --include='*.sh' 2>/dev/null | grep -v '/config/' | grep -v '/tests/' || true)"
if [ -z "$hits" ]; then pass "no inline model table (single source)"; else bad "qwen3:32b found outside config/models.csv: $hits"; fi

# 5. model selection logic returns expected for RTX 3080 (nvidia, 10GB VRAM)
P=""; F=""
while IFS=',' read -r g m p f; do { [ "$g" = "gpu_type" ] || [ -z "$g" ]; } && continue; [ "$g" = "nvidia" ] || continue; if [ 10 -ge "$m" ]; then P="$p"; F="$f"; break; fi; done < "$REPO_ROOT/config/models.csv"
if [ "$P" = "qwen3:8b" ] && [ "$F" = "llama3.2:3b" ]; then pass "model selection nvidia/10GB -> qwen3:8b"; else bad "model selection wrong: $P / $F"; fi

echo ""
if [ "$fail" -eq 0 ]; then echo "All smoke tests passed."; exit 0; else echo "$fail smoke test(s) failed."; exit 1; fi
