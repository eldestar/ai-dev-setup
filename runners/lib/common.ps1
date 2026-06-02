# Shared helpers for the Windows installer.
# Reads single-source config from config/ and templates/ so nothing is duplicated inline.

Set-StrictMode -Version Latest

function Get-RepoRoot {
    # This lib lives at <repo>/runners/lib/common.ps1
    return (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
}

function Get-ModelSelection {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][ValidateSet('nvidia', 'apple_silicon', 'amd', 'cpu_only')][string]$GpuType,
        [Parameter(Mandatory)][int]$CapacityGb,   # VRAM for nvidia; RAM otherwise
        [string]$ConfigPath
    )
    if (-not $ConfigPath) { $ConfigPath = Join-Path (Get-RepoRoot) 'config\models.csv' }
    $lookup = if ($GpuType -eq 'amd') { 'cpu_only' } else { $GpuType }
    $rows = Import-Csv $ConfigPath |
        Where-Object { $_.gpu_type -eq $lookup } |
        Sort-Object { [int]$_.min_gb } -Descending
    foreach ($r in $rows) {
        if ($CapacityGb -ge [int]$r.min_gb) {
            return [pscustomobject]@{ Primary = $r.primary; Fast = $r.fast }
        }
    }
    return [pscustomobject]@{ Primary = 'llama3.2:3b'; Fast = 'qwen3:1.7b' }  # safety fallback
}

function Expand-Template {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$TemplatePath,
        [Parameter(Mandatory)][hashtable]$Tokens
    )
    $content = Get-Content $TemplatePath -Raw
    foreach ($k in $Tokens.Keys) { $content = $content.Replace($k, [string]$Tokens[$k]) }
    return $content
}

function Get-CoreTools {
    [CmdletBinding()]
    param([string]$ConfigPath)
    if (-not $ConfigPath) { $ConfigPath = Join-Path (Get-RepoRoot) 'config\tools.csv' }
    return Import-Csv $ConfigPath
}
