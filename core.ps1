<#
.SYNOPSIS
    Kitly — A modern, lightweight package bundle installer for Windows using Winget.
.DESCRIPTION
    Kitly allows users to install multiple applications using a single command 
    via predefined or custom bundles. Beautiful CLI interface with professional UX.
#>

# ─── Flexible Argument Handling ─────────────────────────────────────────
# We parse $args manually so dash-prefixed flags like -h, --help, -v are
# not intercepted by PowerShell's parameter binder.
$Command = if ($args.Count -gt 0) { [string]$args[0] } else { "" }
$Arguments = if ($args.Count -gt 1) { @($args[1..($args.Count - 1)]) } else { @() }

$ErrorActionPreference = "Stop"

# Force UTF-8 console output so box-drawing characters render correctly
try {
    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
    $OutputEncoding = [System.Text.Encoding]::UTF8
} catch {}

$global:PSScriptRoot = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition
$utilsPath = Join-Path $global:PSScriptRoot "utils.ps1"

if (-not (Test-Path $utilsPath)) {
    Write-Host "  ✗ Critical Error: Missing utils.ps1 at $utilsPath" -ForegroundColor Red
    exit 1
}

. $utilsPath

# ═══════════════════════════════════════════════════════════════════════
# COMMAND: help
# ═══════════════════════════════════════════════════════════════════════
function Show-KitlyHelp {
    Show-KitlyBanner -Compact

    Write-Host "  ┌─────────────────────────────────────────────────────┐" -ForegroundColor DarkGray
    Write-Host "  │                    " -ForegroundColor DarkGray -NoNewline
    Write-Host "COMMANDS" -ForegroundColor Magenta -NoNewline
    Write-Host "                       │" -ForegroundColor DarkGray
    Write-Host "  └─────────────────────────────────────────────────────┘" -ForegroundColor DarkGray
    Write-Host ""

    $commands = @(
        @{ Cmd = "install [bundle|pkg]"; Desc = "Install a bundle or individual package" },
        @{ Cmd = "list"; Desc = "List all available bundles" },
        @{ Cmd = "describe [bundle]"; Desc = "Show details of a specific bundle" },
        @{ Cmd = "search [keyword]"; Desc = "Search Winget for packages" },
        @{ Cmd = "create [name] [pkgs..]"; Desc = "Create a new custom bundle" },
        @{ Cmd = "update [bundle|pkg]"; Desc = "Update a bundle or package" },
        @{ Cmd = "fetch"; Desc = "Show system info and Kitly status" },
        @{ Cmd = "uninstall"; Desc = "Remove Kitly from your system" },
        @{ Cmd = "version"; Desc = "Show current Kitly version" },
        @{ Cmd = "generate-docs"; Desc = "Regenerate PACKS.md documentation" },
        @{ Cmd = "help"; Desc = "Show this help menu" }
    )

    foreach ($c in $commands) {
        $cmdPadded = $c.Cmd.PadRight(26)
        Write-Host "    " -NoNewline
        Write-Host "$cmdPadded" -ForegroundColor Cyan -NoNewline
        Write-Host "$($c.Desc)" -ForegroundColor DarkGray
    }

    Write-Host ""
    Write-Host "  ┌─────────────────────────────────────────────────────┐" -ForegroundColor DarkGray
    Write-Host "  │                    " -ForegroundColor DarkGray -NoNewline
    Write-Host "ALIASES" -ForegroundColor Magenta -NoNewline
    Write-Host "                        │" -ForegroundColor DarkGray
    Write-Host "  └─────────────────────────────────────────────────────┘" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "    desc, d             " -ForegroundColor Cyan -NoNewline
    Write-Host "→ describe" -ForegroundColor DarkGray
    Write-Host "    -h, --help          " -ForegroundColor Cyan -NoNewline
    Write-Host "→ help" -ForegroundColor DarkGray
    Write-Host "    -v, --version       " -ForegroundColor Cyan -NoNewline
    Write-Host "→ version" -ForegroundColor DarkGray
    Write-Host ""

    Write-Host "  ┌─────────────────────────────────────────────────────┐" -ForegroundColor DarkGray
    Write-Host "  │                   " -ForegroundColor DarkGray -NoNewline
    Write-Host "EXAMPLES" -ForegroundColor Magenta -NoNewline
    Write-Host "                       │" -ForegroundColor DarkGray
    Write-Host "  └─────────────────────────────────────────────────────┘" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "    kitly install essential" -ForegroundColor White
    Write-Host "    kitly list" -ForegroundColor White
    Write-Host "    kitly desc dev-frontend" -ForegroundColor White
    Write-Host "    kitly create my-tools Git.Git Python.Python.3.11" -ForegroundColor White
    Write-Host "    kitly fetch" -ForegroundColor White
    Write-Host ""
    Write-KitlyMuted "  https://github.com/RawCooked/Kitly"
    Write-Host ""
}

