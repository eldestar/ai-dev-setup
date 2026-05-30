function Test-SetupCommand([string]$Name) {
    return $null -ne (Get-Command $Name -ErrorAction SilentlyContinue)
}

function Get-SetupContext {
    param([string]$UserHome)
    $shells = New-Object System.Collections.Generic.List[string]
    foreach ($candidate in @("pwsh", "powershell", "bash", "zsh", "wsl")) {
        if (Test-SetupCommand $candidate) { $shells.Add($candidate) | Out-Null }
    }

    $hasWslInstalled = $false
    if (Test-SetupCommand "wsl") {
        $null = & wsl --status 2>$null
        $hasWslInstalled = ($LASTEXITCODE -eq 0)
    }

    $runtime = [System.Runtime.InteropServices.RuntimeInformation]
    $osPlatform = [System.Runtime.InteropServices.OSPlatform]
    $osName = $runtime::OSDescription
    $arch = $runtime::OSArchitecture.ToString()
    $platform = if ($runtime::IsOSPlatform($osPlatform::Windows)) { "Windows" } elseif ($runtime::IsOSPlatform($osPlatform::OSX)) { "macOS" } else { "Linux" }

    [pscustomobject]@{
        Platform = $platform
        OSName = $osName
        Architecture = $arch
        Shells = @($shells)
        PowerShellEdition = $PSVersionTable.PSEdition
        PowerShellVersion = $PSVersionTable.PSVersion.ToString()
        Home = if ($UserHome) { $UserHome } else { [Environment]::GetFolderPath("UserProfile") }
        HomeOverridden = [bool]$UserHome
        HasNode = (Test-SetupCommand "node")
        HasNpm = (Test-SetupCommand "npm")
        HasClaude = (Test-SetupCommand "claude")
        HasCodex = (Test-SetupCommand "codex")
        HasGit = (Test-SetupCommand "git")
        HasWslInstalled = $hasWslInstalled
    }
}
