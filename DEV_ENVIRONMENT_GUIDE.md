# Dev Environment Guide
# Ben's M2 MacBook Air — Complete Reference
Last updated: 2026-05-16

---

## QUICK START

```bash
# New terminal → activate everything
source ~/.zshrc

# Start a new project
newproject my-app-name
cd my-app-name && claude

# Search your vault
rg "search term" ~/vault/

# Use Claude for a task
claude "do X"

# Use local AI (free, no quota)
aider   # uses qwen3:8b on Ollama by default
```

---

## MISSING / STILL NEEDS MANUAL ACTION

Before anything else, do these:

| # | What | Command / Action |
|---|------|-----------------|
| 1 | **Shell reload** | Open a new terminal tab — activates starship, mise (bun), fzf, aliases |
| 2 | **Claude login** | `claude login` → browser → sign in with Claude Pro account |
| 3 | **Codex login** | `codex` → select "Sign in with ChatGPT" → browser → ChatGPT Plus account |
| 4 | **Obsidian** | Download from obsidian.md → open `~/vault/` as vault → install plugins: Dataview, Templater, Git, QuickAdd |
| 5 | **Ruflo plugins** | Inside a `claude` session, run these slash commands: `/plugin marketplace add ruvnet/ruflo` then `/plugin install ruflo-core@ruflo`, `ruflo-swarm@ruflo`, `ruflo-rag-memory@ruflo`, `ruflo-cost-tracker@ruflo`, `ruflo-observability@ruflo`, `ruflo-aidefence@ruflo`, `ruflo-docs@ruflo`, `ruflo-autopilot@ruflo` |
| 6 | **flow-nexus MCP** | Currently failing to connect — run `npx flow-nexus@latest init` if needed, or remove with `claude mcp remove flow-nexus` |
| 7 | **Impeccable context** | In any project: `/teach-impeccable` inside a Claude Code session |

---

## THE TOOLS — WHAT EACH ONE DOES AND HOW TO USE IT

### AI CODING TOOLS

---

#### Claude Code (`claude`)
**What:** Anthropic's official AI coding CLI. Full agentic — reads files, runs shell commands, edits code. Powered by your Claude Pro subscription (no per-token cost).

**Auth:** Claude Pro OAuth (run `claude login` once)

```bash
# Start interactive session in current directory
claude

# One-shot task
claude "add input validation to the login form"

# Faster output (Opus with streaming)
claude --fast

# Check auth and quota status
claude /status

# List available MCP servers
claude mcp list

# List skills
/skills   # (inside a claude session)

# Add an MCP server
claude mcp add myserver -- npx myserver@latest start
```

**Quota:** Shared with claude.ai web — 5-hour rolling window. Heavy web usage reduces CLI quota. Check with `/status`.

---

#### Aider (`aider`)
**What:** Third-party multi-model coding assistant. Works in any git repo. Currently configured to use local Ollama (free). Good for: rapid iteration, working when subscription quota is low.

**Auth:** None needed — uses local Ollama.

```bash
# Start aider in current project (uses qwen3:8b by default)
aider

# Switch model for a session
aider --model ollama/llama3.2:3b    # faster, smaller
aider --model ollama/llama3:latest  # older llama3

# Ask a question without editing files
aider --message "explain this codebase"

# Add specific files to context
aider src/auth.py src/models.py

# If you add API keys later, use Claude/GPT directly:
aider --model claude-sonnet-4-6     # requires ANTHROPIC_API_KEY
aider --model gpt-4o                # requires OPENAI_API_KEY
```

**Config file:** `~/.aider.conf.yml` — edit to change defaults.

---

#### Codex CLI (`codex`)
**What:** OpenAI's coding CLI. Powered by your ChatGPT Plus subscription. Good for: tasks where GPT-4o has an edge (Python data work, code explanation), parallel use alongside Claude.

**Auth:** ChatGPT Plus OAuth (run `codex` once, sign in via browser)

```bash
# Interactive session
codex

# One-shot
codex "refactor this function to use async/await"

# Check quota
# (run /status inside a codex session)
```

**Note:** `codex` is in `~/.npm-global/bin/` — needs a new terminal or `source ~/.zshrc` to be on PATH.

---

#### Ollama (`ollama`)
**What:** Run LLMs locally on your M2. Zero cost, zero quota. Models run entirely on-device.

**Installed models:**
- `qwen3:8b` — 5.2GB — Best all-rounder for M2 16GB. Used by Aider by default.
- `llama3.2:3b` — 2.0GB — Fastest, smallest. Good for quick tasks.
- `llama3:latest` — 4.7GB — Older Llama3 base.

