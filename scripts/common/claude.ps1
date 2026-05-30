function Install-ClaudeAssetsAndCli {
    param(
        [Parameter(Mandatory)]$Context,
        [string]$TargetRoot
    )

    Write-SetupHeader "Claude Code"
    $installed = $Context.HasClaude
    $configured = $false
    $assetsInstalled = $false

    if (-not $installed) {
        if ($Context.HasNpm -and (Confirm-SetupAction "Claude Code was not found. Install @anthropic-ai/claude-code with npm?")) {
            $result = Invoke-SetupCommand "npm" @("install", "-g", "@anthropic-ai/claude-code@latest")
            $installed = $result.Success -and (Test-SetupCommand "claude")
            if (-not $installed) { Write-SetupError "Claude Code npm install did not validate." }
        } else {
            $script:ManualSteps.Add("Install Claude Code from the official Anthropic docs, then run: claude --version") | Out-Null
        }
    } else {
        Write-SetupOk "Claude Code command found"
    }

    if ($installed) {
        $version = Invoke-SetupCommand "claude" @("--version")
        if ($version.Success) {
            Write-SetupOk "Claude validates with claude --version"
            $configured = $true
        } else {
            Write-SetupWarn "Claude command exists but validation failed."
            $script:ManualSteps.Add("Run claude login or review Claude Code authentication, then verify with: claude --version") | Out-Null
        }
    }

    $claudeHome = Join-Path $Context.Home ".claude"
    $projectRoot = if ($TargetRoot) { $TargetRoot } else { $script:RepoRoot }
    $assetsInstalled = (Copy-SetupItem -Source (Join-Path $script:RepoRoot "agents/claude/setup-orchestrator.md") -Destination (Join-Path $claudeHome "agents/setup-orchestrator.md")) -or $assetsInstalled
    $assetsInstalled = (Copy-SetupItem -Source (Join-Path $script:RepoRoot "skills/shared/installer-maintenance") -Destination (Join-Path $claudeHome "skills/installer-maintenance") -Recurse) -or $assetsInstalled
    $assetsInstalled = (Copy-SetupItem -Source (Join-Path $script:RepoRoot "config/claude/commands/adversarial-codex-review.md") -Destination (Join-Path $claudeHome "commands/adversarial-codex-review.md")) -or $assetsInstalled
    $assetsInstalled = (Copy-SetupItem -Source (Join-Path $script:RepoRoot "config/claude/settings.recommended.json") -Destination (Join-Path $Context.Home ".ai-dev-setup/reference/claude/settings.recommended.json")) -or $assetsInstalled
    $assetsInstalled = (Copy-SetupItem -Source (Join-Path $script:RepoRoot "config/claude/CLAUDE.md") -Destination (Join-Path $projectRoot "CLAUDE.md")) -or $assetsInstalled

    [pscustomobject]@{
        Installed = $(if ($installed) { "yes" } else { "no" })
        Configured = $(if ($configured) { "yes" } else { "no" })
        AssetsInstalled = $(if ($assetsInstalled) { "yes" } else { "no" })
    }
}
