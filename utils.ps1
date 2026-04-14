# ═══════════════════════════════════════════════════════════════════════
# Kitly — Utilities & UI Functions
# Beautiful CLI output, config management, and shared helpers
# ═══════════════════════════════════════════════════════════════════════

$script:KitlyVersion = "1.2.0"

# ─── Color Palette ──────────────────────────────────────────────────────
$script:Colors = @{
    Primary   = "Magenta"
    Secondary = "Cyan"
    Success   = "Green"
    Warning   = "Yellow"
    Error     = "Red"
    Muted     = "DarkGray"
    Accent    = "Blue"
    White     = "White"
}

# ─── ASCII Logo ─────────────────────────────────────────────────────────
function Get-KitlyLogo {
    return @(
        "    ██╗  ██╗██╗████████╗██╗  ██╗   ██╗"
        "    ██║ ██╔╝██║╚══██╔══╝██║  ╚██╗ ██╔╝"
        "    █████╔╝ ██║   ██║   ██║   ╚████╔╝ "
        "    ██╔═██╗ ██║   ██║   ██║    ╚██╔╝  "
        "    ██║  ██╗██║   ██║   ███████╗██║   "
        "    ╚═╝  ╚═╝╚═╝   ╚═╝   ╚══════╝╚═╝   "
    )
}

# ─── Minimal Spinner Animation ─────────────────────────────────────────
function Show-KitlySpinner {
    param(
        [string]$Text = "Loading",
        [int]$DurationMs = 800
    )
    $frames = @("⠋","⠙","⠹","⠸","⠼","⠴","⠦","⠧","⠇","⠏")
    $end = (Get-Date).AddMilliseconds($DurationMs)
    $i = 0
    while ((Get-Date) -lt $end) {
        $frame = $frames[$i % $frames.Count]
        Write-Host "`r  $frame $Text" -ForegroundColor $script:Colors.Secondary -NoNewline
        Start-Sleep -Milliseconds 80
        $i++
    }
    Write-Host "`r  ✓ $Text" -ForegroundColor $script:Colors.Success
}

# ─── UI Output Functions ───────────────────────────────────────────────
function Write-KitlyHeader {
    param([string]$Text)
    Write-Host ""
    Write-Host "  ┌─────────────────────────────────────────────────────┐" -ForegroundColor $script:Colors.Muted
    Write-Host "  │  " -ForegroundColor $script:Colors.Muted -NoNewline
    Write-Host "KITLY" -ForegroundColor $script:Colors.Primary -NoNewline
    Write-Host " │ " -ForegroundColor $script:Colors.Muted -NoNewline
    $padded = $Text.PadRight(40)
    Write-Host "$padded" -ForegroundColor $script:Colors.Secondary -NoNewline
    Write-Host "│" -ForegroundColor $script:Colors.Muted
    Write-Host "  └─────────────────────────────────────────────────────┘" -ForegroundColor $script:Colors.Muted
    Write-Host ""
}

function Write-KitlySuccess {
    param([string]$Text)
    Write-Host "  ✓ $Text" -ForegroundColor $script:Colors.Success
}

function Write-KitlyWarning {
    param([string]$Text)
    Write-Host "  ⚠ $Text" -ForegroundColor $script:Colors.Warning
}

function Write-KitlyError {
    param([string]$Text)
    Write-Host "  ✗ $Text" -ForegroundColor $script:Colors.Error
}

function Write-KitlyInfo {
    param([string]$Text)
    Write-Host "  → $Text" -ForegroundColor $script:Colors.Secondary
}

function Write-KitlyMuted {
    param([string]$Text)
    Write-Host "    $Text" -ForegroundColor $script:Colors.Muted
}

function Write-KitlyDivider {
    Write-Host "  ──────────────────────────────────────────────────────" -ForegroundColor $script:Colors.Muted
}

# ─── Beautiful Logo Display ────────────────────────────────────────────
function Show-KitlyBanner {
    param([switch]$Compact)

    Write-Host ""
    $logo = Get-KitlyLogo
    foreach ($line in $logo) {
        Write-Host $line -ForegroundColor $script:Colors.Primary
    }
    Write-Host ""
    if (-not $Compact) {
        Write-Host "    One command. Every tool." -ForegroundColor $script:Colors.Muted
        Write-Host "    Version $script:KitlyVersion" -ForegroundColor $script:Colors.Muted
        Write-Host ""
    }
}

