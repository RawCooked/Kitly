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
    $json = $Config | ConvertTo-Json -Depth 5
    # WHY NOT Set-Content -Encoding UTF8?
    # Windows PowerShell 5.1 always prepends a UTF-8 BOM with that encoding,
    # which some strict JSON parsers (e.g. Python's json module) reject outright.
    $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($configPath, $json, $utf8NoBom)
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

# ─── Admin / Elevation Check ────────────────────────────────────────────
function Test-KitlyIsAdmin {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
}

# ─── Reliable "is it actually installed" Check ─────────────────────────
# WHY NOT TRUST WINGET'S EXIT CODE?
# winget wraps a huge range of underlying installer failures (missing
# elevation, cancelled UAC prompt, hash mismatch, etc.) into the SAME
# small set of process exit codes it also uses for "already installed."
# Asking Windows directly via `winget list --id X --exact` (exit 0 = found,
# non-zero = not found) is the only trustworthy signal.
function Test-KitlyPackageInstalled {
    param([string]$PackageId)
    winget list --id "$PackageId" --exact --accept-source-agreements 2>&1 | Out-Null
    return ($LASTEXITCODE -eq 0)
}

# ─── Winget Package Installer ─────────────────────────────────────────
# Returns one of: "installed", "skipped", "failed"
function Install-WingetPackage {
    param([string]$PackageId)

    Write-KitlyInfo "Installing: $PackageId"

    if (Test-KitlyPackageInstalled -PackageId $PackageId) {
        Write-KitlySuccess "'$PackageId' is already installed."
        return "skipped"
    }

    $arguments = "install --exact --id `"$PackageId`" --silent --accept-package-agreements --accept-source-agreements"

    Write-KitlyMuted "winget $arguments"

    try {
        $process = Start-Process winget -ArgumentList $arguments -Wait -NoNewWindow -PassThru -ErrorAction Stop

        if ($process -and $process.ExitCode -eq 0) {
            Write-KitlySuccess "Installed '$PackageId' successfully!"
            return "installed"
        }

        # Exit code was non-zero or missing — don't trust it either way.
        # Ask Windows what's actually true.
        if (Test-KitlyPackageInstalled -PackageId $PackageId) {
            Write-KitlySuccess "Installed '$PackageId' successfully!"
            return "installed"
        }

        $code = if ($process) { $process.ExitCode } else { "unknown" }
        Write-KitlyWarning "Could not install '$PackageId' (winget exit code: $code)."
        if (-not (Test-KitlyIsAdmin)) {
            Write-KitlyMuted "This package may require Administrator privileges. Try re-opening your terminal as Administrator."
        }
        return "failed"
    } catch {
        Write-KitlyWarning "Failed to execute winget for '$PackageId'. Ensure winget is installed."
        return "failed"
    }
}

# ─── Winget Package Updater ────────────────────────────────────────────
# Returns one of: "updated", "failed"
# NOTE: unlike Install-WingetPackage, there's no reliable "already up to
# date" signal from `winget list` (the package IS installed either way),
# so a non-zero exit code here is reported honestly instead of guessed at.
function Update-WingetPackage {
    param([string]$PackageId)

    Write-KitlyInfo "Upgrading $PackageId..."
    $arguments = "upgrade --exact --id `"$PackageId`" --silent --accept-package-agreements --accept-source-agreements"
    Write-KitlyMuted "winget $arguments"

    try {
        $process = Start-Process winget -ArgumentList $arguments -Wait -NoNewWindow -PassThru -ErrorAction Stop
        if ($process -and $process.ExitCode -eq 0) {
            Write-KitlySuccess "'$PackageId' is up to date!"
            return "updated"
        }

        $code = if ($process) { $process.ExitCode } else { "unknown" }
        Write-KitlyWarning "'$PackageId' was not upgraded (winget exit code: $code)."
        Write-KitlyMuted "This can also mean it was already up to date — check with: winget list --id $PackageId"
        if (-not (Test-KitlyIsAdmin)) {
            Write-KitlyMuted "This package may require Administrator privileges."
        }
        return "failed"
    } catch {
        Write-KitlyWarning "Failed to execute winget for '$PackageId'."
        return "failed"
    }
}

# ─── Dry-run: report what install WOULD do, without changing anything ──
function Test-KitlyDryRunInstall {
    param([string]$PackageId)
    if (Test-KitlyPackageInstalled -PackageId $PackageId) {
        Write-KitlySuccess "'$PackageId' is already installed. (dry run — no changes)"
        return "skipped"
    } else {
        Write-KitlyInfo "Would install: $PackageId (dry run — no changes)"
        return "installed"
    }
}

# ─── Bundle Lookup Helper ─────────────────────────────────────────────
function Get-KitlyBundle {
    param(
        [string]$Name,
        $Config
    )

    # DEBUG: Uncomment the line below to verify the full name is received correctly
    # Write-Host "  [DEBUG] Get-KitlyBundle received Name='$Name'" -ForegroundColor DarkYellow

    if ($Config -and $Config.bundles) {
        # Case-insensitive comparison so "personal", "Personal", "PERSONAL" all resolve
        $match = $Config.bundles.PSObject.Properties | Where-Object {
            $_.Name -ieq $Name
        }
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
