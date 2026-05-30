function Install-CodexAssetsAndCli {
    param([Parameter(Mandatory)]$Context)

    Write-SetupHeader "Codex CLI"
    $installed = $Context.HasCodex
    $configured = $false
    $assetsInstalled = $false

    if (-not $installed) {
        if ($Context.HasNpm -and (Confirm-SetupAction "Codex CLI was not found. Install @openai/codex with npm?")) {
            $result = Invoke-SetupCommand "npm" @("install", "-g", "@openai/codex@latest")
            $installed = $result.Success -and (Test-SetupCommand "codex")
            if (-not $installed) { Write-SetupError "Codex npm install did not validate." }
        } else {
            $script:ManualSteps.Add("Install Codex CLI from the official OpenAI docs, then run: codex --version") | Out-Null
        }
    } else {
        Write-SetupOk "Codex command found"
    }

    if ($installed) {
        $version = Invoke-SetupCommand "codex" @("--version")
        if ($version.Success) {
            Write-SetupOk "Codex validates with codex --version"
            $configured = $true
        } else {
            Write-SetupWarn "Codex command exists but validation failed."
            $script:ManualSteps.Add("Run codex login or review Codex CLI authentication, then verify with: codex --version") | Out-Null
        }
    }

    $codexHome = if ($Context.HomeOverridden) { Join-Path $Context.Home ".codex" } elseif ($env:CODEX_HOME) { $env:CODEX_HOME } else { Join-Path $Context.Home ".codex" }
    $agentsHome = Join-Path $Context.Home ".agents"
    $assetsInstalled = (Copy-SetupItem -Source (Join-Path $script:RepoRoot "agents/codex/installer-reviewer.toml") -Destination (Join-Path $codexHome "agents/installer-reviewer.toml")) -or $assetsInstalled
    $assetsInstalled = (Copy-SetupItem -Source (Join-Path $script:RepoRoot "skills/shared/installer-maintenance") -Destination (Join-Path $agentsHome "skills/installer-maintenance") -Recurse) -or $assetsInstalled
    $assetsInstalled = (Copy-SetupItem -Source (Join-Path $script:RepoRoot "config/codex") -Destination (Join-Path $Context.Home ".ai-dev-setup/reference/codex") -Recurse) -or $assetsInstalled

    [pscustomobject]@{
        Installed = $(if ($installed) { "yes" } else { "no" })
        Configured = $(if ($configured) { "yes" } else { "no" })
        AssetsInstalled = $(if ($assetsInstalled) { "yes" } else { "no" })
    }
}
