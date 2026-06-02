#!/usr/bin/env bash
# doctor.sh — read-only preflight / health check (Mac/Linux). Changes nothing.
# Reports environment + per-component status and audits installed skills/agents
# against skills-lock.json. Run before or after install.
set -u
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TARGET="${CLAUDE_HOME:-$HOME/.claude}"
PY="$(command -v python3 || command -v python || true)"
ok=0; miss=0

check() {
  if command -v "$1" >/dev/null 2>&1; then printf '  [OK]   %s\n' "$1"; ok=$((ok+1))
  else printf '  [MISS] %s\n' "$1"; miss=$((miss+1)); fi
}

echo ""
echo "=== Environment ==="
echo "  OS: $(uname -s) $(uname -r)   Arch: $(uname -m)"

echo ""
echo "=== Tools ==="
core=""
while IFS=',' read -r id chk scoop brew; do
  { [ "$id" = "id" ] || [ -z "$id" ]; } && continue
  core="$core $chk"
done < "$REPO_ROOT/config/tools.csv"
for t in $core claude codex aider ollama uv gitleaks trivy semgrep infisical markitdown; do check "$t"; done

echo ""
echo "=== Single-source config ==="
for f in config/models.csv config/tools.csv templates/CLAUDE.md.tmpl skills-lock.json; do
  if [ -f "$REPO_ROOT/$f" ]; then echo "  [OK]   $f"; else echo "  [MISS] $f"; fi
done

echo ""
echo "=== Skill/agent audit (installed vs skills-lock.json) ==="
if [ -n "$PY" ] && [ -f "$REPO_ROOT/skills-lock.json" ]; then
  "$PY" - "$REPO_ROOT/skills-lock.json" "$TARGET" <<'PYEOF'
import json, os, sys
lock = json.load(open(sys.argv[1], encoding="utf-8")); target = sys.argv[2]
want_skills = {s["name"] for s in lock.get("skills", [])}
want_agents = set()
for a in lock.get("agents", []): want_agents |= set(a.get("files", {}).keys())
def listing(p): return set(os.listdir(p)) if os.path.isdir(p) else set()
have_skills = listing(os.path.join(target, "skills"))
have_agents = listing(os.path.join(target, "agents"))
def report(label, want, have):
    missing = want - have; extra = have - want
    print("  %s: %d in lock, %d installed" % (label, len(want), len(have)))
    if missing: print("    not installed: " + ", ".join(sorted(missing)))
    if extra:   print("    UNPINNED/extra (not in lock): " + ", ".join(sorted(extra)))
    if not missing and not extra: print("    in sync")
report("skills", want_skills, have_skills)
report("agents", want_agents, have_agents)
PYEOF
else
  echo "  (python or skills-lock.json missing — audit skipped)"
fi

echo ""
echo "Summary: $ok tools present, $miss missing."