```bash
# Check running models
ollama list

# Pull a new model
ollama pull phi4-mini        # 3.8GB, fast
ollama pull llama3.2:3b      # already installed

# Start the Ollama service (if not running)
brew services start ollama
brew services stop ollama

# Run a model directly (no aider)
ollama run qwen3:8b

# Use from any app via API (port 11434)
curl http://localhost:11434/api/generate \
  -d '{"model":"qwen3:8b","prompt":"hello"}'
```

---

### SHELL & TERMINAL

---

#### Starship (`starship`)
**What:** Fast, informative shell prompt. Shows git branch, language versions, exit codes. Activates automatically after `source ~/.zshrc`.

```bash
# Customize prompt
starship config   # opens config in $EDITOR
# Config file: ~/.config/starship.toml
```

---

#### fzf
**What:** Fuzzy finder. After `source ~/.zshrc`, adds keyboard shortcuts to your terminal:
- `Ctrl+R` — fuzzy search command history
- `Ctrl+T` — fuzzy find files
- `Alt+C` — fuzzy cd into directories

```bash
# Use in scripts
ls | fzf                          # pick from list
git checkout $(git branch | fzf)  # fuzzy branch switch
```

---

#### bat (`bat`)
**What:** `cat` replacement with syntax highlighting. Aliased to `cat` in your shell after reload.

```bash
cat file.py          # syntax highlighted (uses bat)
bat file.py          # explicit
bat --plain file.py  # no line numbers/decorations
```

---

#### ripgrep (`rg`)
**What:** Extremely fast code search. Aliased to `grep` after shell reload.

```bash
rg "pattern" .                    # search current directory
rg "TODO" ~/vault/               # search vault
rg -l "function auth"            # list files only
rg --type py "import requests"   # Python files only
rg -n "error" logs/              # with line numbers
```

---

#### lazygit (`lazygit`)
**What:** Terminal UI for git. Keyboard-driven — browse commits, stage hunks, resolve conflicts.

```bash
lazygit   # run in any git repo
```
Key bindings inside lazygit: `s` stage, `c` commit, `p` push, `?` help.

---

#### zellij (`zellij`)
**What:** Terminal multiplexer (like tmux but friendlier). Run multiple terminal panes in one window. Good for: running a dev server + claude + a watcher simultaneously.

```bash
zellij                   # start new session
zellij attach            # attach to existing session
# Inside zellij: Ctrl+p then n = new pane, arrow keys navigate
```

---

#### mise (`mise`)
**What:** Runtime version manager. Manages Node, Python, Bun per-project. Replaces nvm, pyenv, etc.

```bash
# List installed runtimes
mise list

# Install a version
mise install node@22
mise install python@3.12

# Set version for current project
mise use node@22           # writes .mise.toml in current dir
mise use python@3.12

# Set global default
mise use --global node@lts

# Run a command with a specific version
mise exec node@22 -- node --version
```

**Installed versions:** Node 24.15.0, Python 3.14.5, Bun 1.3.14

---

#### just (`just`)
**What:** Command runner (like make, but sane). Define project tasks in a `Justfile`.

```bash
# List available tasks in current project
just --list

# Run a task
just build
just test
just deploy

# Example Justfile:
# test:
#   pytest tests/
# build:
#   bun run build
```

---

#### DuckDB (`duckdb`)
**What:** Embedded SQL engine. Query CSV, JSON, Parquet files directly — no database setup needed.

```bash
duckdb                                          # interactive shell
duckdb -c "SELECT * FROM 'data.csv' LIMIT 10"  # one-shot query
duckdb -c "SELECT * FROM 'data.json'"          # JSON too
duckdb mydb.db                                  # persistent database

# From inside duckdb shell:
# .open data.csv         — load a file
# .tables               — list tables
# SELECT count(*) FROM read_csv_auto('file.csv');
```

---

### PACKAGE MANAGERS

---

#### uv
**What:** Extremely fast Python package manager. Use instead of pip for everything.

```bash
# Install a package
uv pip install requests

# Create a virtual environment
uv venv .venv
source .venv/bin/activate

# Install from requirements.txt
uv pip install -r requirements.txt

# Run a script without installing
uvx ruff check .

# Install a tool globally (like pipx)
uv tool install black
```

---

#### bun
**What:** Fast JavaScript runtime + package manager. Replaces npm/yarn for most use cases. Available after shell reload (managed by mise).

```bash
bun install           # install dependencies (reads package.json)
bun add react         # add a package
bun run dev           # run a script
bun test              # run tests
bun build ./index.ts  # bundle
bunx cowsay hello     # run a package without installing (like npx)
```