# ═══════════════════════════════════════════════════════════════════════
# COMMAND: (no args) — Beautiful default interface
# ═══════════════════════════════════════════════════════════════════════
function Show-KitlyDefault {
    Show-KitlyBanner

    # Quick stats
    $bundleCount = Get-KitlyBundleCount
    $pkgCount = Get-KitlyPackageCount

    Write-Host "  ┌─────────────────────────────────────────────────────┐" -ForegroundColor DarkGray
    Write-Host "  │                  " -ForegroundColor DarkGray -NoNewline
    Write-Host "QUICK STATS" -ForegroundColor Magenta -NoNewline
    Write-Host "                      │" -ForegroundColor DarkGray
    Write-Host "  └─────────────────────────────────────────────────────┘" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "    Bundles Available    " -ForegroundColor Cyan -NoNewline
    Write-Host "$bundleCount" -ForegroundColor White
    Write-Host "    Total Packages      " -ForegroundColor Cyan -NoNewline
    Write-Host "$pkgCount" -ForegroundColor White
    Write-Host "    Version             " -ForegroundColor Cyan -NoNewline
    Write-Host "$script:KitlyVersion" -ForegroundColor White
    Write-Host ""

    # Available bundles preview
    $config = Load-KitlyConfig
    if ($config -and $config.bundles) {
        Write-Host "  ┌─────────────────────────────────────────────────────┐" -ForegroundColor DarkGray
        Write-Host "  │               " -ForegroundColor DarkGray -NoNewline
        Write-Host "AVAILABLE BUNDLES" -ForegroundColor Magenta -NoNewline
        Write-Host "                   │" -ForegroundColor DarkGray
        Write-Host "  └─────────────────────────────────────────────────────┘" -ForegroundColor DarkGray
        Write-Host ""
        foreach ($prop in $config.bundles.PSObject.Properties) {
            $name = $prop.Name.PadRight(20)
            $count = @($prop.Value.packages).Count
            Write-Host "    ◆ " -ForegroundColor Magenta -NoNewline
            Write-Host "$name" -ForegroundColor White -NoNewline
            Write-Host "$count packages" -ForegroundColor DarkGray
        }
        Write-Host ""
    }

    Write-Host "  ──────────────────────────────────────────────────────" -ForegroundColor DarkGray
    Write-Host "    Run " -ForegroundColor DarkGray -NoNewline
    Write-Host "kitly help" -ForegroundColor Cyan -NoNewline
    Write-Host " for all commands" -ForegroundColor DarkGray
    Write-Host "    Run " -ForegroundColor DarkGray -NoNewline
    Write-Host "kitly install [bundle]" -ForegroundColor Cyan -NoNewline
    Write-Host " to get started" -ForegroundColor DarkGray
    Write-Host ""
}

