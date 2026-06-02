# runners/install.ps1 — native Windows installer (runs from the cloned repo).
# Invoked by the thin bootstrap (setup-windows.ps1). Reads single-source config:
#   config/models.csv · config/tools.csv · templates/CLAUDE.md.tmpl
# Edit those, not inline copies.

#Requires -Version 5.1
param([switch]$Check)
Set-StrictMode -Version Latest
$ErrorActionPreference = "Continue"

. "$PSScriptRoot\lib\common.ps1"
$RepoRoot = Get-RepoRoot

# Preflight-only: report status and exit without changing anything.
if ($Check) { & (Join-Path $PSScriptRoot '..\scripts\doctor.ps1'); return }

# File logging: tee everything to a timestamped log.
$logDir  = Join-Path $HOME ".ai-dev-setup\logs"
New-Item -ItemType Directory -Path $logDir -Force | Out-Null
$logFile = Join-Path $logDir ("install-" + (Get-Date -Format "yyyyMMdd-HHmmss") + ".log")
try { Start-Transcript -Path $logFile -Append | Out-Null } catch {}

# ── System Detection ──────────────────────────────────────────────────────────
Write-Header "System Detection"

$RAM_GB   = [math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB)
$CPU      = (Get-CimInstance Win32_Processor | Select-Object -First 1).Name.Trim()
$WinVer   = (Get-CimInstance Win32_OperatingSystem).Caption
$gpuInfo  = Get-CimInstance Win32_VideoController | Select-Object -First 1
$GPU      = $gpuInfo.Name
$VRAM_GB  = 0
$GPU_TYPE = "cpu_only"
if ($gpuInfo.AdapterRAM -and $gpuInfo.AdapterRAM -gt 0) { $VRAM_GB = [math]::Round($gpuInfo.AdapterRAM / 1GB) }
if ($GPU -match "NVIDIA")          { $GPU_TYPE = "nvidia" }
elseif ($GPU -match "AMD|Radeon")  { $GPU_TYPE = "amd" }

Write-Host "  OS:   $WinVer"
Write-Host "  CPU:  $CPU"
Write-Host "  RAM:  ${RAM_GB}GB"
Write-Host "  GPU:  $GPU (${VRAM_GB}GB VRAM)"

# Model selection comes from config/models.csv (single source of truth)
$capacity = if ($GPU_TYPE -eq "nvidia") { $VRAM_GB } else { $RAM_GB }
$model    = Get-ModelSelection -GpuType $GPU_TYPE -CapacityGb $capacity
$PRIMARY  = $model.Primary
$FAST     = $model.Fast
Write-Host "  Recommended Ollama models: primary=$PRIMARY  fast=$FAST"

# ── Scoop ─────────────────────────────────────────────────────────────────────
Write-Header "Scoop (package manager)"
if (-not (Test-Command "scoop")) {
    Write-Info "Installing Scoop..."
    Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
    Invoke-RestMethod get.scoop.sh | Invoke-Expression
    $env:PATH = [System.Environment]::GetEnvironmentVariable("PATH", "User") + ";" + $env:PATH
} else {
    Write-OK "Scoop already installed"
}
scoop bucket add extras   2>&1 | Out-Null
scoop bucket add versions 2>&1 | Out-Null
Write-OK "extras + versions buckets added"

# ── Core CLI Tools (single source: config/tools.csv) ──────────────────────────
Write-Header "Core CLI Tools"
foreach ($tool in Get-CoreTools) {
    if (-not (Test-Command $tool.check)) {
        Write-Info "Installing $($tool.scoop)..."
        scoop install $tool.scoop 2>&1 | Out-Null
        if (Test-Command $tool.check) { Write-OK $tool.id } else { Write-Warn "$($tool.id) install may have failed — check manually" }
    } else {
        Write-OK "$($tool.id) (already installed)"
    }
}
if (Test-Command "mise") { Write-OK "mise: $(mise --version 2>&1)" }

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
    if (-not (Test-Command "ollama")) { Write-Warn "Scoop install failed — download from https://ollama.com/download/windows" }
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
    if (Test-Command "gitleaks") { Write-OK "gitleaks: $(gitleaks version)" } else { Write-Warn "gitleaks install failed — try: scoop install gitleaks" }
} else { Write-OK "gitleaks: $(gitleaks version)" }

