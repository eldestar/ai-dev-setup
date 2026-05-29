# setup-windows.ps1
# AI Dev Environment Bootstrap — Windows
# Supports: WSL2 (recommended) and Native PowerShell
#
# Usage:
#   Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
#   .\setup-windows.ps1
#
# No admin required for Scoop/native path.
# WSL2 install requires a one-time restart.

#Requires -Version 5.1
Set-StrictMode -Version Latest
$ErrorActionPreference = "Continue"

# ─── Helpers ──────────────────────────────────────────────────────────────────

function Write-Header($text) { Write-Host "`n=== $text ===" -ForegroundColor Cyan }
function Write-OK($text)     { Write-Host "  [OK] $text" -ForegroundColor Green }
function Write-Info($text)   { Write-Host "  ... $text" -ForegroundColor Gray }
function Write-Warn($text)   { Write-Host "  [!] $text" -ForegroundColor Yellow }
function Write-Step($text)   { Write-Host "  --> $text" }

function Test-Command($name) {
    return $null -ne (Get-Command $name -ErrorAction SilentlyContinue)
}

function Add-ProfileLine($line) {
    if (-not (Test-Path $PROFILE)) { New-Item -ItemType File -Path $PROFILE -Force | Out-Null }
    if (-not (Select-String -Path $PROFILE -Pattern ([regex]::Escape($line)) -Quiet -ErrorAction SilentlyContinue)) {
        Add-Content -Path $PROFILE -Value $line
    }
}

# ─── System Detection ─────────────────────────────────────────────────────────

Write-Header "System Detection"

$RAM_GB   = [math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB)
$CPU      = (Get-CimInstance Win32_Processor | Select-Object -First 1).Name.Trim()
$WinVer   = (Get-CimInstance Win32_OperatingSystem).Caption
$gpuInfo  = Get-CimInstance Win32_VideoController | Select-Object -First 1
$GPU      = $gpuInfo.Name
$VRAM_GB  = 0
$GPU_TYPE = "cpu_only"

if ($gpuInfo.AdapterRAM -and $gpuInfo.AdapterRAM -gt 0) {
    $VRAM_GB = [math]::Round($gpuInfo.AdapterRAM / 1GB)
}
if ($GPU -match "NVIDIA")     { $GPU_TYPE = "nvidia" }
elseif ($GPU -match "AMD|Radeon") { $GPU_TYPE = "amd" }

Write-Host "  OS:   $WinVer"
Write-Host "  CPU:  $CPU"
Write-Host "  RAM:  ${RAM_GB}GB"
Write-Host "  GPU:  $GPU (${VRAM_GB}GB VRAM)"

# Ollama model recommendation
if ($GPU_TYPE -eq "nvidia") {
    if     ($VRAM_GB -ge 24) { $PRIMARY = "qwen3:32b";   $FAST = "qwen3:14b"   }
    elseif ($VRAM_GB -ge 16) { $PRIMARY = "qwen3:14b";   $FAST = "qwen3:8b"    }
    elseif ($VRAM_GB -ge 8)  { $PRIMARY = "qwen3:8b";    $FAST = "llama3.2:3b" }
    else                     { $PRIMARY = "llama3.2:3b"; $FAST = "phi4-mini"   }
} else {
    if     ($RAM_GB -ge 64)  { $PRIMARY = "qwen3:32b";   $FAST = "qwen3:14b"   }
    elseif ($RAM_GB -ge 32)  { $PRIMARY = "qwen3:14b";   $FAST = "qwen3:8b"    }
    elseif ($RAM_GB -ge 16)  { $PRIMARY = "qwen3:8b";    $FAST = "llama3.2:3b" }
    else                     { $PRIMARY = "llama3.2:3b"; $FAST = "qwen3:1.7b"  }
}

Write-Host ""
Write-Host "  Recommended Ollama models:"
Write-Host "    Primary : $PRIMARY"
Write-Host "    Fast    : $FAST"

# ─── Path Selection ───────────────────────────────────────────────────────────

Write-Header "Setup Path"

$wslInstalled = $false
try {
    $wslOut = wsl --status 2>&1 | Out-String
    if ($wslOut -match "Default Distribution") { $wslInstalled = $true }
} catch {}

Write-Host ""
Write-Host "  [1] WSL2 (recommended) — full Linux environment, identical to Mac"
Write-Host "  [2] Native PowerShell  — works but some tools have reduced functionality"
Write-Host ""

