<#
.SYNOPSIS
Kitly - A modern, lightweight package bundle installer for Windows using Winget.
.DESCRIPTION
Kitly allows users to install multiple applications using a single command via predefined or custom bundles.
#>

param(
    [Parameter(Position=0, Mandatory=$true, HelpMessage="Command to execute (install, search, list, describe, create, update, generate-docs)")]
    [ValidateSet("install", "search", "list", "describe", "create", "update", "generate-docs")]
    [string]$Command,

    [Parameter(Position=1, ValueFromRemainingArguments=$true)]
    [string[]]$Arguments
)

$ErrorActionPreference = "Stop"

$global:PSScriptRoot = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition
$utilsPath = Join-Path $global:PSScriptRoot "utils.ps1"

if (-not (Test-Path $utilsPath)) {
    Write-Host " [x] Critical Error: Missing utils.ps1 at $utilsPath" -ForegroundColor Red
    exit 1
}

. $utilsPath

switch ($Command) {
    "install" {
        if ($Arguments.Count -eq 0) {
            Write-KitlyError "Usage: kitly install [bundle_name_or_package_id]"
            exit 1
        }
        $target = $Arguments[0]
        $config = Load-KitlyConfig

        Write-KitlyHeader "Installing: $target"

        $isBundle = $false
        if ($config -and $config.bundles) {
            $bundleMatches = $config.bundles.PSObject.Properties | Where-Object { $_.Name -eq $target }
            if ($bundleMatches) {
                $isBundle = $true
                $packages = $bundleMatches.Value.packages
                Write-KitlyInfo "Found bundle '$target' with $($packages.Count) packages."
                foreach ($pkg in $packages) {
                    Install-WingetPackage -PackageId $pkg
                }
            }
        }
        
        if (-not $isBundle) {
            Write-KitlyInfo "No bundle named '$target' found. Treating as individual package ID..."
            Install-WingetPackage -PackageId $target
        }

        Write-KitlyHeader "Installation Completed!"
    }

    "search" {
        if ($Arguments.Count -eq 0) {
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
                Write-Host " [*] $($property.Name)" -ForegroundColor Cyan
                Write-Host "    $($property.Value.description)" -ForegroundColor DarkGray
            }
            Write-Host "`n Run 'kitly describe [bundle_name]' for more info." -ForegroundColor DarkGray
        } else {
            Write-KitlyWarning "No bundles configured in packages.json."
        }
    }

    "describe" {
        if ($Arguments.Count -eq 0) {
            Write-KitlyError "Usage: kitly describe [bundle_name]"
            exit 1
        }
        $target = $Arguments[0]
        $config = Load-KitlyConfig

        if ($config -and $config.bundles) {
            $bundleMatches = $config.bundles.PSObject.Properties | Where-Object { $_.Name -eq $target }
            if ($bundleMatches) {
                Write-KitlyHeader "Bundle: $target"
                Write-KitlyInfo "Description: $($bundleMatches.Value.description)"
                Write-Host ""
                Write-KitlyInfo "Packages Included:"
                foreach ($pkg in $bundleMatches.Value.packages) {
                    Write-Host "  - $pkg" -ForegroundColor White
                }
                Write-Host "`nTo install, run: kitly install $target`n" -ForegroundColor DarkGray
                exit 0
            }
        }
        
        Write-KitlyWarning "Bundle '$target' not found in packages.json."
        Write-KitlyInfo "You can describe individual winget packages with: winget show $target"
    }

    "create" {
        if ($Arguments.Count -lt 2) {
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

        $bundleMatches = $config.bundles.PSObject.Properties | Where-Object { $_.Name -eq $bundleName }
        if ($bundleMatches) {
            Write-KitlyError "Bundle '$bundleName' already exists. Currently 'kitly update' upgrades installed apps. Manually edit packages.json to modify the bundle."
        } else {
            $newBundle = @{
                description = "Custom bundle created via CLI."
                packages = $appIds
            } | ConvertTo-Json -Depth 3 | ConvertFrom-Json

            $config.bundles | Add-Member -MemberType NoteProperty -Name $bundleName -Value $newBundle
            Save-KitlyConfig -Config $config
            Write-KitlySuccess "Created custom bundle '$bundleName' with $($appIds.Count) packages."
            Generate-PacksMd
        }
    }

    "update" {
        if ($Arguments.Count -eq 0) {
            Write-KitlyError "Usage: kitly update [bundle_name_or_package_id]"
            exit 1
        }
        $target = $Arguments[0]
        $config = Load-KitlyConfig
        
        Write-KitlyHeader "Updating: $target"

        $isBundle = $false
        if ($config -and $config.bundles) {
            $bundleMatches = $config.bundles.PSObject.Properties | Where-Object { $_.Name -eq $target }
            if ($bundleMatches) {
                $isBundle = $true
                $packages = $bundleMatches.Value.packages
                Write-KitlyInfo "Found bundle '$target'. Filtering for upgrades..."
                foreach ($pkg in $packages) {
                    Write-KitlyInfo "Upgrading $pkg..."
                    $arguments = "upgrade --exact --id `"$pkg`" --silent --accept-package-agreements --accept-source-agreements"
                    Write-Host "     Running: winget $arguments" -ForegroundColor DarkGray
                    
                    try {
                        $process = Start-Process winget -ArgumentList $arguments -Wait -NoNewWindow -PassThru -ErrorAction Stop
                        if ($process.ExitCode -eq 0) {
                            Write-KitlySuccess "Upgraded '$pkg' successfully!"
                        } elseif ($process.ExitCode -in @(2316632070, -1978335226, -1978335189, 2316632107)) {
                            Write-KitlySuccess "'$pkg' is already up to date!"
                        } else {
                            Write-KitlyWarning "'$pkg' could not be upgraded or had issues (Exit code: $($process.ExitCode))."
                        }
                    } catch {
                        Write-KitlyWarning "Failed to execute winget for '$pkg'."
                    }
                }
            }
        }
        
        if (-not $isBundle) {
            Write-KitlyInfo "No bundle named '$target' found. Attempting winget upgrade on package ID..."
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
        
        Write-KitlyHeader "Update Completed!"
    }
    
    "generate-docs" {
        Write-KitlyHeader "Generating Documentation"
        Generate-PacksMd
    }
}
