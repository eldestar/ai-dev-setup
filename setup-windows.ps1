# setup-windows.ps1 — AI Dev Environment bootstrap (Windows)
#
# This is the `irm ... | iex` entry point. It is intentionally THIN: it ensures git,
# clones the ai-dev-setup repo, then runs the repo's installer (runners/install.ps1),
# which reads single-source config in config/ and templates/. Keeping the real logic in
# the repo (not inlined here) is what prevents SETUP.md <-> setup-windows.ps1 drift.
#
# Usage:
#   irm https://raw.githubusercontent.com/eldestar/ai-dev-setup/main/setup-windows.ps1 | iex
#
#Requires -Version 5.1

# Wrapped in a function so early returns never close the caller's shell under `| iex`.
function Invoke-AiDevBootstrap {
    Set-StrictMode -Version Latest
    $ErrorActionPreference = "Continue"

    $RepoUrl = "https://github.com/eldestar/ai-dev-setup.git"
    $RepoRef = "main"   # pin to a tag/commit for reproducible installs
    $RepoDir = Join-Path $HOME "ai-dev-setup"

    function Write-Header($t) { Write-Host "`n=== $t ===" -ForegroundColor Cyan }
    function Write-OK($t)     { Write-Host "  [OK] $t" -ForegroundColor Green }
    function Write-Info($t)   { Write-Host "  ... $t" -ForegroundColor Gray }
    function Write-Warn($t)   { Write-Host "  [!] $t" -ForegroundColor Yellow }
    function Test-Cmd($n)     { return $null -ne (Get-Command $n -ErrorAction SilentlyContinue) }

    Write-Header "AI Dev Setup — Windows bootstrap"

    # ── Path choice: WSL2 (recommended) vs native ──
    $wslInstalled = $false
    try { if ((wsl --status 2>&1 | Out-String) -match "Default Distribution") { $wslInstalled = $true } } catch {}

    Write-Host ""
    Write-Host "  [1] WSL2 (recommended) — full Linux environment, identical to Mac"
    Write-Host "  [2] Native PowerShell  — installs everything via Scoop on Windows"
    Write-Host ""
    if ($wslInstalled) { Write-OK "WSL2 already installed" } else { Write-Warn "WSL2 not detected" }
    $choice  = Read-Host "  Choose path [1=WSL2  2=Native] (default 1)"
    $useWSL2 = ($choice -ne "2")

    # ── WSL2 path ──
    if ($useWSL2) {
        Write-Header "WSL2 Setup"
        if (-not $wslInstalled) {
            Write-Info "Installing WSL2 + Ubuntu (requires restart)..."
            wsl --install
            Write-Warn "RESTART REQUIRED. After restart, open Ubuntu and run:"
            Write-Host ""
            Write-Host "    git clone $RepoUrl ~/ai-dev-setup && cd ~/ai-dev-setup"
            Write-Host "    npm install -g @anthropic-ai/claude-code && claude login"
            Write-Host '    claude "Read SETUP.md, run system detection, execute all phases. Log to SETUP_LOG.md."'
            Write-Host ""
            $restart = Read-Host "  Restart now? [y/N]"
            if ($restart -match "^[Yy]") { Restart-Computer -Force }
            return
        }
        Write-Info "Cloning/updating repo inside WSL2..."
        wsl -- bash -c "[ -d ~/ai-dev-setup/.git ] && (cd ~/ai-dev-setup && git pull --ff-only) || git clone $RepoUrl ~/ai-dev-setup" 2>&1 | Out-Null
        $claudeExists = wsl -- bash -c "command -v claude >/dev/null 2>&1 && echo yes || echo no" 2>&1
        if ($claudeExists -match "no") {
            Write-Info "Installing Node + Claude Code inside WSL2..."
            wsl -- bash -c "curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash - && sudo apt-get install -y nodejs && npm install -g @anthropic-ai/claude-code"
        } else {
            Write-OK "Claude Code already present in WSL2"
        }
        Write-Host ""
        Write-Host "  NEXT STEPS (inside WSL2 Ubuntu):"
        Write-Host "    1. wsl    2. claude login    3. cd ~/ai-dev-setup"
        Write-Host '    4. claude "Read SETUP.md, run system detection, execute all phases. Log to SETUP_LOG.md."'
        return
    }

    # ── Native path: ensure git, clone repo, run runners/install.ps1 ──
    Write-Header "Ensure git"
    if (-not (Test-Cmd git)) {
        if (Test-Cmd winget) {
            Write-Info "Installing Git via winget..."
            winget install --id Git.Git -e --source winget --accept-source-agreements --accept-package-agreements
            $env:PATH = [Environment]::GetEnvironmentVariable("PATH", "Machine") + ";" + [Environment]::GetEnvironmentVariable("PATH", "User")
        } else {
            Write-Warn "git and winget both missing. Install Git for Windows (https://git-scm.com/download/win), reopen PowerShell, and re-run."
            return
        }
    }
    if (-not (Test-Cmd git)) {
        Write-Warn "git still not on PATH — open a NEW PowerShell window and re-run."
        return
    }
    Write-OK "git: $(git --version)"

    Write-Header "Clone / update ai-dev-setup at $RepoDir"
    if (Test-Path (Join-Path $RepoDir ".git")) {
        Write-Info "Updating existing repo..."
        git -C $RepoDir fetch --depth 1 origin $RepoRef 2>&1 | Out-Null
        git -C $RepoDir checkout $RepoRef 2>&1 | Out-Null
        git -C $RepoDir pull --ff-only 2>&1 | Out-Null
    } else {
        # NOTE: --branch accepts a branch or tag. To pin an exact commit SHA, switch to
        # `git clone` then `git -C $RepoDir checkout <sha>` (a SHA cannot be used with --branch).
        git clone --depth 1 --branch $RepoRef $RepoUrl $RepoDir 2>&1 | Out-Null
    }

    $installer = Join-Path $RepoDir "runners\install.ps1"
    if (-not (Test-Path $installer)) {
        Write-Warn "Clone failed or installer missing. Clone manually:"
        Write-Warn "  git clone $RepoUrl `"$RepoDir`"  ; then run runners\install.ps1"
        return
    }
    Write-OK "Repo ready at $RepoDir"

    Write-Header "Running native installer (runners\install.ps1)"
    & $installer
}

Invoke-AiDevBootstrap