# ─── Config Management ─────────────────────────────────────────────────
function Load-KitlyConfig {
    $configPath = Join-Path $global:PSScriptRoot "packages.json"
    if (Test-Path $configPath) {
        $json = Get-Content $configPath -Raw
        return $json | ConvertFrom-Json
    }
    return $null
}

function Save-KitlyConfig {
    param($Config)
    $configPath = Join-Path $global:PSScriptRoot "packages.json"
    $Config | ConvertTo-Json -Depth 5 | Set-Content $configPath -Encoding UTF8
}

# ─── Documentation Generator ──────────────────────────────────────────
function Generate-PacksMd {
    $config = Load-KitlyConfig
    if (-not $config -or -not $config.bundles) {
        Write-KitlyError "Could not find bundles in packages.json to generate PACKS.md"
        return
    }

    $mdPath = Join-Path $global:PSScriptRoot "PACKS.md"
    $mdContent = @(
        "# 📦 Kitly Packages",
        "",
        "Welcome to the Kitly package bundle registry. Below you'll find the predefined bundles that can be installed with a single command: ``kitly install bundle_name``.",
        ""
    )
    
    foreach ($property in $config.bundles.PSObject.Properties) {
        $name = $property.Name
        $bundle = $property.Value
        $desc = $bundle.description
        $packages = $bundle.packages
        
        $mdContent += "## 📋 $name"
        $mdContent += ""
        if ($desc) {
            $mdContent += "*$desc*"
            $mdContent += ""
        }
        $mdContent += "**Included Apps:**"
        $mdContent += ""
        foreach ($pkg in $packages) {
            $mdContent += '- `' + $pkg + '`'
        }
        $mdContent += ""
        $mdContent += "---"
        $mdContent += ""
    }

    $mdContent | Set-Content $mdPath -Encoding UTF8
    Write-KitlySuccess "Documentation generated at: $mdPath"
}

# ─── Winget Package Installer ─────────────────────────────────────────
function Install-WingetPackage {
    param([string]$PackageId)
    
    Write-KitlyInfo "Installing: $PackageId"

    $arguments = "install --exact --id `"$PackageId`" --silent --accept-package-agreements --accept-source-agreements"
    
    Write-KitlyMuted "winget $arguments"
    
    try {
        $process = Start-Process winget -ArgumentList $arguments -Wait -NoNewWindow -PassThru -ErrorAction Stop
        
        if ($process -and $process.ExitCode -ne $null) {
            if ($process.ExitCode -eq 0) {
                Write-KitlySuccess "Installed '$PackageId' successfully!"
            } elseif ($process.ExitCode -in @(2316632070, -1978335226, -1978335189, 2316632107)) {
                Write-KitlySuccess "'$PackageId' is already installed or up-to-date!"
            } else {
                Write-KitlyWarning "Could not install '$PackageId' (Exit code: $($process.ExitCode)). Skipping."
            }
        } else {
            Write-KitlyWarning "Process exited unexpectedly."
        }
    } catch {
        Write-KitlyWarning "Failed to execute winget for '$PackageId'. Ensure winget is installed."
    }
}

# ─── Bundle Lookup Helper ─────────────────────────────────────────────
function Get-KitlyBundle {
    param(
        [string]$Name,
        $Config
    )
    if ($Config -and $Config.bundles) {
        $match = $Config.bundles.PSObject.Properties | Where-Object { $_.Name -eq $Name }
        if ($match) { return $match }
    }
    return $null
}

# ─── Count Installed Bundles ───────────────────────────────────────────
function Get-KitlyBundleCount {
    $config = Load-KitlyConfig
    if ($config -and $config.bundles) {
        return @($config.bundles.PSObject.Properties).Count
    }
    return 0
}

# ─── Get Total Package Count ───────────────────────────────────────────
function Get-KitlyPackageCount {
    $config = Load-KitlyConfig
    $count = 0
    if ($config -and $config.bundles) {
        foreach ($prop in $config.bundles.PSObject.Properties) {
            $count += @($prop.Value.packages).Count
        }
    }
    return $count
}