if (-not (Test-Command "trivy")) {
    scoop install trivy 2>&1 | Out-Null
    if (Test-Command "trivy") { Write-OK "trivy installed" } else { Write-Warn "trivy install failed — try: scoop install trivy" }
} else { Write-OK "trivy installed" }

if (-not (Test-Command "semgrep")) {
    uv tool install semgrep 2>&1 | Out-Null
    if (Test-Command "semgrep") { Write-OK "semgrep: $(semgrep --version)" } else { Write-Warn "semgrep install failed — try: uv tool install semgrep" }
} else { Write-OK "semgrep: $(semgrep --version)" }

if (-not (Test-Command "infisical")) {
    scoop install infisical 2>&1 | Out-Null
    if (-not (Test-Command "infisical")) { npm install -g @infisical/cli 2>&1 | Out-Null }
    if (Test-Command "infisical") { Write-OK "infisical installed" } else { Write-Warn "infisical install failed — manual: https://infisical.com/docs/cli" }
} else { Write-OK "infisical installed" }

# ── markitdown ────────────────────────────────────────────────────────────────
Write-Header "markitdown"
if (-not (Test-Command "markitdown")) {
    uv tool install markitdown 2>&1 | Out-Null
    Write-OK "markitdown installed"
} else {
    Write-OK "markitdown already installed"
}

# ── Global gitleaks pre-commit hook ───────────────────────────────────────────
Write-Header "Global Git Hooks (gitleaks)"
$hooksDir = "$HOME\.git-hooks"
$hookFile = "$hooksDir\pre-commit"
if (-not (Test-Path $hookFile)) {
    New-Item -ItemType Directory -Path $hooksDir -Force | Out-Null
    git config --global core.hooksPath ($hooksDir -replace "\\", "/")
    # Git for Windows executes pre-commit as a shell script via sh.exe
    "#!/bin/sh`ngitleaks protect --staged --no-banner" | Out-File -FilePath $hookFile -Encoding ascii -NoNewline
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
    '# Interactive convenience aliases (no -Option AllScope/-Force so they do not override commands inside scripts)',
    'if (Get-Command bat -ErrorAction SilentlyContinue) { Set-Alias -Name cat -Value bat }',
    'if (Get-Command rg  -ErrorAction SilentlyContinue) { Set-Alias -Name grep -Value rg }',
    '$env:PATH = "$HOME\.npm-global\bin;" + $env:PATH',
    '$env:PATH = "$HOME\.local\bin;" + $env:PATH'
)
if (-not (Test-Path $PROFILE)) { New-Item -ItemType File -Path $PROFILE -Force | Out-Null }
foreach ($line in $profileLines) {
    if (-not (Select-String -Path $PROFILE -Pattern ([regex]::Escape($line)) -Quiet -ErrorAction SilentlyContinue)) {
        Add-Content -Path $PROFILE -Value $line
    }
}
Write-OK "Profile updated: $PROFILE"

# ── Knowledge Base ────────────────────────────────────────────────────────────
Write-Header "Knowledge Base (~/vault)"
foreach ($d in @("raw", "wiki", "playbooks", "templates", "agents", "daily", "projects")) {
    New-Item -ItemType Directory -Path "$HOME\vault\$d" -Force | Out-Null
}
Write-OK "Vault structure created at $HOME\vault"

# ── MCP Servers ───────────────────────────────────────────────────────────────
Write-Header "MCP Servers"
if (Test-Command "claude") {
    $mcpList = claude mcp list 2>&1 | Out-String
    if ($mcpList -notmatch "vault") {
        $vaultPath = "$HOME\vault" -replace "\\", "/"
        claude mcp add vault --scope user -- npx -y @modelcontextprotocol/server-filesystem $vaultPath
        Write-OK "vault MCP registered"
    } else { Write-OK "vault MCP already registered" }
    if ($mcpList -notmatch "ruflo") {
        claude mcp add ruflo -- npx ruflo@latest mcp start
        Write-OK "ruflo MCP registered"
    } else { Write-OK "ruflo MCP already registered" }
} else {
    Write-Warn "claude not found — MCP registration skipped (run after claude login)"
}

