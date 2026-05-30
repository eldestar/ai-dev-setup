#Requires -Version 5.1
<#
.SYNOPSIS
Cross-platform Windows entry point for the Claude + Codex setup installer.

.EXAMPLE
.\install.ps1 -DryRun -VerboseLogging

.EXAMPLE
.\install.ps1 -Yes
#>
[CmdletBinding()]
param(
    [switch]$DryRun,
    [switch]$Yes,
    [switch]$VerboseLogging,
    [string]$TargetRoot,
    [string]$UserHome
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Continue"

$script:RepoRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$script:DryRun = [bool]$DryRun
$script:AssumeYes = [bool]$Yes
$script:VerboseLogging = [bool]$VerboseLogging
$script:ManualSteps = New-Object System.Collections.Generic.List[string]
$script:Errors = New-Object System.Collections.Generic.List[string]

. (Join-Path $script:RepoRoot "scripts/common/logging.ps1")
. (Join-Path $script:RepoRoot "scripts/common/detection.ps1")
. (Join-Path $script:RepoRoot "scripts/common/assets.ps1")
. (Join-Path $script:RepoRoot "scripts/common/claude.ps1")
. (Join-Path $script:RepoRoot "scripts/common/codex.ps1")
. (Join-Path $script:RepoRoot "scripts/windows/setup.ps1")

Initialize-SetupLog
Write-SetupHeader "Claude + Codex Installer"
Write-SetupInfo "Repo root: $script:RepoRoot"
if ($script:DryRun) { Write-SetupWarn "Dry run enabled. No changes will be written." }

$context = Get-SetupContext -UserHome $UserHome
Write-SetupHeader "Detected Environment"
Write-SetupInfo "OS: $($context.OSName)"
Write-SetupInfo "Architecture: $($context.Architecture)"
Write-SetupInfo "PowerShell: $($context.PowerShellEdition) $($context.PowerShellVersion)"
Write-SetupInfo "Detected shells: $($context.Shells -join ', ')"

if ($context.Platform -eq "Windows") {
    Install-WindowsPrerequisites -Context $context
}

$assets = Install-RepoAssets -Context $context -TargetRoot $TargetRoot
$claude = Install-ClaudeAssetsAndCli -Context $context -TargetRoot $TargetRoot
$codex = Install-CodexAssetsAndCli -Context $context

Write-SetupHeader "Final Summary"
Write-SetupInfo "OS detected: $($context.OSName)"
Write-SetupInfo "Shells detected: $($context.Shells -join ', ')"
Write-SetupInfo "Claude installed/configured: $($claude.Installed)/$($claude.Configured)"
Write-SetupInfo "Codex installed/configured: $($codex.Installed)/$($codex.Configured)"
Write-SetupInfo "Shared assets installed: $($assets.SharedInstalled)"
Write-SetupInfo "Claude assets installed: $($claude.AssetsInstalled)"
Write-SetupInfo "Codex assets installed: $($codex.AssetsInstalled)"

if ($script:ManualSteps.Count -gt 0) {
    Write-SetupWarn "Manual steps still required:"
    foreach ($step in $script:ManualSteps) { Write-SetupWarn "  - $step" }
} else {
    Write-SetupOk "No manual fallback steps were recorded."
}

if ($script:Errors.Count -gt 0) {
    Write-SetupWarn "Errors or skipped items:"
    foreach ($err in $script:Errors) { Write-SetupWarn "  - $err" }
} else {
    Write-SetupOk "No errors recorded."
}

Write-SetupInfo "Log file: $script:LogPath"
