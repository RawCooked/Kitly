# 🎨 Kitly Utilities & UI functions

function Write-KitlyHeader {
    param([string]$Text)
    Write-Host "`n ========================================================== " -ForegroundColor DarkGray
    Write-Host " [*] KITLY | $Text " -ForegroundColor Cyan -BackgroundColor DarkBlue
    Write-Host " ========================================================== `n" -ForegroundColor DarkGray
}

function Write-KitlySuccess {
    param([string]$Text)
    Write-Host " [v] $Text" -ForegroundColor Green
}

function Write-KitlyWarning {
    param([string]$Text)
    Write-Host " [!] $Text" -ForegroundColor Yellow
}

function Write-KitlyError {
    param([string]$Text)
    Write-Host " [x] $Text" -ForegroundColor Red
}

function Write-KitlyInfo {
    param([string]$Text)
    Write-Host " [i] $Text" -ForegroundColor Cyan
}

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

function Generate-PacksMd {
    $config = Load-KitlyConfig
    if (-not $config -or -not $config.bundles) {
        Write-KitlyError "Could not find bundles in packages.json to generate PACKS.md"
        return
    }

    $mdPath = Join-Path $global:PSScriptRoot "PACKS.md"
    $mdContent = @(
        "# [*] Kitly Packages",
        "",
        "Welcome to the Kitly package bundle registry. Below you'll find the predefined bundles that can be installed with a single command: `kitly install bundle_name`.",
        ""
    )
    
    foreach ($property in $config.bundles.PSObject.Properties) {
        $name = $property.Name
        $bundle = $property.Value
        $desc = $bundle.description
        $packages = $bundle.packages
        
        $mdContent += "## [*] $name"
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
    Write-KitlySuccess "Documentation successfully generated at: $mdPath"
}

function Install-WingetPackage {
    param([string]$PackageId)
    
    Write-KitlyInfo "Attempting to install: $PackageId"

    $arguments = "install --exact --id `"$PackageId`" --silent --accept-package-agreements --accept-source-agreements"
    
    Write-Host "     Running: winget $arguments" -ForegroundColor DarkGray
    
    try {
        $process = Start-Process winget -ArgumentList $arguments -Wait -NoNewWindow -PassThru -ErrorAction Stop
        
        if ($process -and $process.ExitCode -ne $null) {
            # 0: Success
            # ExitCodes for already installed or upgrade handling in Winget
            if ($process.ExitCode -eq 0) {
                Write-KitlySuccess "Installed '$PackageId' successfully!"
            } elseif ($process.ExitCode -in @(2316632070, -1978335226, -1978335189, 2316632107)) {
                Write-KitlySuccess "'$PackageId' is already installed or up-to-date!"
            } else {
                Write-KitlyWarning "Could not install '$PackageId' or it failed (Exit code: $($process.ExitCode)). Skipping."
            }
        } else {
            Write-KitlyWarning "Process exited unexpectedly or exited without code."
        }
    } catch {
        Write-KitlyWarning "Failed to execute winget for '$PackageId'. Ensure winget is installed and reachable."
    }
}
