function Copy-SetupItem {
    param(
        [string]$Source,
        [string]$Destination,
        [switch]$Recurse
    )

    if (-not (Test-Path $Source)) {
        Write-SetupWarn "Source missing, skipping: $Source"
        return $false
    }

    if ($script:DryRun) {
        Write-SetupInfo "DRY RUN: copy $Source -> $Destination"
        return $true
    }

    $parent = Split-Path -Parent $Destination
    if ($parent -and -not (Test-Path $parent)) { New-Item -ItemType Directory -Path $parent -Force | Out-Null }

    if ((Test-Path $Destination) -and -not (Confirm-SetupAction "Replace existing $Destination after backing it up?")) {
        Write-SetupWarn "Skipped existing destination: $Destination"
        return $false
    }

    if (Test-Path $Destination) {
        $backup = "$Destination.backup-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
        Move-Item -LiteralPath $Destination -Destination $backup -Force
        Write-SetupOk "Backed up $Destination to $backup"
    }

    if ($Recurse) {
        Copy-Item -LiteralPath $Source -Destination $Destination -Recurse -Force
    } else {
        Copy-Item -LiteralPath $Source -Destination $Destination -Force
    }
    Write-SetupOk "Installed $Destination"
    return $true
}

function Install-RepoAssets {
    param(
        [Parameter(Mandatory)]$Context,
        [string]$TargetRoot
    )

    Write-SetupHeader "Shared Repo Assets"
    $homeBase = Join-Path $Context.Home ".ai-dev-setup"
    $shared = Join-Path $homeBase "shared"
    $projectRoot = if ($TargetRoot) { $TargetRoot } else { $script:RepoRoot }

    $installed = $false
    $installed = (Copy-SetupItem -Source (Join-Path $script:RepoRoot "config/shared") -Destination (Join-Path $shared "config") -Recurse) -or $installed
    $installed = (Copy-SetupItem -Source (Join-Path $script:RepoRoot "agents/shared") -Destination (Join-Path $shared "agents") -Recurse) -or $installed
    $installed = (Copy-SetupItem -Source (Join-Path $script:RepoRoot "templates") -Destination (Join-Path $shared "templates") -Recurse) -or $installed
    $installed = (Copy-SetupItem -Source (Join-Path $script:RepoRoot "config/shared/AGENTS.md") -Destination (Join-Path $projectRoot "AGENTS.md")) -or $installed

    [pscustomobject]@{ SharedInstalled = $(if ($installed) { "yes" } else { "no" }) }
}