---

### KNOWLEDGE BASE

---

#### vault (`~/vault/`)
**What:** Your personal knowledge base. Plain markdown files. Git-versionable. Searchable with ripgrep. Accessible to Claude via MCP.

**Structure:**
```
~/vault/
├── AGENTS.md       ← Claude reads this first (vault guide)
├── raw/            ← Source documents, imported PDFs (never edit)
├── wiki/           ← Processed notes, research summaries
├── playbooks/      ← Claude-executable workflows (SKILL.md files)
├── templates/      ← Note templates with frontmatter
├── agents/         ← Agent persona definitions
├── daily/          ← Daily notes, research log, capture inbox
└── projects/       ← One subfolder per project (CONTEXT.md entry point)
```

```bash
# Search vault
rg "machine learning" ~/vault/

# Convert a PDF/file into markdown for the vault
markitdown document.pdf > ~/vault/raw/document.md

# Then process it into a wiki note
claude "Read ~/vault/raw/document.md and create a wiki note in ~/vault/wiki/"
```

**Frontmatter standard for wiki/ notes:**
```yaml
---
title: Note Title
date_added: 2026-05-16
tags: [tag1, tag2]
status: draft | active | archived
type: research | runbook | project | reference
importance: low | medium | high
source: filename or URL
---
```

---

#### markitdown (`markitdown`)
**What:** Converts any file to clean markdown. PDF, Word, Excel, PowerPoint, HTML — all become markdown that Claude can read.

```bash
markitdown document.pdf > ~/vault/raw/document.md
markitdown slides.pptx > ~/vault/raw/slides.md
markitdown report.docx > ~/vault/raw/report.md
markitdown data.xlsx > ~/vault/raw/data.md
```

---

### SECURITY TOOLS

---

#### gitleaks (`gitleaks`)
**What:** Scans git repos for accidentally committed secrets (API keys, tokens, passwords). **Auto-runs on every `git commit`** via the global pre-commit hook.

```bash
# Scan staged changes before commit (auto via hook, but manual too)
gitleaks protect --staged

# Scan entire repo history
gitleaks detect

# Scan a specific directory
gitleaks detect --source .

# If it blocks a commit with a false positive:
SKIP=gitleaks git commit -m "message"   # bypass once
```

---

#### trivy (`trivy`)
**What:** Vulnerability scanner. Checks code, containers, and dependencies for known CVEs.

```bash
# Scan current project dependencies
trivy fs .

# Scan a Docker image
trivy image nginx:latest

# Scan with specific severity
trivy fs . --severity HIGH,CRITICAL

# Output as JSON
trivy fs . --format json > scan-results.json
```

---

#### semgrep (`semgrep`)
**What:** Static analysis — finds code patterns, security anti-patterns, and bugs. Language-aware (understands syntax, not just text).

```bash
# Scan with default rules
semgrep --config=auto .

# Security-focused scan
semgrep --config=p/security .

# Python-specific
semgrep --config=p/python .

# OWASP top 10
semgrep --config=p/owasp-top-ten .
```

---

#### Infisical (`infisical`)
**What:** Secret manager. Replaces `.env` files. Secrets are encrypted and synced — no more secrets in repos.

```bash
# Initialize in a project
infisical init                    # links to your Infisical project

# Run a command with secrets injected
infisical run -- node server.js
infisical run -- python app.py

# Add a secret
infisical secrets set API_KEY=abc123

# List secrets
infisical secrets list

# Export to .env (for tools that need it)
infisical export --format dotenv > .env.local
```

---

### MCP SERVERS (Claude's extended capabilities)

MCP servers give Claude Code access to external systems. They connect automatically when you run `claude`.

| Server | Status | What it gives Claude |
|--------|--------|---------------------|
| `vault` | ✓ Connected | Read/write your `~/vault/` knowledge base |
| `ruflo` | ✓ Connected | Multi-agent orchestration |
| `ruv-swarm` | ✓ Connected | Swarm-mode agent coordination |
| `flow-nexus` | ✗ Failed | Workflow automation (needs init) |
| Granola | ✓ Connected | Meeting notes/transcripts |
| Slack | ✓ Connected | Slack read/search |
| Notion | ✓ Connected | Notion pages |
| Atlassian Rovo | ✓ Connected | Jira/Confluence |
| Google Drive | ✓ Connected | Drive files |
| Google Calendar | ✓ Connected | Calendar events |
| Gmail | ✓ Connected | Email |

```bash
# See all MCP servers and health
claude mcp list

# Add a new MCP server (project-scoped)
claude mcp add myserver -- npx myserver@latest start

# Add user-scoped (available in all projects)
claude mcp add myserver --scope user -- npx myserver@latest start

# Remove a server
claude mcp remove flow-nexus
```

