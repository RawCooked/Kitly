<#
.SYNOPSIS
    Kitly Installer — One-command setup for Kitly CLI.
.DESCRIPTION
    Downloads and installs Kitly to C:\kitly, creates a .cmd wrapper,
    adds it to the user PATH, and verifies the installation.
    
    Usage:
        iwr https://kitly.app/install.ps1 | iex
    OR:
        curl -L https://kitly.app/install.ps1 | powershell -NoProfile -
#>

$ErrorActionPreference = "Stop"

# ─── Configuration ──────────────────────────────────────────────────────
$KitlyVersion   = "1.0.0"
$InstallDir     = "C:\kitly"
$GithubRepo     = "https://rawcooked.github.io/Kitly/"
$RequiredFiles  = @("kitly.ps1", "utils.ps1", "packages.json")

# ─── UI Helpers ─────────────────────────────────────────────────────────
function Write-Step   { param([string]$Text) Write-Host "  [*] $Text" -ForegroundColor Cyan }
function Write-Done   { param([string]$Text) Write-Host "  [v] $Text" -ForegroundColor Green }
function Write-Fail   { param([string]$Text) Write-Host "  [x] $Text" -ForegroundColor Red }
function Write-Warn   { param([string]$Text) Write-Host "  [!] $Text" -ForegroundColor Yellow }

# ─── Banner ─────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "  ╔══════════════════════════════════════════════╗" -ForegroundColor Magenta
Write-Host "  ║                                              ║" -ForegroundColor Magenta
Write-Host "  ║          KITLY INSTALLER v$KitlyVersion            ║" -ForegroundColor Magenta
Write-Host "  ║     One command. Every tool you need.        ║" -ForegroundColor Magenta
Write-Host "  ║                                              ║" -ForegroundColor Magenta
Write-Host "  ╚══════════════════════════════════════════════╝" -ForegroundColor Magenta
Write-Host ""

# ─── Step 1: Check prerequisites ────────────────────────────────────────
Write-Step "Checking prerequisites..."

# Check if winget is available
try {
    $wingetVersion = winget --version 2>$null
    if ($wingetVersion) {
        Write-Done "Winget found: $wingetVersion"
    } else {
        throw "not found"
    }
} catch {
    Write-Fail "Winget is not installed or not in PATH."
    Write-Host "         Install it from: https://aka.ms/getwinget" -ForegroundColor DarkGray
    exit 1
}

# ─── Step 2: Check for existing installation ────────────────────────────
Write-Step "Checking for existing Kitly installation..."

if (Test-Path (Join-Path $InstallDir "kitly.ps1")) {
    Write-Warn "Kitly is already installed at $InstallDir"
    Write-Host ""
    $response = Read-Host "         Reinstall? (y/N)"
    if ($response -notin @("y", "Y", "yes", "Yes")) {
        Write-Host ""
        Write-Done "Installation cancelled. Existing installation preserved."
        Write-Host ""
        exit 0
    }
    Write-Step "Reinstalling Kitly..."
} else {
    Write-Done "No existing installation found. Proceeding with fresh install."
}

# ─── Step 3: Create installation directory ──────────────────────────────
Write-Step "Creating installation directory: $InstallDir"

try {
    if (-not (Test-Path $InstallDir)) {
        New-Item -ItemType Directory -Path $InstallDir -Force | Out-Null
    }
    Write-Done "Directory ready: $InstallDir"
} catch {
    Write-Fail "Failed to create directory: $InstallDir"
    Write-Host "         Try running as Administrator." -ForegroundColor DarkGray
    exit 1
}

# ─── Step 4: Download Kitly files ───────────────────────────────────────
Write-Step "Downloading Kitly files from GitHub..."

$downloadFailed = $false

foreach ($file in $RequiredFiles) {
    $url = "$GithubRepo/$file"
    $dest = Join-Path $InstallDir $file
    
    Write-Host "       Downloading $file..." -ForegroundColor DarkGray
    
    try {
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        Invoke-WebRequest -Uri $url -OutFile $dest -UseBasicParsing -ErrorAction Stop
        Write-Done "  $file downloaded."
    } catch {
        Write-Fail "  Failed to download: $file"
        Write-Host "         URL: $url" -ForegroundColor DarkGray
        Write-Host "         Error: $($_.Exception.Message)" -ForegroundColor DarkGray
        $downloadFailed = $true
    }
}