if ($wslInstalled) {
    Write-OK "WSL2 already installed"
    $choice = Read-Host "  Use WSL2? [Y/n]"
    $useWSL2 = ($choice -eq "" -or $choice -match "^[Yy]")
} else {
    Write-Warn "WSL2 not detected"
    $choice = Read-Host "  Choose path [1=WSL2  2=Native]"
    $useWSL2 = ($choice -ne "2")
}

# ─── WSL2 PATH ────────────────────────────────────────────────────────────────

if ($useWSL2) {
    Write-Header "WSL2 Setup"

    if (-not $wslInstalled) {
        Write-Info "Installing WSL2 + Ubuntu (requires restart)..."
        wsl --install
        Write-Host ""
        Write-Warn "RESTART REQUIRED. After restart, complete these steps:"
        Write-Host ""
        Write-Host "  1. Open Ubuntu from Start Menu and create your Linux user"
        Write-Host "  2. Inside Ubuntu, run:"
        Write-Host ""
        Write-Host "     curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -"
        Write-Host "     sudo apt-get install -y nodejs git"
        Write-Host "     npm install -g @anthropic-ai/claude-code"
        Write-Host "     claude login"
        Write-Host "     git clone https://github.com/eldestar/ai-dev-setup.git ~/ai-dev-setup"
        Write-Host "     cd ~/ai-dev-setup"
        Write-Host '     claude "Read SETUP.md, run system detection first and report findings,'
        Write-Host '     then execute all phases in order. Ask me before each phase starts.'
        Write-Host '     Collect all manual steps and present them together at the end.'
        Write-Host '     Log everything to SETUP_LOG.md."'
        Write-Host ""
        $restart = Read-Host "  Restart now? [y/N]"
        if ($restart -match "^[Yy]") { Restart-Computer -Force }
        exit 0
    }

    # WSL2 already installed — set up repo and Claude Code inside it
    Write-Info "Checking for ai-dev-setup inside WSL2..."
    $repoExists = wsl -- bash -c "[ -d ~/ai-dev-setup ] && echo yes || echo no" 2>&1
    if ($repoExists -match "no") {
        Write-Info "Cloning repo into WSL2..."
        wsl -- bash -c "git clone https://github.com/eldestar/ai-dev-setup.git ~/ai-dev-setup 2>&1"
    } else {
        Write-Info "Pulling latest..."
        wsl -- bash -c "cd ~/ai-dev-setup && git pull 2>&1"
    }

    $claudeExists = wsl -- bash -c "command -v claude >/dev/null 2>&1 && echo yes || echo no" 2>&1
    if ($claudeExists -match "no") {
        Write-Info "Installing Node + Claude Code inside WSL2..."
        wsl -- bash -c "curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash - && sudo apt-get install -y nodejs && npm install -g @anthropic-ai/claude-code"
    } else {
        Write-OK "Claude Code already present in WSL2"
    }

    Write-Host ""
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    Write-Host "  NEXT STEPS — run inside WSL2 Ubuntu terminal"
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    Write-Host ""
    Write-Host "  1. Open Ubuntu (Start Menu or: wsl)"
    Write-Host "  2. claude login"
    Write-Host "  3. cd ~/ai-dev-setup"
    Write-Host '  4. claude "Read SETUP.md, run system detection first and report'
    Write-Host '     findings, then execute all phases in order. Ask me before each'
    Write-Host '     phase starts. Log everything to SETUP_LOG.md."'
    Write-Host ""
    exit 0
}

# ─── NATIVE WINDOWS PATH ──────────────────────────────────────────────────────

Write-Header "Native Windows — Full Setup"
Write-Warn "Proceeding with native PowerShell path."

# ── Scoop ─────────────────────────────────────────────────────────────────────

Write-Header "Scoop (package manager)"

if (-not (Test-Command "scoop")) {
    Write-Info "Installing Scoop..."
    Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
    Invoke-RestMethod get.scoop.sh | Invoke-Expression
    # Reload PATH
    $env:PATH = [System.Environment]::GetEnvironmentVariable("PATH", "User") + ";" + $env:PATH
} else {
    Write-OK "Scoop already installed"
}

scoop bucket add extras  2>&1 | Out-Null
scoop bucket add versions 2>&1 | Out-Null
Write-OK "extras + versions buckets added"

# ── Core CLI Tools ────────────────────────────────────────────────────────────

Write-Header "Core CLI Tools"

