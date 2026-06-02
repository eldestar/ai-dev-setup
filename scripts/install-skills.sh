#!/usr/bin/env bash
# install-skills.sh — install ONLY the pinned allowlist from skills-lock.json (Mac/Linux).
# No bulk installs. Clones each source at its pinned commit SHA, copies the declared files,
# and verifies SHA-256 anchors for skills. Plugins/MCP are printed as the claude commands to run.
#
# Usage:  scripts/install-skills.sh [path-to-skills-lock.json]
#   env:  CLAUDE_HOME (default ~/.claude)
set -u

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
LOCK="${1:-$REPO_ROOT/skills-lock.json}"
TARGET="${CLAUDE_HOME:-$HOME/.claude}"
CACHE="${TMPDIR:-/tmp}/ai-dev-skills-cache"
PY="$(command -v python3 || command -v python || true)"

[ -f "$LOCK" ] || { echo "[!] skills-lock.json not found at $LOCK"; exit 0; }
command -v git >/dev/null 2>&1 || { echo "[!] git is required for skills install — skipping"; exit 0; }
[ -n "$PY" ] || { echo "[!] python is required to parse skills-lock.json — skipping"; exit 0; }

mkdir -p "$CACHE" "$TARGET/skills" "$TARGET/agents"

sha256_of() {
  if command -v sha256sum >/dev/null 2>&1; then sha256sum "$1" | awk '{print $1}'
  else shasum -a 256 "$1" | awk '{print $1}'; fi
}

repo_at_ref() {  # $1=repo $2=ref  -> prints cache dir, or returns 1
  local repo="$1" ref="$2" key dir
  key="$(printf '%s' "$repo" | tr -c 'a-zA-Z0-9' '_')_${ref:0:8}"
  dir="$CACHE/$key"
  if [ ! -d "$dir/.git" ]; then
    mkdir -p "$dir"
    git -C "$dir" init -q
    git -C "$dir" remote add origin "$repo" 2>/dev/null
    git -C "$dir" fetch -q --depth 1 origin "$ref" || return 1
    git -C "$dir" checkout -q FETCH_HEAD || return 1
  fi
  printf '%s' "$dir"
}

# Flatten the lock into tab-separated rows with python (no jq dependency).
PLAN="$("$PY" - "$LOCK" <<'PYEOF'
import json, sys
lock = json.load(open(sys.argv[1], encoding="utf-8"))
for s in lock.get("skills", []):
    print("\t".join(["SKILL", s["name"], s["repo"], s["ref"], s["from"], s.get("anchor",""), s.get("sha256","")]))
for a in lock.get("agents", []):
    for tgt, path in a.get("files", {}).items():
        print("\t".join(["AGENT", tgt, a["repo"], a["ref"], path]))
for p in lock.get("plugins", []):
    if p.get("plugin"):       print("\t".join(["PLUGIN", "/plugin marketplace add %s#%s ; /plugin install %s" % (p["marketplace"], p["ref"], p["plugin"])]))
    elif p.get("marketplace"):print("\t".join(["PLUGIN", "/plugin marketplace add %s   (install desired plugins)" % p["marketplace"]]))
    elif p.get("install"):    print("\t".join(["PLUGIN", p["install"]]))
    else:                     print("\t".join(["PLUGIN", "%s: %s @ %s" % (p["name"], p.get("repo",""), p["ref"])]))
for m in lock.get("mcp", []):
    print("\t".join(["MCP", m["cmd"]]))
PYEOF
)"

echo ""
echo "=== Skills (pinned, SHA-256 verified) ==="
printf '%s\n' "$PLAN" | grep '^SKILL' | while IFS=$'\t' read -r _ name repo ref from anchor sha; do
  src="$(repo_at_ref "$repo" "$ref")" || { echo "  [!] $name: fetch of pinned ref failed"; continue; }
  [ -e "$src/$from" ] || { echo "  [!] $name: source path '$from' missing at pinned ref"; continue; }
  dest="$TARGET/skills/$name"
  rm -rf "$dest"; mkdir -p "$dest"; cp -R "$src/$from/." "$dest/"
  if [ -n "$sha" ] && [ -n "$anchor" ]; then
    got="$(sha256_of "$dest/$anchor")"
    if [ "$got" != "$sha" ]; then echo "  [!] $name: SHA-256 MISMATCH (expected $sha, got $got) — left in place, review"; continue; fi
  fi
  echo "  [OK] $name (verified)"
done

echo ""
echo "=== Agents (pinned, reviewed subset) ==="
printf '%s\n' "$PLAN" | grep '^AGENT' | while IFS=$'\t' read -r _ target repo ref path; do
  src="$(repo_at_ref "$repo" "$ref")" || { echo "  [!] $target: fetch of pinned ref failed"; continue; }
  [ -f "$src/$path" ] || { echo "  [!] $target: '$path' missing at pinned ref"; continue; }
  cp -f "$src/$path" "$TARGET/agents/$target"
  echo "  [OK] $target"
done

echo ""
echo "=== Plugins / MCP — run inside a 'claude' session (auth may be required) ==="
printf '%s\n' "$PLAN" | grep -E '^(PLUGIN|MCP)' | while IFS=$'\t' read -r _ cmd; do echo "  $cmd"; done
echo ""
echo "Skills/agents installed from the pinned allowlist into $TARGET"