if ($downloadFailed) {
    Write-Host ""
    Write-Fail "Some files failed to download. Check your internet connection and the repository URL."
    Write-Host "         Repo: $GithubRepo" -ForegroundColor DarkGray
    exit 1
}

# ─── Step 5: Create kitly.cmd wrapper ───────────────────────────────────
Write-Step "Creating kitly.cmd wrapper..."

$cmdWrapperPath = Join-Path $InstallDir "kitly.cmd"
$cmdContent = @"
@echo off
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0kitly.ps1" %*
"@

try {
    Set-Content -Path $cmdWrapperPath -Value $cmdContent -Encoding ASCII
    Write-Done "kitly.cmd created at: $cmdWrapperPath"
} catch {
    Write-Fail "Failed to create kitly.cmd wrapper."
    exit 1
}

# ─── Step 6: Add to PATH ───────────────────────────────────────────────
Write-Step "Adding Kitly to user PATH..."

try {
    $currentPath = [Environment]::GetEnvironmentVariable("Path", "User")
    
    # Check if already in PATH (case-insensitive, handle trailing backslash)
    $pathEntries = $currentPath -split ";" | ForEach-Object { $_.TrimEnd("\") }
    $installDirNormalized = $InstallDir.TrimEnd("\")
    
    if ($pathEntries -contains $installDirNormalized) {
        Write-Done "Kitly is already in PATH. No changes needed."
    } else {
        # Append to PATH, avoiding duplicate semicolons
        $newPath = if ($currentPath -and $currentPath[-1] -eq ";") {
            "$currentPath$InstallDir"
        } elseif ($currentPath) {
            "$currentPath;$InstallDir"
        } else {
            $InstallDir
        }
        
        [Environment]::SetEnvironmentVariable("Path", $newPath, "User")
        Write-Done "Added $InstallDir to user PATH."
        
        # Also update the current session PATH
        $env:Path = "$env:Path;$InstallDir"
    }
} catch {
    Write-Warn "Could not automatically add to PATH."
    Write-Host "         Manually add '$InstallDir' to your user PATH variable." -ForegroundColor DarkGray
}

# ─── Step 7: Verify installation ───────────────────────────────────────
Write-Step "Verifying installation..."

$allGood = $true
foreach ($file in @("kitly.ps1", "utils.ps1", "packages.json", "kitly.cmd")) {
    $filePath = Join-Path $InstallDir $file
    if (Test-Path $filePath) {
        Write-Host "       [v] $file" -ForegroundColor Green
    } else {
        Write-Host "       [x] $file — MISSING" -ForegroundColor Red
        $allGood = $false
    }
}

# ─── Step 8: Final message ──────────────────────────────────────────────
Write-Host ""

if ($allGood) {
    Write-Host "  ╔══════════════════════════════════════════════╗" -ForegroundColor Green
    Write-Host "  ║                                              ║" -ForegroundColor Green
    Write-Host "  ║   Kitly installed successfully!              ║" -ForegroundColor Green
    Write-Host "  ║                                              ║" -ForegroundColor Green
    Write-Host "  ║   Restart your terminal, then run:           ║" -ForegroundColor Green
    Write-Host "  ║                                              ║" -ForegroundColor Green
    Write-Host "  ║     kitly list                               ║" -ForegroundColor Green
    Write-Host "  ║     kitly install <bundle>                   ║" -ForegroundColor Green
    Write-Host "  ║                                              ║" -ForegroundColor Green
    Write-Host "  ╚══════════════════════════════════════════════╝" -ForegroundColor Green
} else {
    Write-Host "  ╔══════════════════════════════════════════════╗" -ForegroundColor Yellow
    Write-Host "  ║                                              ║" -ForegroundColor Yellow
    Write-Host "  ║   Installation completed with warnings.      ║" -ForegroundColor Yellow
    Write-Host "  ║   Some files may be missing.                 ║" -ForegroundColor Yellow
    Write-Host "  ║   Check $InstallDir for details.      ║" -ForegroundColor Yellow
    Write-Host "  ║                                              ║" -ForegroundColor Yellow
    Write-Host "  ╚══════════════════════════════════════════════╝" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "  Installed to: $InstallDir" -ForegroundColor DarkGray
Write-Host "  Documentation: https://github.com/YOUR_USERNAME/kitly" -ForegroundColor DarkGray
Write-Host ""