$scoopTools = [ordered]@{
    "git"      = "git"
    "starship" = "starship"
    "fzf"      = "fzf"
    "bat"      = "bat"
    "rg"       = "ripgrep"
    "lazygit"  = "lazygit"
    "duckdb"   = "duckdb"
    "just"     = "just"
    "caddy"    = "caddy"
    "zellij"   = "zellij"
}

foreach ($cmd in $scoopTools.Keys) {
    if (-not (Test-Command $cmd)) {
        Write-Info "Installing $($scoopTools[$cmd])..."
        scoop install $scoopTools[$cmd] 2>&1 | Out-Null
        if (Test-Command $cmd) { Write-OK $cmd } else { Write-Warn "$cmd install may have failed — check manually" }
    } else {
        Write-OK "$cmd (already installed)"
    }
}

# mise
if (-not (Test-Command "mise")) {
    Write-Info "Installing mise..."
    scoop install mise 2>&1 | Out-Null
}
Write-OK "mise: $(mise --version 2>&1)"

# ── Runtimes via mise ─────────────────────────────────────────────────────────

Write-Header "Runtimes (Node LTS, Python 3.12, Bun)"

mise install node@lts    2>&1 | Select-String "(Installed|already installed)" | ForEach-Object { Write-OK $_.Line.Trim() }
mise install python@3.12 2>&1 | Select-String "(Installed|already installed)" | ForEach-Object { Write-OK $_.Line.Trim() }
mise install bun@latest  2>&1 | Select-String "(Installed|already installed)" | ForEach-Object { Write-OK $_.Line.Trim() }

Write-OK "mise list:"
mise list

# ── Python Package Tools ──────────────────────────────────────────────────────

Write-Header "Python Package Tools (uv, pipx)"

$pythonBin = (mise which python 2>&1).Trim()
if (-not (Test-Command "uv")) {
    & $pythonBin -m pip install uv --quiet
    Write-OK "uv installed"
} else {
    Write-OK "uv: $(uv --version)"
}

if (-not (Test-Command "pipx")) {
    & $pythonBin -m pip install pipx --quiet
    pipx ensurepath 2>&1 | Out-Null
    Write-OK "pipx installed"
} else {
    Write-OK "pipx: $(pipx --version)"
}

# ── npm (scoped prefix) ───────────────────────────────────────────────────────

Write-Header "npm global prefix"

$npmGlobal = "$HOME\.npm-global"
New-Item -ItemType Directory -Path $npmGlobal -Force | Out-Null
npm config set prefix $npmGlobal 2>&1 | Out-Null
$env:PATH = "$npmGlobal\bin;$env:PATH"
Write-OK "npm prefix: $npmGlobal"

# ── Claude Code ───────────────────────────────────────────────────────────────

Write-Header "Claude Code"

if (-not (Test-Command "claude")) {
    Write-Info "Installing Claude Code..."
    npm install -g @anthropic-ai/claude-code 2>&1 | Select-Object -Last 3 | ForEach-Object { Write-Info $_ }
} else {
    Write-OK "claude: $(claude --version)"
}

# ── Codex CLI ─────────────────────────────────────────────────────────────────

Write-Header "Codex CLI"

if (-not (Test-Command "codex")) {
    Write-Info "Installing Codex CLI..."
    npm install -g @openai/codex 2>&1 | Select-Object -Last 2 | ForEach-Object { Write-Info $_ }
} else {
    Write-OK "codex already installed"
}

# ── Ollama ────────────────────────────────────────────────────────────────────

Write-Header "Ollama"

if (-not (Test-Command "ollama")) {
    Write-Info "Installing Ollama via Scoop..."
    scoop install ollama 2>&1 | Out-Null
    if (-not (Test-Command "ollama")) {
        Write-Warn "Scoop install failed — download from https://ollama.com/download/windows"
    }
} else {
    Write-OK "ollama: $(ollama --version)"
}

if (Test-Command "ollama") {
    Start-Process -FilePath "ollama" -ArgumentList "serve" -WindowStyle Hidden -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 3
    Write-Info "Pulling primary model: $PRIMARY (may take several minutes)..."
    ollama pull $PRIMARY
    Write-Info "Pulling fast model: $FAST..."
    ollama pull $FAST
    ollama list
}

# ── Aider ─────────────────────────────────────────────────────────────────────

Write-Header "Aider"

