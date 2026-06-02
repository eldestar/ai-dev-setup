# install-skills.ps1 — install ONLY the pinned allowlist from skills-lock.json (Windows).
# No bulk installs. Clones each source at its pinned commit SHA, copies the declared files,
# and verifies SHA-256 anchors for skills. Plugins/MCP are printed as the claude commands to run.
#
# Usage:  scripts\install-skills.ps1 [-LockPath <path>] [-TargetRoot <dir>]
[CmdletBinding()]
param(
    [string]$LockPath,
    [string]$TargetRoot = (Join-Path $HOME ".claude")
)
Set-StrictMode -Version Latest
$ErrorActionPreference = "Continue"

if (-not $LockPath) { $LockPath = Join-Path (Split-Path $PSScriptRoot -Parent) "skills-lock.json" }
if (-not (Test-Path $LockPath)) { Write-Host "[!] skills-lock.json not found at $LockPath" -ForegroundColor Yellow; return }
if ($null -eq (Get-Command git -ErrorAction SilentlyContinue)) { Write-Host "[!] git is required for skills install — skipping" -ForegroundColor Yellow; return }

$lock  = Get-Content $LockPath -Raw | ConvertFrom-Json
$cache = Join-Path ([System.IO.Path]::GetTempPath()) "ai-dev-skills-cache"
New-Item -ItemType Directory -Path $cache -Force | Out-Null
New-Item -ItemType Directory -Path (Join-Path $TargetRoot "skills") -Force | Out-Null
New-Item -ItemType Directory -Path (Join-Path $TargetRoot "agents") -Force | Out-Null

function Get-RepoAtRef {
    param([string]$Repo, [string]$Ref)
    $key = (($Repo -replace '[^a-zA-Z0-9]', '_') + "_" + $Ref.Substring(0, 8))
    $dir = Join-Path $cache $key
    if (-not (Test-Path (Join-Path $dir ".git"))) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
        git -C $dir init -q
        git -C $dir remote add origin $Repo 2>$null
        git -C $dir fetch -q --depth 1 origin $Ref
        if ($LASTEXITCODE -ne 0) { throw "fetch of pinned ref failed" }
        git -C $dir checkout -q FETCH_HEAD
    }
    return $dir
}

Write-Host "`n=== Skills (pinned, SHA-256 verified) ===" -ForegroundColor Cyan
foreach ($s in $lock.skills) {
    try {
        $src      = Get-RepoAtRef -Repo $s.repo -Ref $s.ref
        $fromPath = Join-Path $src ($s.from -replace '/', '\')
        if (-not (Test-Path $fromPath)) { Write-Host "  [!] $($s.name): source path '$($s.from)' missing at pinned ref" -ForegroundColor Yellow; continue }
        $dest = Join-Path $TargetRoot ("skills\" + $s.name)
        if (Test-Path $dest) { Remove-Item $dest -Recurse -Force }
        Copy-Item $fromPath $dest -Recurse -Force
        if ($s.sha256 -and $s.anchor) {
            $got = (Get-FileHash (Join-Path $dest $s.anchor) -Algorithm SHA256).Hash.ToLower()
            if ($got -ne ([string]$s.sha256).ToLower()) {
                Write-Host "  [!] $($s.name): SHA-256 MISMATCH (expected $($s.sha256), got $got) — review" -ForegroundColor Red; continue
            }
        }
        Write-Host "  [OK] $($s.name) (verified)" -ForegroundColor Green
    } catch { Write-Host "  [!] $($s.name): $_" -ForegroundColor Yellow }
}

Write-Host "`n=== Agents (pinned, reviewed subset) ===" -ForegroundColor Cyan
foreach ($a in $lock.agents) {
    try {
        $src = Get-RepoAtRef -Repo $a.repo -Ref $a.ref
        foreach ($prop in $a.files.PSObject.Properties) {
            $target   = $prop.Name
            $fromFile = Join-Path $src ($prop.Value -replace '/', '\')
            if (-not (Test-Path $fromFile)) { Write-Host "  [!] $($a.source)/$target : '$($prop.Value)' missing at pinned ref" -ForegroundColor Yellow; continue }
            Copy-Item $fromFile (Join-Path $TargetRoot ("agents\" + $target)) -Force
            Write-Host "  [OK] $target" -ForegroundColor Green
        }
    } catch { Write-Host "  [!] $($a.source): $_" -ForegroundColor Yellow }
}

Write-Host "`n=== Plugins / MCP — run inside a 'claude' session (auth may be required) ===" -ForegroundColor Cyan
foreach ($p in $lock.plugins) {
    if ($p.PSObject.Properties.Name -contains 'plugin')           { Write-Host "  /plugin marketplace add $($p.marketplace)#$($p.ref) ; /plugin install $($p.plugin)" }
    elseif ($p.PSObject.Properties.Name -contains 'marketplace')  { Write-Host "  /plugin marketplace add $($p.marketplace)   (install desired plugins)" }
    elseif ($p.PSObject.Properties.Name -contains 'install')      { Write-Host "  $($p.install)" }
    else { Write-Host "  $($p.name): $($p.repo) @ $($p.ref)" }
}
foreach ($m in $lock.mcp) { Write-Host "  $($m.cmd)" }
Write-Host ""
Write-Host "Skills/agents installed from the pinned allowlist into $TargetRoot"
