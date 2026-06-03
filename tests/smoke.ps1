# smoke.ps1 — fast validation gate (no installs). Exit non-zero on any failure.
Set-StrictMode -Version Latest
$ErrorActionPreference = "Continue"
$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$script:fail = 0
function Pass($m) { Write-Host "  [PASS] $m" -ForegroundColor Green }
function Bad($m)  { Write-Host "  [FAIL] $m" -ForegroundColor Red; $script:fail++ }

Write-Host "=== smoke tests (pwsh) ==="

# 1. skills-lock.json valid JSON
try { Get-Content (Join-Path $RepoRoot 'skills-lock.json') -Raw | ConvertFrom-Json | Out-Null; Pass "skills-lock.json valid JSON" }
catch { Bad "skills-lock.json invalid JSON" }

# 1b. v3 schema: tiers+bundles registries, every entry has tier
$lockObj = Get-Content (Join-Path $RepoRoot 'skills-lock.json') -Raw | ConvertFrom-Json
$v3ok = $true
if ($lockObj.version -ne 3)                        { Bad "skills-lock.json version != 3"; $v3ok = $false }
if (-not $lockObj.PSObject.Properties['tiers'])    { Bad "skills-lock.json missing 'tiers' registry"; $v3ok = $false }
if (-not $lockObj.PSObject.Properties['bundles'])  { Bad "skills-lock.json missing 'bundles' registry"; $v3ok = $false }
foreach ($s in $lockObj.skills)  { if (-not $s.PSObject.Properties['tier']) { Bad "skill '$($s.name)' missing tier"; $v3ok = $false } }
foreach ($a in $lockObj.agents)  { if (-not $a.PSObject.Properties['tier']) { Bad "agent '$($a.source)' missing tier"; $v3ok = $false } }
foreach ($p in $lockObj.plugins) { if (-not $p.PSObject.Properties['tier']) { Bad "plugin '$($p.name)' missing tier"; $v3ok = $false } }
foreach ($m in $lockObj.mcp)     { if (-not $m.PSObject.Properties['tier']) { Bad "mcp '$($m.name)' missing tier"; $v3ok = $false } }
if ($v3ok) { Pass "skills-lock.json v3 schema (tiers/bundles/tier fields)" }

# 2. config CSV headers
if ((Get-Content (Join-Path $RepoRoot 'config\models.csv') -First 1) -eq 'gpu_type,min_gb,primary,fast') { Pass "models.csv header" } else { Bad "models.csv header" }
if ((Get-Content (Join-Path $RepoRoot 'config\tools.csv')  -First 1) -eq 'id,check,scoop,brew')          { Pass "tools.csv header" }  else { Bad "tools.csv header" }

# 3. all PowerShell files parse
foreach ($f in @('setup-windows.ps1', 'runners\install.ps1', 'runners\lib\common.ps1', 'scripts\install-skills.ps1', 'scripts\doctor.ps1', 'tests\smoke.ps1')) {
    $errs = $null
    [System.Management.Automation.Language.Parser]::ParseFile((Join-Path $RepoRoot $f), [ref]$null, [ref]([ref]$errs).Value) | Out-Null
    if ($errs -and $errs.Count) { Bad "parse $f" } else { Pass "parse $f" }
}

# 4. template renders with no leftover tokens
. (Join-Path $RepoRoot 'runners\lib\common.ps1')
$tmplPath = Join-Path $RepoRoot 'templates\CLAUDE.md.tmpl'
$tok = @{}
([regex]::Matches((Get-Content $tmplPath -Raw), '\{\{[A-Z0-9_]+\}\}') | ForEach-Object { $_.Value } | Sort-Object -Unique) | ForEach-Object { $tok[$_] = 'X' }
$r = Expand-Template -TemplatePath $tmplPath -Tokens $tok
if ($r -match '\{\{') { Bad "template leftover tokens" } else { Pass "template renders clean" }

# 5. model selection sanity (RTX 3080)
$m = Get-ModelSelection -GpuType nvidia -CapacityGb 10 -ConfigPath (Join-Path $RepoRoot 'config\models.csv')
if ($m.Primary -eq 'qwen3:8b' -and $m.Fast -eq 'llama3.2:3b') { Pass "model selection nvidia/10GB -> qwen3:8b" } else { Bad "model selection wrong: $($m.Primary) / $($m.Fast)" }

# 6. single-source drift: qwen3:32b only under config/ (exclude tests/ — they reference it on purpose)
$hits = @(Get-ChildItem $RepoRoot -Recurse -Include *.md, *.ps1, *.sh -File -ErrorAction SilentlyContinue |
    Where-Object { $_.FullName -notmatch 'config[\\/]' -and $_.FullName -notmatch 'tests[\\/]' } |
    Select-String -Pattern 'qwen3:32b' -SimpleMatch -ErrorAction SilentlyContinue)
if ($hits.Count) { Bad "qwen3:32b outside config: $((($hits.Path | Sort-Object -Unique) -join ', '))" } else { Pass "no inline model table (single source)" }

Write-Host ""
if ($script:fail -eq 0) { Write-Host "All smoke tests passed." -ForegroundColor Green; exit 0 }
else { Write-Host "$($script:fail) smoke test(s) failed." -ForegroundColor Red; exit 1 }
