function Initialize-SetupLog {
    $logs = Join-Path $script:RepoRoot "logs"
    if (-not (Test-Path $logs)) { New-Item -ItemType Directory -Path $logs -Force | Out-Null }
    $stamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $script:LogPath = Join-Path $logs "setup-$stamp.log"
    if (-not $script:DryRun) { New-Item -ItemType File -Path $script:LogPath -Force | Out-Null }
}

function Write-SetupLog([string]$Level, [string]$Message) {
    $line = "[{0}] [{1}] {2}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"), $Level, $Message
    if ($script:LogPath -and -not $script:DryRun) { Add-Content -Path $script:LogPath -Value $line }
    switch ($Level) {
        "OK" { Write-Host $Message -ForegroundColor Green }
        "WARN" { Write-Host $Message -ForegroundColor Yellow }
        "ERROR" { Write-Host $Message -ForegroundColor Red }
        "HEADER" { Write-Host "`n=== $Message ===" -ForegroundColor Cyan }
        default { Write-Host $Message }
    }
}

function Write-SetupHeader([string]$Message) { Write-SetupLog "HEADER" $Message }
function Write-SetupInfo([string]$Message) { Write-SetupLog "INFO" "  $Message" }
function Write-SetupOk([string]$Message) { Write-SetupLog "OK" "  [OK] $Message" }
function Write-SetupWarn([string]$Message) { Write-SetupLog "WARN" "  [!] $Message" }

function Write-SetupError([string]$Message) {
    $script:Errors.Add($Message) | Out-Null
    Write-SetupLog "ERROR" "  [ERROR] $Message"
}

function Confirm-SetupAction([string]$Prompt) {
    if ($script:AssumeYes) { return $true }
    $answer = Read-Host "$Prompt [y/N]"
    return ($answer -match "^[Yy]")
}

function Invoke-SetupCommand([string]$Command, [string[]]$Arguments) {
    $rendered = "$Command $($Arguments -join ' ')".Trim()
    if ($script:DryRun) {
        Write-SetupInfo "DRY RUN: $rendered"
        return @{ Success = $true; Output = "" }
    }
    Write-SetupInfo "Running: $rendered"
    try {
        $output = & $Command @Arguments 2>&1
        $code = $LASTEXITCODE
        if ($script:VerboseLogging -and $output) { $output | ForEach-Object { Write-SetupInfo $_ } }
        return @{ Success = ($code -eq 0); Output = ($output -join "`n") }
    } catch {
        return @{ Success = $false; Output = $_.Exception.Message }
    }
}