if (-not (Test-Command "aider")) {
    Write-Info "Installing aider-chat via uv..."
    uv tool install aider-chat --python 3.12 2>&1 | Select-Object -Last 3 | ForEach-Object { Write-Info $_ }
} else {
    Write-OK "aider: $(aider --version)"
}

@"
# Aider config — local Ollama (free, no API key needed)
model: ollama/$PRIMARY
auto-commits: false
pretty: true
"@ | Out-File -FilePath "$HOME\.aider.conf.yml" -Encoding utf8
Write-OK "~/.aider.conf.yml written (model: ollama/$PRIMARY)"

# ── Security Tools ────────────────────────────────────────────────────────────

Write-Header "Security Tools"

if (-not (Test-Command "gitleaks")) {
    scoop install gitleaks 2>&1 | Out-Null
    if (Test-Command "gitleaks") { Write-OK "gitleaks: $(gitleaks version)" }
    else { Write-Warn "gitleaks install failed — try: scoop install gitleaks" }
} else {
    Write-OK "gitleaks: $(gitleaks version)"
}

if (-not (Test-Command "trivy")) {
    scoop install trivy 2>&1 | Out-Null
    if (Test-Command "trivy") { Write-OK "trivy installed" }
    else { Write-Warn "trivy install failed — try: scoop install trivy" }
} else {
    Write-OK "trivy installed"
}

if (-not (Test-Command "semgrep")) {
    uv tool install semgrep 2>&1 | Out-Null
    if (Test-Command "semgrep") { Write-OK "semgrep: $(semgrep --version)" }
    else { Write-Warn "semgrep install failed — try: uv tool install semgrep" }
} else {
    Write-OK "semgrep: $(semgrep --version)"
}

if (-not (Test-Command "infisical")) {
    scoop install infisical 2>&1 | Out-Null
    if (-not (Test-Command "infisical")) {
        npm install -g @infisical/cli 2>&1 | Out-Null
    }
    if (Test-Command "infisical") { Write-OK "infisical installed" }
    else { Write-Warn "infisical install failed — manual install: https://infisical.com/docs/cli" }
} else {
    Write-OK "infisical installed"
}

# ── markitdown ────────────────────────────────────────────────────────────────

Write-Header "markitdown"

if (-not (Test-Command "markitdown")) {
    uv tool install markitdown 2>&1 | Out-Null
    Write-OK "markitdown installed"
} else {
    Write-OK "markitdown already installed"
}

# ── Global gitleaks pre-commit hook ──────────────────────────────────────────

Write-Header "Global Git Hooks (gitleaks)"

$hooksDir = "$HOME\.git-hooks"
$hookFile = "$hooksDir\pre-commit"

if (-not (Test-Path $hookFile)) {
    New-Item -ItemType Directory -Path $hooksDir -Force | Out-Null
    git config --global core.hooksPath ($hooksDir -replace "\\", "/")
    # Git for Windows executes pre-commit as a shell script via sh.exe
    @"
#!/bin/sh
gitleaks protect --staged --no-banner
"@ | Out-File -FilePath $hookFile -Encoding ascii -NoNewline
    Write-OK "gitleaks pre-commit hook installed at $hooksDir"
} else {
    Write-OK "Pre-commit hook already installed"
}

# ── PowerShell Profile ────────────────────────────────────────────────────────

Write-Header "PowerShell Profile"

$profileDir = Split-Path $PROFILE
New-Item -ItemType Directory -Path $profileDir -Force | Out-Null

$profileLines = @(
    'if (Get-Command starship -ErrorAction SilentlyContinue) { Invoke-Expression (&starship init powershell) }',
    'if (Get-Command mise -ErrorAction SilentlyContinue) { Invoke-Expression (&mise activate powershell) }',
    'if (Get-Command bat -ErrorAction SilentlyContinue) { Set-Alias -Name cat -Value bat -Option AllScope -Force }',
    'if (Get-Command rg -ErrorAction SilentlyContinue)  { Set-Alias -Name grep -Value rg  -Option AllScope -Force }',
    '$env:PATH = "$HOME\.npm-global\bin;" + $env:PATH',
    '$env:PATH = "$HOME\.local\bin;" + $env:PATH'
)

foreach ($line in $profileLines) { Add-ProfileLine $line }
Write-OK "Profile updated: $PROFILE"

# ── Knowledge Base ────────────────────────────────────────────────────────────

Write-Header "Knowledge Base (~/vault)"

