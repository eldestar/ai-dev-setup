# doctor.ps1 — read-only preflight / health check (Windows). Changes nothing.
# Reports environment + per-component status and audits installed skills/agents
# against skills-lock.json.
[CmdletBinding()]
param([string]$TargetRoot = (Join-Path $HOME ".claude"))
Set-StrictMode -Version Latest
$ErrorActionPreference = "Continue"

$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
function Test-Cmd($n) { return $null -ne (Get-Command $n -ErrorAction SilentlyContinue) }
$ok = 0; $miss = 0

Write-Host "`n=== Environment ==="
Write-Host "  OS: $((Get-CimInstance Win32_OperatingSystem).Caption)"

Write-Host "`n=== Tools ==="
$core = @()
Import-Csv (Join-Path $RepoRoot 'config\tools.csv') | ForEach-Object { $core += $_.check }
foreach ($t in ($core + @('claude', 'codex', 'aider', 'ollama', 'uv', 'gitleaks', 'trivy', 'semgrep', 'infisical', 'markitdown'))) {
    if (Test-Cmd $t) { Write-Host "  [OK]   $t" -ForegroundColor Green; $ok++ }
    else { Write-Host "  [MISS] $t" -ForegroundColor Yellow; $miss++ }
}

Write-Host "`n=== Single-source config ==="
foreach ($f in @('config\models.csv', 'config\tools.csv', 'templates\CLAUDE.md.tmpl', 'skills-lock.json')) {
    if (Test-Path (Join-Path $RepoRoot $f)) { Write-Host "  [OK]   $f" } else { Write-Host "  [MISS] $f" -ForegroundColor Yellow }
}

Write-Host "`n=== Skill/agent audit (installed vs skills-lock.json) ==="
$lock = Get-Content (Join-Path $RepoRoot 'skills-lock.json') -Raw | ConvertFrom-Json
$wantSkills = @($lock.skills.name)
$wantAgents = @()
foreach ($a in $lock.agents) { $wantAgents += $a.files.PSObject.Properties.Name }
$haveSkills = @(); if (Test-Path "$TargetRoot\skills") { $haveSkills = @((Get-ChildItem "$TargetRoot\skills" -Directory -ErrorAction SilentlyContinue).Name) }
$haveAgents = @(); if (Test-Path "$TargetRoot\agents") { $haveAgents = @((Get-ChildItem "$TargetRoot\agents" -File -ErrorAction SilentlyContinue).Name) }
function Report($label, $want, $have) {
    $missing = @($want | Where-Object { $_ -notin $have })
    $extra   = @($have | Where-Object { $_ -notin $want })
    Write-Host "  ${label}: $($want.Count) in lock, $($have.Count) installed"
    if ($missing.Count) { Write-Host "    not installed: $($missing -join ', ')" -ForegroundColor Yellow }
    if ($extra.Count)   { Write-Host "    UNPINNED/extra (not in lock): $($extra -join ', ')" -ForegroundColor Red }
    if (-not $missing.Count -and -not $extra.Count) { Write-Host "    in sync" -ForegroundColor Green }
}
Report "skills" $wantSkills $haveSkills
Report "agents" $wantAgents $haveAgents

Write-Host "`nSummary: $ok tools present, $miss missing."