# ═══════════════════════════════════════════════════════════════════════
# COMMAND: fetch — NeoFetch-style system report
# ═══════════════════════════════════════════════════════════════════════
function Show-KitlyFetch {
    Show-KitlySpinner -Text "Gathering system information" -DurationMs 600

    Write-Host ""

    $logo = Get-KitlyLogo
    
    # Gather system info
    $os = (Get-CimInstance Win32_OperatingSystem -ErrorAction SilentlyContinue)
    $osName = if ($os) { $os.Caption } else { "Windows" }
    $osVersion = if ($os) { $os.Version } else { "Unknown" }
    $hostname = $env:COMPUTERNAME
    $username = $env:USERNAME
    $psVersion = $PSVersionTable.PSVersion.ToString()
    $uptime = if ($os) {
        $boot = $os.LastBootUpTime
        $span = (Get-Date) - $boot
        "$([math]::Floor($span.TotalDays))d $($span.Hours)h $($span.Minutes)m"
    } else { "Unknown" }
    
    $bundleCount = Get-KitlyBundleCount
    $pkgCount = Get-KitlyPackageCount
    
    # Check winget
    $wingetVer = "Not found"
    try { $wingetVer = (winget --version 2>$null) } catch {}

    # Build info lines to display beside the logo
    $info = @(
        @{ Label = ""; Value = "$username@$hostname"; Color = "Cyan" }
        @{ Label = ""; Value = "─────────────────────────────"; Color = "DarkGray" }
        @{ Label = "OS"; Value = "$osName"; Color = "White" }
        @{ Label = "OS Version"; Value = "$osVersion"; Color = "White" }
        @{ Label = "Uptime"; Value = "$uptime"; Color = "White" }
        @{ Label = "Shell"; Value = "PowerShell $psVersion"; Color = "White" }
        @{ Label = "Winget"; Value = "$wingetVer"; Color = "White" }
        @{ Label = ""; Value = "─────────────────────────────"; Color = "DarkGray" }
        @{ Label = "Kitly Version"; Value = "$script:KitlyVersion"; Color = "Magenta" }
        @{ Label = "Bundles"; Value = "$bundleCount available"; Color = "White" }
        @{ Label = "Packages"; Value = "$pkgCount total across bundles"; Color = "White" }
        @{ Label = "Install Path"; Value = "$global:PSScriptRoot"; Color = "White" }
    )

    # Print logo + info side by side
    $maxLines = [Math]::Max($logo.Count, $info.Count)
    
    for ($i = 0; $i -lt $maxLines; $i++) {
        # Logo part
        if ($i -lt $logo.Count) {
            Write-Host $logo[$i] -ForegroundColor Magenta -NoNewline
        } else {
            Write-Host (" " * 38) -NoNewline
        }

        Write-Host "   " -NoNewline

        # Info part
        if ($i -lt $info.Count) {
            $item = $info[$i]
            if ($item.Label -eq "") {
                Write-Host $item.Value -ForegroundColor $item.Color
            } else {
                Write-Host "$($item.Label)" -ForegroundColor Cyan -NoNewline
                Write-Host ": " -ForegroundColor DarkGray -NoNewline
                Write-Host "$($item.Value)" -ForegroundColor $item.Color
            }
        } else {
            Write-Host ""
        }
    }

    # Color palette bar
    Write-Host ""
    Write-Host "    " -NoNewline
    $palette = @("DarkRed","Red","DarkYellow","Yellow","DarkGreen","Green","DarkCyan","Cyan","DarkBlue","Blue","DarkMagenta","Magenta")
    foreach ($c in $palette) {
        Write-Host "██" -ForegroundColor $c -NoNewline
    }
    Write-Host ""
    Write-Host ""
}

# ═══════════════════════════════════════════════════════════════════════
# COMMAND: version
# ═══════════════════════════════════════════════════════════════════════
function Show-KitlyVersion {
    Write-Host ""
    Write-Host "  Kitly " -ForegroundColor Magenta -NoNewline
    Write-Host "v$script:KitlyVersion" -ForegroundColor White
    Write-Host ""
}