$vaultDirs = @("raw", "wiki", "playbooks", "templates", "agents", "daily", "projects")
foreach ($d in $vaultDirs) {
    New-Item -ItemType Directory -Path "$HOME\vault\$d" -Force | Out-Null
}
Write-OK "Vault structure created at $HOME\vault"

# ── MCP Servers ───────────────────────────────────────────────────────────────

Write-Header "MCP Servers"

if (Test-Command "claude") {
    $mcpList = claude mcp list 2>&1 | Out-String
    if ($mcpList -notmatch "vault") {
        # Windows path needs forward slashes for MCP
        $vaultPath = "$HOME\vault" -replace "\\", "/"
        claude mcp add vault --scope user -- npx -y @modelcontextprotocol/server-filesystem $vaultPath
        Write-OK "vault MCP registered"
    } else {
        Write-OK "vault MCP already registered"
    }
    if ($mcpList -notmatch "ruflo") {
        claude mcp add ruflo -- npx ruflo@latest mcp start
        Write-OK "ruflo MCP registered"
    } else {
        Write-OK "ruflo MCP already registered"
    }
} else {
    Write-Warn "claude not found — MCP registration skipped (run after claude login)"
}

# ── Skills + Agents ───────────────────────────────────────────────────────────

Write-Header "Skills (antigravity-awesome-skills)"

$skillsDir = "$HOME\.claude\skills"
New-Item -ItemType Directory -Path $skillsDir -Force | Out-Null

$skillCount = (Get-ChildItem $skillsDir -ErrorAction SilentlyContinue | Measure-Object).Count
if ($skillCount -lt 100) {
    Write-Info "Installing skills..."
    npx antigravity-awesome-skills --claude 2>&1 | Select-Object -Last 5 | ForEach-Object { Write-Info $_ }
} else {
    Write-OK "Skills already installed ($skillCount dirs)"
}

Write-Header "Agents (agency-agents)"

$agentsDir = "$HOME\.claude\agents"
New-Item -ItemType Directory -Path $agentsDir -Force | Out-Null

$agentCount = (Get-ChildItem $agentsDir -ErrorAction SilentlyContinue | Measure-Object).Count
if ($agentCount -lt 10) {
    Write-Info "Cloning agency-agents..."
    $tmpAgents = "$env:TEMP\agency-agents"
    git clone https://github.com/msitarzewski/agency-agents $tmpAgents 2>&1 | Out-Null
    if (Test-Path "$tmpAgents\agents") {
        Copy-Item -Path "$tmpAgents\agents\*" -Destination $agentsDir -Recurse -Force 2>&1 | Out-Null
        Write-OK "Agents installed to $agentsDir"
    } else {
        Write-Warn "agency-agents clone failed — install manually from github.com/msitarzewski/agency-agents"
    }
} else {
    Write-OK "Agents already installed ($agentCount agents)"
}

# ── Global CLAUDE.md ──────────────────────────────────────────────────────────

Write-Header "Global CLAUDE.md"

$claudeDir  = "$HOME\.claude"
$claudeMdPath = "$claudeDir\CLAUDE.md"
New-Item -ItemType Directory -Path $claudeDir -Force | Out-Null

if (-not (Test-Path $claudeMdPath)) {
    $claudeMd = @"
# Global Claude Code Context

## Who I Am
Name: [Fill in your name]
Role: Developer / Researcher / Builder
Primary use cases:
1. Building apps and pet projects
2. Building and maintaining knowledge bases
3. Deep technical research

## My Machine
- Windows — $CPU
- RAM: ${RAM_GB}GB
- GPU: $GPU (${VRAM_GB}GB VRAM)
- OS: $WinVer
- Shell: PowerShell with starship prompt

## My Tech Stack
- Runtimes: Node LTS, Python 3.12, Bun (via mise)
- Package managers: uv (Python), bun/npm (JS)
- AI tools: Claude Code, Codex CLI, Aider (local Ollama), Ollama
- Agent orchestration: Ruflo
- Knowledge base: Obsidian vault at ~/vault/
- Secrets: Infisical
- Version control: git with gitleaks pre-commit hook

## Available MCP Servers
- vault: ~/vault/ — personal knowledge base
- ruflo: multi-agent orchestration layer

## Installed Skills
- antigravity-awesome-skills: security, DevOps, observability bundles
- agency-agents: specialized agent personas at ~/.claude/agents/

## How I Work Best
- Show me what you're going to do before doing it
- Ask me before modifying existing files
- Batch related tasks into one message rather than sequential prompts
- Prefer uv for Python deps, bun for JS deps

## IRON RULES
- Never commit secrets, API keys, or credentials
- Never run destructive operations without confirmation
- Always run 'gitleaks protect --staged' check before committing

## Model Selection Guide
- Complex reasoning, architecture: Claude Code (Claude Pro subscription)
- Surgical tasks, auditing: Codex CLI (ChatGPT Plus subscription)
- Free/local quick tasks: aider (uses ollama/$PRIMARY)
- Both subscription quotas shared with web usage

## Auth Notes
- Claude Code: authenticated via Claude Pro OAuth (not API key)
- Codex CLI: authenticated via ChatGPT Plus OAuth (not API key)
- Aider: local Ollama by default (free)

## Ruflo Integration
When working on multi-file tasks, use ToolSearch to find and invoke ruflo MCP tools.
Key tools: memory_store, memory_search, hooks_route, swarm_init, agent_spawn.
"@
    $claudeMd | Out-File -FilePath $claudeMdPath -Encoding utf8
    Write-OK "~/.claude/CLAUDE.md written — edit to fill in Name and Role"
} else {
    Write-OK "~/.claude/CLAUDE.md already exists (skipping)"
}

