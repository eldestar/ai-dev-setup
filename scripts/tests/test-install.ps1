#Requires -Version 5.1
[CmdletBinding()]
param(
    [switch]$KeepSandbox
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$installer = Join-Path $repoRoot "install.ps1"
$pwsh = (Get-Command pwsh -ErrorAction Stop).Source
$sandboxRoot = Join-Path ([System.IO.Path]::GetTempPath()) "ai-dev-setup-tests-$PID"

function Assert-True([bool]$Condition, [string]$Message) {
    if (-not $Condition) { throw "ASSERTION FAILED: $Message" }
}

function Write-MockCommand([string]$Bin, [string]$Name, [string]$Body) {
    $path = Join-Path $Bin "$Name.cmd"
    [System.IO.File]::WriteAllText($path, "@echo off`r`n$Body`r`n")
}

function Initialize-MockBin([string]$Bin, [string[]]$InitialTools) {
    New-Item -ItemType Directory -Path $Bin -Force | Out-Null
    Write-MockCommand $Bin "git" "echo git version mock"
    Write-MockCommand $Bin "node" "echo v22.0.0-mock"
    Write-MockCommand $Bin "npm" @'
echo %*>> "%MOCK_NPM_LOG%"
if "%~3"=="@anthropic-ai/claude-code@latest" (
  echo @echo off> "%~dp0claude.cmd"
  echo echo claude-code mock>> "%~dp0claude.cmd"
  exit /b 0
)
if "%~3"=="@openai/codex@latest" (
  echo @echo off> "%~dp0codex.cmd"
  echo echo codex-cli mock>> "%~dp0codex.cmd"
  exit /b 0
)
exit /b 0
'@

    if ($InitialTools -contains "claude") { Write-MockCommand $Bin "claude" "echo claude-code mock" }
    if ($InitialTools -contains "codex") { Write-MockCommand $Bin "codex" "echo codex-cli mock" }
}

function Invoke-InstallerScenario {
    param(
        [string]$Name,
        [string[]]$InitialTools,
        [string[]]$ExpectedPackages
    )

    $root = Join-Path $sandboxRoot $Name
    $bin = Join-Path $root "bin"
    $sandboxHome = Join-Path $root "home"
    $project = Join-Path $root "project"
    $npmLog = Join-Path $root "npm.log"
    Initialize-MockBin $bin $InitialTools

    $start = New-Object System.Diagnostics.ProcessStartInfo
    $start.FileName = $pwsh
    $start.Arguments = "-NoProfile -File `"$installer`" -Yes -UserHome `"$sandboxHome`" -TargetRoot `"$project`""
    $start.UseShellExecute = $false
    $start.RedirectStandardOutput = $true
    $start.RedirectStandardError = $true
    $start.EnvironmentVariables["PATH"] = $bin
    $start.EnvironmentVariables["MOCK_NPM_LOG"] = $npmLog

    $process = [System.Diagnostics.Process]::Start($start)
    $stdout = $process.StandardOutput.ReadToEnd()
    $stderr = $process.StandardError.ReadToEnd()
    $process.WaitForExit()

    Assert-True ($process.ExitCode -eq 0) "$Name exited with $($process.ExitCode): $stderr"
    Assert-True ($stdout -match "Claude installed/configured: yes/yes") "$Name did not configure Claude"
    Assert-True ($stdout -match "Codex installed/configured: yes/yes") "$Name did not configure Codex"
    Assert-True (Test-Path (Join-Path $project "AGENTS.md")) "$Name missing project AGENTS.md"
    Assert-True (Test-Path (Join-Path $project "CLAUDE.md")) "$Name missing project CLAUDE.md"
    Assert-True (Test-Path (Join-Path $sandboxHome ".claude/skills/ai-dev-setup/installer-maintenance/SKILL.md")) "$Name missing Claude skill"
    Assert-True (Test-Path (Join-Path $sandboxHome ".codex/goals/ai-dev-setup/setup-validation.goal.md")) "$Name missing Codex goal"

    $npmCalls = if (Test-Path $npmLog) { Get-Content $npmLog -Raw } else { "" }
    foreach ($package in $ExpectedPackages) {
        Assert-True ($npmCalls -match [regex]::Escape($package)) "$Name did not install expected package $package"
    }
    foreach ($package in @("@anthropic-ai/claude-code@latest", "@openai/codex@latest")) {
        if ($ExpectedPackages -notcontains $package) {
            Assert-True ($npmCalls -notmatch [regex]::Escape($package)) "$Name unexpectedly installed package $package"
        }
    }

    Write-Host "[OK] $Name"
}

try {
    New-Item -ItemType Directory -Path $sandboxRoot -Force | Out-Null
    Invoke-InstallerScenario "neither-installed" @() @("@anthropic-ai/claude-code@latest", "@openai/codex@latest")
    Invoke-InstallerScenario "claude-only" @("claude") @("@openai/codex@latest")
    Invoke-InstallerScenario "codex-only" @("codex") @("@anthropic-ai/claude-code@latest")
    Invoke-InstallerScenario "both-installed" @("claude", "codex") @()
    Write-Host "All installer sandbox scenarios passed."
} finally {
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