---

#### Ruflo (multi-agent orchestration)
**What:** Agent orchestration layer. Lets Claude spawn sub-agents, coordinate multi-step tasks, and maintain memory across sessions.

```bash
# Initialize Ruflo (first time setup)
npx ruflo@latest init wizard

# Inside a claude session, install plugins:
/plugin marketplace add ruvnet/ruflo
/plugin install ruflo-swarm@ruflo         # multi-agent swarm
/plugin install ruflo-rag-memory@ruflo    # persistent RAG memory
/plugin install ruflo-cost-tracker@ruflo  # track token spend
/plugin install ruflo-observability@ruflo # tracing/logging
/plugin install ruflo-aidefence@ruflo     # security guardrails
/plugin install ruflo-autopilot@ruflo     # autonomous execution
```

---

### AGENTS & SKILLS

#### 207 Agency Agents (`~/.claude/agents/`)
**What:** Specialized personas Claude can adopt. Installed by agency-agents.

```bash
# Inside a claude session, invoke by name:
# "Act as the Security Engineer agent and review this code"
# "Switch to Technical Writer mode and document this API"

# List available agents
ls ~/.claude/agents/
```

Examples: academic-historian, accounts-payable-agent, agents-orchestrator, architecture, security-engineer, technical-writer, workflow-architect.

#### 1,443 Skills (`~/.claude/skills/`)
**What:** Pre-built Claude workflows for specific tasks. Installed by antigravity-awesome-skills.

```bash
# Inside a claude session:
/skills         # list available skills
@skill-name     # invoke a skill

# Notable skill bundles installed:
# Security, DevOps, observability, accessibility, ad-creative,
# agent-evaluation, architecture, and 1,400+ more
```

#### Design Skills
- **impeccable** — typography, layout, and anti-pattern enforcement. Run `/teach-impeccable` once per project.
- **emilkowalski/skill** — motion and animation guidance.

---

### APP BUILDING

---

#### PocketBase (`pocketbase`)
**What:** Single-binary backend. Real-time database, auth, file storage, admin UI — one executable, no Docker needed.

```bash
# Start the server in your project
pocketbase serve

# Access admin UI
open http://localhost:8090/_/

# Start with custom port
pocketbase serve --http=0.0.0.0:9090

# Create collections, auth, APIs all via the admin UI
# or via the REST API at http://localhost:8090/api/
```

---

#### Caddy (`caddy`)
**What:** Modern web server with automatic HTTPS. Use as a local reverse proxy or for serving static sites.

```bash
# Serve current directory
caddy file-server --browse

# Reverse proxy to a local dev server
caddy reverse-proxy --to localhost:3000

# Use a Caddyfile for full config
caddy run --config Caddyfile

# Example Caddyfile (local HTTPS for app at :3000):
# localhost {
#   reverse_proxy localhost:3000
# }
```

---

#### `newproject` command
**What:** One command to scaffold a new project with git, CLAUDE.md, spec-kit, autoskills, and Infisical.

```bash
newproject my-app-name
cd my-app-name
claude
```

Sets up: `git init`, `.claude/CLAUDE.md`, `infisical init`, auto-detected skills via autoskills.

---

#### spec-kit (`specify`)
**What:** Spec-driven development workflow. Write a spec → Claude generates clarifications → implementation plan → tasks → code.

```bash
# Initialize spec-kit in a project
specify init . --integration claude-code

# Inside a claude session, use the workflow:
/speckit.specify   # describe what you're building
/speckit.plan      # generate implementation plan
/speckit.tasks     # break into tasks
# Then let claude implement each task
```

---

#### autoskills
**What:** Auto-detects your project type and installs matching skills from the skill registry.

```bash
# Run in any project directory
npx autoskills

# Or globally installed:
autoskills
```

---

## HOW TO USE THE TOOLS TOGETHER — WORKFLOWS

---

### Workflow 1: Starting a New Project
```bash
# 1. Scaffold
newproject my-app
cd my-app

# 2. Set up secrets (instead of .env files)
infisical init
infisical secrets set DATABASE_URL=postgres://...

# 3. Open Claude with full context
claude
# Claude reads .claude/CLAUDE.md + has vault MCP access

# 4. Describe what you're building
# Inside claude session:
/speckit.specify   # write the spec
/speckit.plan      # generate plan
/speckit.tasks     # create task list
```

---