# ── Skills + Agents (pinned allowlist) ────────────────────────────────────────
Write-Header "Skills + Agents (pinned allowlist)"
# Installs ONLY the pinned, SHA-256-verified allowlist in skills-lock.json (no bulk install).
& (Join-Path $RepoRoot 'scripts\install-skills.ps1') -TargetRoot "$HOME\.claude"

# ── Global CLAUDE.md (rendered from templates/CLAUDE.md.tmpl) ──────────────────
Write-Header "Global CLAUDE.md (rendered from template)"
$claudeDir    = "$HOME\.claude"
$claudeMdPath = "$claudeDir\CLAUDE.md"
New-Item -ItemType Directory -Path $claudeDir -Force | Out-Null
if (-not (Test-Path $claudeMdPath)) {
    $tokens = @{
        '{{NAME}}'           = '[Fill in your name]'
        '{{ROLE}}'           = 'Developer / Researcher / Builder'
        '{{USE_CASE_1}}'     = 'Building AI-powered apps and tools'
        '{{USE_CASE_2}}'     = 'Building and maintaining knowledge bases'
        '{{USE_CASE_3}}'     = 'Deep technical research'
        '{{MACHINE_CPU}}'    = "Windows - $CPU"
        '{{MACHINE_RAM_GB}}' = "$RAM_GB"
        '{{MACHINE_GPU}}'    = "$GPU (${VRAM_GB}GB VRAM)"
        '{{MACHINE_OS}}'     = "$WinVer"
        '{{MACHINE_SHELL}}'  = 'PowerShell'
        '{{PRIMARY_MODEL}}'  = "$PRIMARY"
        '{{FAST_MODEL}}'     = "$FAST"
    }
    $tmplPath = Join-Path $RepoRoot 'templates\CLAUDE.md.tmpl'
    (Expand-Template -TemplatePath $tmplPath -Tokens $tokens) | Out-File -FilePath $claudeMdPath -Encoding utf8
    Write-OK "~/.claude/CLAUDE.md rendered from templates/CLAUDE.md.tmpl — edit Name and Role"
} else {
    Write-OK "~/.claude/CLAUDE.md already exists (skipping)"
}

# ── Validation ────────────────────────────────────────────────────────────────
Write-Header "Validation"
$checkTools = @("scoop", "git", "node", "bun", "rg", "fzf", "bat", "lazygit",
                "starship", "mise", "duckdb", "gitleaks", "trivy", "infisical",
                "claude", "aider", "ollama", "uv", "markitdown")
$pass = 0; $fail = 0
foreach ($t in $checkTools) {
    if (Test-Command $t) { Write-OK $t; $pass++ } else { Write-Warn "$t — NOT FOUND"; $fail++ }
}
Write-Host ""
if ($fail -eq 0) { Write-OK "All tools present!" } else { Write-Warn "$fail tools missing — check warnings above" }

# ── Manual Steps ──────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host "  MANUAL STEPS — complete after bootstrap finishes"               -ForegroundColor Cyan
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host ""
Write-Host "  1. Open a NEW PowerShell window (activates profile changes)"
Write-Host "  2. claude login   -> sign in with Claude Pro account"
Write-Host "  3. codex          -> 'Sign in with ChatGPT' -> browser auth"
Write-Host "  4. infisical login  (then: infisical init  per project)"
Write-Host "  5. Inside a 'claude' session, add the pinned plugins/skills:"
Write-Host "       /plugin marketplace add openai/codex-plugin-cc"
Write-Host "       /plugin install codex@openai-codex ; /reload-plugins ; /codex:setup"
Write-Host "       /plugin marketplace add obra/superpowers-marketplace"
Write-Host "       /plugin install superpowers@superpowers-marketplace"
Write-Host "     (Full pinned allowlist: see skills-lock.json)"
Write-Host "  6. Obsidian: install from obsidian.md -> open ~/vault as vault"
Write-Host "  7. Edit ~/.claude/CLAUDE.md — fill in your Name and Role"
Write-Host ""
Write-Host "  Bootstrap complete. $pass tools installed, $fail missing." -ForegroundColor Green
try { Stop-Transcript | Out-Null } catch {}
Write-Host "  Log: $logFile"
