#Requires -Version 5.1
[CmdletBinding()]
param(
    [switch]$KeepSandbox
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$originalUserProfile = [Environment]::GetEnvironmentVariable("USERPROFILE")
$originalHome = [Environment]::GetEnvironmentVariable("HOME")
$originalCodexHome = [Environment]::GetEnvironmentVariable("CODEX_HOME")
$sandboxRoot = Join-Path ([System.IO.Path]::GetTempPath()) "ai-dev-setup-extension-tests-$PID"

function Assert-True([bool]$Condition, [string]$Message) {
    if (-not $Condition) { throw "ASSERTION FAILED: $Message" }
}

function Invoke-Checked {
    param(
        [string]$Command,
        [string[]]$Arguments
    )

    $output = & $Command @Arguments 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "$Command $($Arguments -join ' ') failed:`n$($output -join "`n")"
    }
    return @($output)
}

try {
    $skillValidator = Join-Path $originalUserProfile ".codex/skills/.system/skill-creator/scripts/quick_validate.py"
    $pluginValidator = Join-Path $originalUserProfile ".codex/skills/.system/plugin-creator/scripts/validate_plugin.py"
    $sharedSkill = Join-Path $repoRoot "skills/shared/installer-maintenance"
    $codexPlugin = Join-Path $repoRoot "plugins/ai-dev-setup"
    $claudePlugin = Join-Path $repoRoot "plugins/claude/ai-dev-setup"
    $codexSubagent = Join-Path $repoRoot "agents/codex/installer-reviewer.toml"

    Assert-True (Test-Path $skillValidator) "Codex skill validator is unavailable"
    Assert-True (Test-Path $pluginValidator) "Codex plugin validator is unavailable"

    $null = Invoke-Checked "uv" @("run", "--with", "pyyaml", "python", $skillValidator, $sharedSkill)
    $null = Invoke-Checked "uv" @("run", "--with", "pyyaml", "python", $pluginValidator, $codexPlugin)
    $null = Invoke-Checked "python" @("-c", "import pathlib,tomllib; tomllib.loads(pathlib.Path(r'$codexSubagent').read_text())")
    $null = Invoke-Checked "claude" @("plugin", "validate", $claudePlugin)

    $claudeDetails = Invoke-Checked "claude" @("--plugin-dir", $claudePlugin, "plugin", "details", "ai-dev-setup")
    $claudeText = $claudeDetails -join "`n"
    Assert-True ($claudeText -match "installer-maintenance") "Claude plugin inventory missing skill"
    Assert-True ($claudeText -match "setup-orchestrator") "Claude plugin inventory missing subagent"
    Assert-True ($claudeText -match "adversarial-codex-review") "Claude plugin inventory missing command"
    Write-Host "[OK] Claude plugin validation and inventory"

    $sandboxHome = Join-Path $sandboxRoot "home"
    $codexHome = Join-Path $sandboxRoot "codex-home"
    $project = Join-Path $sandboxRoot "project"
    New-Item -ItemType Directory -Path $sandboxHome -Force | Out-Null
    New-Item -ItemType Directory -Path $codexHome -Force | Out-Null
    New-Item -ItemType Directory -Path $project -Force | Out-Null
    Copy-Item -LiteralPath (Join-Path $repoRoot "config/shared/AGENTS.md") -Destination (Join-Path $project "AGENTS.md")

    $env:HOME = $sandboxHome
    $env:USERPROFILE = $sandboxHome
    $env:CODEX_HOME = $codexHome

    $null = Invoke-Checked "codex" @("plugin", "marketplace", "add", $repoRoot)
    $available = Invoke-Checked "codex" @("plugin", "list")
    Assert-True (($available -join "`n") -match "ai-dev-setup@ai-dev-setup") "Codex marketplace list missing plugin"
    $null = Invoke-Checked "codex" @("plugin", "add", "ai-dev-setup@ai-dev-setup")
    $installed = Invoke-Checked "codex" @("plugin", "list")
    Assert-True (($installed -join "`n") -match "installed, enabled") "Codex plugin was not enabled"
    Write-Host "[OK] Codex marketplace discovery and plugin install"

    Push-Location $project
    try {
        $promptInput = Invoke-Checked "codex" @("debug", "prompt-input", "compatibility probe")
    } finally {
        Pop-Location
    }
    Assert-True (($promptInput -join "`n") -match "AGENTS.md instructions") "Codex prompt input missing project AGENTS.md"
    Assert-True (($promptInput -join "`n") -match "ai-dev-setup:installer-maintenance") "Codex prompt input missing plugin skill"
    Write-Host "[OK] Codex AGENTS.md and plugin skill prompt discovery"

    Write-Host "All native extension compatibility checks passed."
} finally {
    $env:HOME = $originalHome
    $env:USERPROFILE = $originalUserProfile
    $env:CODEX_HOME = $originalCodexHome

    if ($KeepSandbox) {
        Write-Host "Sandbox retained at $sandboxRoot"
    } elseif (Test-Path $sandboxRoot) {
        $tempRoot = [System.IO.Path]::GetFullPath([System.IO.Path]::GetTempPath())
        $resolved = [System.IO.Path]::GetFullPath($sandboxRoot)
        if (-not $resolved.StartsWith($tempRoot, [System.StringComparison]::OrdinalIgnoreCase)) {
            throw "Refusing to clean sandbox outside temp root: $resolved"
        }
        Remove-Item -LiteralPath $resolved -Recurse -Force
    }
}
