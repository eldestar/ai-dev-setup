function Install-WindowsPrerequisites {
    param([Parameter(Mandatory)]$Context)

    Write-SetupHeader "Windows Prerequisites"

    if (-not $Context.HasGit) {
        if (Test-SetupCommand "winget") {
            if (Confirm-SetupAction "Git was not found. Install Git with winget?") {
                Invoke-SetupCommand "winget" @("install", "--id", "Git.Git", "-e")
            }
        } else {
            $script:ManualSteps.Add("Install Git for Windows, then verify with: git --version") | Out-Null
        }
    } else {
        Write-SetupOk "Git is installed"
    }

    if (-not $Context.HasNode -or -not $Context.HasNpm) {
        if (Test-SetupCommand "winget") {
            if (Confirm-SetupAction "Node.js/npm were not found. Install Node.js LTS with winget?") {
                Invoke-SetupCommand "winget" @("install", "--id", "OpenJS.NodeJS.LTS", "-e")
                $env:PATH = [System.Environment]::GetEnvironmentVariable("PATH", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("PATH", "User")
            }
        } elseif (Test-SetupCommand "scoop") {
            if (Confirm-SetupAction "Node.js/npm were not found. Install nodejs-lts with Scoop?") {
                Invoke-SetupCommand "scoop" @("install", "nodejs-lts")
            }
        } else {
            $script:ManualSteps.Add("Install Node.js LTS, then verify with: node --version and npm --version") | Out-Null
        }
    } else {
        Write-SetupOk "Node.js and npm are installed"
    }

    if (-not $Context.HasWslInstalled) {
        $script:ManualSteps.Add("For the most compatible Codex setup on Windows, install WSL2 and verify with: wsl --status") | Out-Null
    } else {
        Write-SetupOk "WSL2 is installed"
    }
}