### Workflow 2: Deep Research → Vault → Code
```bash
# 1. Convert source material to markdown
markitdown research-paper.pdf > ~/vault/raw/paper.md

# 2. Let Claude process it into a wiki note
claude "Read ~/vault/raw/paper.md and create a structured wiki note \
  at ~/vault/wiki/paper-summary.md using the research template"

# 3. Search vault later
rg "neural network" ~/vault/

# 4. Use vault knowledge in a project
claude "Read ~/vault/wiki/paper-summary.md and implement the algorithm described"
```

---

### Workflow 3: Security-First Code Review
```bash
# Before committing — gitleaks runs automatically, but also:
trivy fs .                          # dependency vulnerabilities
semgrep --config=p/security .      # code anti-patterns

# In Claude:
claude "Review this code for security issues before I commit"

# Commit — gitleaks pre-commit hook fires automatically
git add .
git commit -m "feat: add user auth"   # gitleaks scans staged files
```

---

### Workflow 4: Using Local AI When Quota Is Low
```bash
# Check Claude quota
claude /status

# If quota is low, switch to free local tools:
aider                    # uses qwen3:8b by default
ollama run qwen3:8b      # direct REPL

# For a quick one-shot:
echo "explain this function" | ollama run llama3.2:3b
```

---

### Workflow 5: Running Multiple Terminals (zellij)
```bash
zellij    # open multiplexer

# Layout for a typical dev session:
# Pane 1: claude (AI coding)
# Pane 2: dev server (bun run dev / python app.py)
# Pane 3: git log / lazygit
# Pane 4: logs or test runner

# Inside zellij: Ctrl+p → n = new pane
#                Ctrl+p → arrows = navigate panes
```

---

### Workflow 6: Data Exploration
```bash
# Query any CSV/JSON directly — no database setup
duckdb -c "SELECT * FROM 'users.csv' WHERE country='US' LIMIT 20"
duckdb -c "SELECT count(*), category FROM 'orders.csv' GROUP BY category"

# Convert Excel to markdown for Claude
markitdown report.xlsx > ~/vault/raw/report.md
claude "Analyze ~/vault/raw/report.md and summarize the key trends"
```

---

### Workflow 7: Git + Lazygit + Gitleaks
```bash
lazygit    # visual git UI

# Stage specific hunks (not whole files): press e on a file
# Commit: press c — gitleaks pre-commit hook fires automatically
# Push: press P
# Resolve conflicts: press M
```

---

## RUNTIME SUMMARY

| Tool | Auth | Cost | Best for |
|------|------|------|---------|
| Claude Code | Claude Pro OAuth | Subscription | Primary coding agent |
| Codex CLI | ChatGPT Plus OAuth | Subscription | Parallel GPT tasks |
| Aider | None (Ollama) | Free | Iteration, offline, low quota |
| Ollama | None | Free | Local inference, always available |

---

## DAILY COMMANDS CHEATSHEET

```bash
# Start work
source ~/.zshrc           # if shell isn't fresh
claude                    # start coding session
lazygit                   # check git status visually

# Search
rg "term" .              # search code
rg "term" ~/vault/       # search knowledge base
Ctrl+R                   # fuzzy search shell history (fzf)
Ctrl+T                   # fuzzy find file (fzf)

# Data
duckdb -c "SELECT * FROM 'file.csv' LIMIT 10"
markitdown doc.pdf > ~/vault/raw/doc.md

# Security (before shipping)
gitleaks protect --staged
trivy fs .
semgrep --config=p/security .

# Runtime management
mise list                 # what's installed
mise use node@22         # switch node version

# Packages
uv pip install X         # Python (fast)
bun add X                # JavaScript (fast)

# Processes
brew services list        # check running services
brew services start ollama
```

---

## FILE LOCATIONS

| File | Purpose |
|------|---------|
| `~/.zshrc` | Shell config — PATH, aliases, tool activation |
| `~/.claude/CLAUDE.md` | Global Claude context — read every session |
| `~/.claude/skills/` | 1,443 installed skills |
| `~/.claude/agents/` | 207 installed agent personas |
| `~/.claude.json` | Claude Code settings + MCP server registry |
| `~/.aider.conf.yml` | Aider defaults (currently: ollama/qwen3:8b) |
| `~/.git-hooks/pre-commit` | Global gitleaks hook (runs on every commit) |
| `~/.npm-global/bin/` | Global npm binaries (codex, autoskills, infisical) |
| `~/.local/bin/` | User binaries (claude, aider, newproject) |
| `~/vault/` | Personal knowledge base |
| `~/CLEANUP_LOG.md` | Log of cleanup changes |
| `~/Documents/Master AI Projects/SETUP_LOG.md` | Log of setup changes |
