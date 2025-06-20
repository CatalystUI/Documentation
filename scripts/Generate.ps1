<#
#####################################
 This file is public domain.
 It does not fall under the same licensing as the rest of the project.
 Feel free to use it in your project.

 - FireController#1847
#####################################
#>

# --- PowerShell 7+ Required ---
if ($PSVersionTable.PSVersion.Major -lt 7) {
    Write-Host "PowerShell 7+ is required. Attempting to relaunch..."

    # Try to find pwsh in PATH
    $pwsh = Get-Command pwsh -ErrorAction SilentlyContinue

    # If not found in PATH, try known locations
    if (-not $pwsh) {
        $knownPaths = @(
            "$env:ProgramFiles\PowerShell\7\pwsh.exe",
            "$env:ProgramFiles(x86)\PowerShell\7\pwsh.exe",
            "$env:LOCALAPPDATA\Microsoft\PowerShell\7\pwsh.exe"
        )
        $pwsh = $knownPaths | Where-Object { Test-Path $_ } | Select-Object -First 1
    } else {
        $pwsh = $pwsh.Source
    }
    if ($pwsh) {
        Write-Host "Relaunching script in PowerShell 7..."
        Start-Process -FilePath $pwsh -ArgumentList "-NoProfile", "-ExecutionPolicy", "Bypass", "-File", "`"$($MyInvocation.MyCommand.Definition)`""
        $failed = $false
    } else {
        Write-Host "PowerShell 7 not found in PATH or common locations."
        Write-Host "Download it here: https://aka.ms/powershell"
        $failed = $true
    }

    Write-Host "`nFor a better script experience, install PowerShell 7+ and ensure your Visual Studio is configured to use it."
    Write-Host "Download PowerShell 7+: https://aka.ms/powershell"
    Write-Host "Configure Visual Studio to use PowerShell 7+: https://stackoverflow.com/a/76045797/6472449`n"

    if ($failed) {
        exit 1
    } else {
        exit 0
    }
}
Write-Host "Using PowerShell version: $($PSVersionTable.PSVersion)"
Write-Host

# List arguments
if ($args -contains "--help" -or
    $args -contains "-h" -or
    $args -contains "/?" -or
    $args -contains "-?" -or
    $args -contains "/help" -or
    $args -contains "/h") {
    Write-Host "Usage: .\Generate.ps1 [--clean] [--serve]"
    Write-Host "Options:"
    Write-Host "  --clean   Clean the build before generating documentation"
    Write-Host "  --serve   Serve the documentation locally on localhost:8080"
    Write-Host
    exit 0
}


# Add .NET tools directory to PATH if not already present
$dotnetTools = Join-Path $env:USERPROFILE ".dotnet\tools"
if (-not ($env:PATH -split ';' | ForEach-Object { $_.Trim() }) -contains $dotnetTools) {
    $env:PATH += ";$dotnetTools"
}

# Build CatalystUI
$orig = Get-Location
Set-Location ../src/CatalystUI
./CreateSignatures.ps1
if ($args -contains "--clean") {
    dotnet clean
}
dotnet restore
dotnet build
Set-Location $orig

# Load DocFX
$fx = Get-Command docfx
if (-not $fx) {
    dotnet tool install -g docfx
    $fx = Get-Command docfx
    if (-not $fx) {
        Write-Host "docfx tool not found. Please install it using:"
        Write-Host "dotnet tool install -g docfx"
        exit 1
    }
}
Write-Host "Using docfx version: $(docfx --version)"
Write-Host

# Generate documentation
if ($args -contains "--serve") {
    docfx ../docs/docfx.json --serve
} else {
    docfx ../docs/docfx.json
}