# ─── Validation ───────────────────────────────────────────────────────────────

Write-Header "Validation"

$checkTools = @("scoop", "git", "node", "bun", "rg", "fzf", "bat", "lazygit",
                "starship", "mise", "duckdb", "gitleaks", "trivy", "infisical",
                "claude", "aider", "ollama", "uv", "markitdown")

$pass = 0; $fail = 0
foreach ($t in $checkTools) {
    if (Test-Command $t) { Write-OK $t; $pass++ }
    else                 { Write-Warn "$t — NOT FOUND"; $fail++ }
}

Write-Host ""
if ($fail -eq 0) {
    Write-OK "All tools present!"
} else {
    Write-Warn "$fail tools missing — check warnings above"
}

# ─── Manual Steps ─────────────────────────────────────────────────────────────

Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host "  MANUAL STEPS — complete in order after bootstrap finishes"          -ForegroundColor Cyan
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host ""
Write-Host "  1. Open a NEW PowerShell window (activates profile changes)"
Write-Host ""
Write-Host "  2. claude login"
Write-Host "     -> Browser opens -> sign in with Claude Pro account"
Write-Host ""
Write-Host "  3. codex  (first run)"
Write-Host "     -> Select 'Sign in with ChatGPT' -> browser auth"
Write-Host ""
Write-Host "  4. infisical login"
Write-Host "     -> Then: infisical init  (once per project)"
Write-Host ""
Write-Host "  5. Open terminal -> run: claude"
Write-Host "     Then paste these slash commands one at a time:"
Write-Host "       /plugin marketplace add openai/codex-plugin-cc"
Write-Host "       /plugin install codex@openai-codex"
Write-Host "       /reload-plugins"
Write-Host "       /codex:setup"
Write-Host ""
Write-Host "  6. Same claude session — Ruflo plugins:"
Write-Host "       /plugin marketplace add ruvnet/ruflo"
Write-Host "       /plugin install ruflo-core@ruflo"
Write-Host "       /plugin install ruflo-swarm@ruflo"
Write-Host "       /plugin install ruflo-rag-memory@ruflo"
Write-Host "       /plugin install ruflo-cost-tracker@ruflo"
Write-Host "       /plugin install ruflo-observability@ruflo"
Write-Host "       /plugin install ruflo-aidefence@ruflo"
Write-Host "       /plugin install ruflo-autopilot@ruflo"
Write-Host "       /plugin install ruflo-testgen@ruflo"
Write-Host "       /plugin install ruflo-adr@ruflo"
Write-Host "       /plugin install ruflo-intelligence@ruflo"
Write-Host ""
Write-Host "  7. Same claude session — Superpowers:"
Write-Host "       /plugin marketplace add obra/superpowers-marketplace"
Write-Host "       /plugin install superpowers@superpowers-marketplace"
Write-Host ""
Write-Host "  8. Obsidian: download from obsidian.md"
Write-Host "     -> Open ~/vault as vault"
Write-Host "     -> Install plugins: Dataview, Templater, Git, QuickAdd"
Write-Host ""
Write-Host "  9. Edit ~/.claude/CLAUDE.md — fill in your Name and Role"
Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Bootstrap complete. $pass tools installed, $fail missing." -ForegroundColor Green
Write-Host "  Follow the manual steps above to finish the setup."
Write-Host ""