# ═══════════════════════════════════════════════════════════════════════
# COMMAND: uninstall — Clean removal
# ═══════════════════════════════════════════════════════════════════════
function Invoke-KitlyUninstall {
    Show-KitlyBanner -Compact
    Write-KitlyHeader "Uninstalling Kitly"

    Write-Host ""
    Write-Host "  This will:" -ForegroundColor Yellow
    Write-Host "    • Delete core.ps1, utils.ps1, kitly.cmd" -ForegroundColor DarkGray
    Write-Host "    • Remove packages.json and PACKS.md" -ForegroundColor DarkGray
    Write-Host "    • Remove Kitly folder from your PATH" -ForegroundColor DarkGray
    Write-Host ""

    $response = Read-Host "  Are you sure? (y/N)"
    if ($response -notin @("y", "Y", "yes", "Yes")) {
        Write-Host ""
        Write-KitlyInfo "Uninstall cancelled."
        Write-Host ""
        return
    }

    Write-Host ""

    # Step 1: Remove from PATH
    Write-KitlyInfo "Removing Kitly from PATH..."
    try {
        $currentPath = [Environment]::GetEnvironmentVariable("Path", "User")
        if ($currentPath) {
            $pathEntries = $currentPath -split ";" | Where-Object { 
                $_.TrimEnd("\") -ne $global:PSScriptRoot.TrimEnd("\") -and $_ -ne ""
            }
            $newPath = $pathEntries -join ";"
            [Environment]::SetEnvironmentVariable("Path", $newPath, "User")
            Write-KitlySuccess "Removed from PATH."
        }
    } catch {
        Write-KitlyWarning "Could not remove from PATH automatically."
    }

    # Step 2: Delete files
    Write-KitlyInfo "Deleting Kitly files..."
    $filesToDelete = @("core.ps1", "utils.ps1", "kitly.cmd", "packages.json", "PACKS.md", "fix.ps1")
    foreach ($file in $filesToDelete) {
        $path = Join-Path $global:PSScriptRoot $file
        if (Test-Path $path) {
            try {
                Remove-Item $path -Force
                Write-KitlySuccess "Deleted $file"
            } catch {
                Write-KitlyWarning "Could not delete $file"
            }
        }
    }

    # Step 3: Try to remove directory if empty
    try {
        $remaining = Get-ChildItem $global:PSScriptRoot -Force -ErrorAction SilentlyContinue
        if (-not $remaining -or $remaining.Count -eq 0) {
            Remove-Item $global:PSScriptRoot -Force -ErrorAction SilentlyContinue
            Write-KitlySuccess "Removed Kitly directory."
        } else {
            Write-KitlyWarning "Directory not empty, skipping folder removal."
            Write-KitlyMuted "Remaining files in: $global:PSScriptRoot"
        }
    } catch {
        Write-KitlyWarning "Could not remove directory."
    }

    Write-Host ""
    Write-Host "  ┌─────────────────────────────────────────────────────┐" -ForegroundColor Green
    Write-Host "  │                                                     │" -ForegroundColor Green
    Write-Host "  │   Kitly has been uninstalled successfully.          │" -ForegroundColor Green
    Write-Host "  │   Restart your terminal to apply PATH changes.     │" -ForegroundColor Green
    Write-Host "  │                                                     │" -ForegroundColor Green
    Write-Host "  │   Thanks for using Kitly! 💜                       │" -ForegroundColor Green
    Write-Host "  │                                                     │" -ForegroundColor Green
    Write-Host "  └─────────────────────────────────────────────────────┘" -ForegroundColor Green
    Write-Host ""
}

# ═══════════════════════════════════════════════════════════════════════
# COMMAND ROUTING — Main switch with alias support
# ═══════════════════════════════════════════════════════════════════════

# Normalize aliases
$resolvedCommand = switch ($Command) {
    { $_ -in @("help", "-h", "--help") }    { "help" }
    { $_ -in @("desc", "d", "describe") }   { "describe" }
    { $_ -in @("-v", "--version", "version") } { "version" }
    { $_ -in @("", $null) }                 { "default" }
    default                                  { $Command }
}

switch ($resolvedCommand) {
    "default" {
        Show-KitlyDefault
    }

    "help" {
        Show-KitlyHelp
    }

    "version" {
        Show-KitlyVersion
    }

    "fetch" {
        Show-KitlyFetch
    }

    "uninstall" {
        Invoke-KitlyUninstall
    }

    "install" {
        if (-not $Arguments -or $Arguments.Count -eq 0) {
            Write-KitlyError "Usage: kitly install [bundle_name_or_package_id]"
            exit 1
        }
        $target = $Arguments[0]
        $config = Load-KitlyConfig

        Write-KitlyHeader "Installing: $target"

        $bundle = Get-KitlyBundle -Name $target -Config $config
        if ($bundle) {
            $packages = $bundle.Value.packages
            Write-KitlyInfo "Found bundle '$target' with $($packages.Count) packages."
            Write-Host ""
            foreach ($pkg in $packages) {
                Install-WingetPackage -PackageId $pkg
            }
        } else {
            Write-KitlyInfo "No bundle named '$target' found. Treating as individual package ID..."
            Install-WingetPackage -PackageId $target
        }

        Write-Host ""
        Write-KitlyHeader "Installation Completed!"
    }

    "search" {
        if (-not $Arguments -or $Arguments.Count -eq 0) {
            Write-KitlyError "Usage: kitly search [keyword]"
            exit 1
        }
        $keyword = $Arguments[0]
        Write-KitlyHeader "Searching Winget for '$keyword'"
        winget search $keyword
    }

    "list" {
        $config = Load-KitlyConfig
        Write-KitlyHeader "Available Bundles"

        if ($config -and $config.bundles) {
            foreach ($property in $config.bundles.PSObject.Properties) {
                $name = $property.Name.PadRight(20)
                $count = @($property.Value.packages).Count
                Write-Host "    ◆ " -ForegroundColor Magenta -NoNewline
                Write-Host "$name" -ForegroundColor White -NoNewline
                Write-Host "$count packages" -ForegroundColor DarkGray
                Write-KitlyMuted "$($property.Value.description)"
                Write-Host ""
            }
            Write-KitlyDivider
            Write-KitlyMuted "Run 'kitly describe [bundle_name]' for details."
            Write-Host ""
        } else {
            Write-KitlyWarning "No bundles configured in packages.json."
        }
    }

    "describe" {
        if (-not $Arguments -or $Arguments.Count -eq 0) {
            Write-KitlyError "Usage: kitly describe [bundle_name]"
            Write-KitlyMuted "Aliases: kitly desc [name], kitly d [name]"
            exit 1
        }
        $target = $Arguments[0]
        $config = Load-KitlyConfig

        $bundle = Get-KitlyBundle -Name $target -Config $config
        if ($bundle) {
            Write-KitlyHeader "Bundle: $target"
            Write-KitlyInfo "Description: $($bundle.Value.description)"
            Write-Host ""
            
            $packages = $bundle.Value.packages
            Write-Host "    Packages ($($packages.Count)):" -ForegroundColor DarkGray
            Write-Host ""
            foreach ($pkg in $packages) {
                Write-Host "      • " -ForegroundColor Magenta -NoNewline
                Write-Host "$pkg" -ForegroundColor White
            }
            Write-Host ""
            Write-KitlyDivider
            Write-KitlyMuted "Install with: kitly install $target"
            Write-Host ""
        } else {
            Write-KitlyWarning "Bundle '$target' not found in packages.json."
            Write-KitlyInfo "You can try: winget show $target"
        }
    }

    "create" {
        if (-not $Arguments -or $Arguments.Count -lt 2) {
            Write-KitlyError "Usage: kitly create [bundle_name] [appId1] [appId2] ..."
            exit 1
        }
        $bundleName = $Arguments[0]
        $appIds = @($Arguments[1..($Arguments.Count - 1)])
        
        $config = Load-KitlyConfig
        if (-not $config) {
            $config = @{ bundles = @{} } | ConvertTo-Json | ConvertFrom-Json
        }
        if (-not $config.bundles) {
            $config | Add-Member -MemberType NoteProperty -Name "bundles" -Value (@{} | ConvertTo-Json | ConvertFrom-Json)
        }

        $existing = Get-KitlyBundle -Name $bundleName -Config $config
        if ($existing) {
            Write-KitlyError "Bundle '$bundleName' already exists."
            Write-KitlyMuted "Edit packages.json manually to modify it."
        } else {
            $newBundle = @{
                description = "Custom bundle created via CLI."
                packages = $appIds
            } | ConvertTo-Json -Depth 3 | ConvertFrom-Json

            $config.bundles | Add-Member -MemberType NoteProperty -Name $bundleName -Value $newBundle
            Save-KitlyConfig -Config $config
            Write-KitlySuccess "Created bundle '$bundleName' with $($appIds.Count) packages."
            Generate-PacksMd
        }
    }

    "update" {
        if (-not $Arguments -or $Arguments.Count -eq 0) {
            Write-KitlyError "Usage: kitly update [bundle_name_or_package_id]"
            exit 1
        }
        $target = $Arguments[0]
        $config = Load-KitlyConfig
        
        Write-KitlyHeader "Updating: $target"

        $bundle = Get-KitlyBundle -Name $target -Config $config
        if ($bundle) {
            $packages = $bundle.Value.packages
            Write-KitlyInfo "Found bundle '$target'. Updating $($packages.Count) packages..."
            Write-Host ""
            foreach ($pkg in $packages) {
                Write-KitlyInfo "Upgrading $pkg..."
                $arguments = "upgrade --exact --id `"$pkg`" --silent --accept-package-agreements --accept-source-agreements"
                Write-KitlyMuted "winget $arguments"
                
                try {
                    $process = Start-Process winget -ArgumentList $arguments -Wait -NoNewWindow -PassThru -ErrorAction Stop
                    if ($process.ExitCode -eq 0) {
                        Write-KitlySuccess "Upgraded '$pkg' successfully!"
                    } elseif ($process.ExitCode -in @(2316632070, -1978335226, -1978335189, 2316632107)) {
                        Write-KitlySuccess "'$pkg' is already up to date!"
                    } else {
                        Write-KitlyWarning "'$pkg' could not be upgraded (Exit code: $($process.ExitCode))."
                    }
                } catch {
                    Write-KitlyWarning "Failed to execute winget for '$pkg'."
                }
            }
        } else {
            Write-KitlyInfo "No bundle named '$target'. Attempting winget upgrade..."
            $arguments = "upgrade --exact --id `"$target`" --silent --accept-package-agreements --accept-source-agreements"
            
            try {
                $process = Start-Process winget -ArgumentList $arguments -Wait -NoNewWindow -PassThru -ErrorAction Stop
                if ($process.ExitCode -eq 0) {
                    Write-KitlySuccess "Upgraded '$target' successfully!"
                } elseif ($process.ExitCode -in @(2316632070, -1978335226, -1978335189, 2316632107)) {
                    Write-KitlySuccess "'$target' is already up to date!"
                } else {
                    Write-KitlyWarning "'$target' could not be upgraded (Exit code: $($process.ExitCode))."
                }
            } catch {
                Write-KitlyWarning "Failed to execute winget for '$target'."
            }
        }
        
        Write-Host ""
        Write-KitlyHeader "Update Completed!"
    }
    
    "generate-docs" {
        Write-KitlyHeader "Generating Documentation"
        Generate-PacksMd
    }

    default {
        Write-KitlyError "Unknown command: '$Command'"
        Write-KitlyMuted "Run 'kitly help' for available commands."
        Write-Host ""
        exit 1
    }
}
