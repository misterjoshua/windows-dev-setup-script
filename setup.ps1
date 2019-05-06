param(
    [switch] $Confirm,
    [switch] $Chat
)

function Invoke-Main {
    Initialize-Setup
    
    Enable-WindowsOptionalFeatures @(
        "Microsoft-Windows-Subsystem-Linux",
        "Microsoft-Hyper-V-All"
    )
    
    if (-not (Get-AppxPackage -Name "CanonicalGroupLimited.UbuntuonWindows")) {
        $ubuntuAppx = ".\Ubuntu.appx"
        if (-not (Test-Path $ubuntuAppx)) {
            Invoke-WebRequest -Uri https://aka.ms/wsl-ubuntu-1804 -OutFile $ubuntuAppx -UseBasicParsing
        }
        Add-AppxPackage $ubuntuAppx
    }
    
    Initialize-Symlinks @(
        @("$home\.ssh", "$configPath\ssh"),
        @("$home\.aws", "$configPath\aws"),
        @("$home\.kube", "$configPath\kube")
    )
    
    Install-Chocolatey
    Install-ChocolateyPackages @(
        # Frameworks
        "golang",
        "jdk11",
        "jdk8",
        "nodejs",
        "php",
        "python",
    
        # Dev tools
        "composer",
        "git",
        "gradle",
        "jetbrainstoolbox",
        "vscode",
    
        # Deployment tools
        "awscli",
        "awstools.powershell",
        "azure-cli",
        "docker-desktop",
        "kubernetes-helm",
        "heroku-cli",
        "packer",
        "terraform",
    
        # Utilities
        "7zip",
        "keepass",
        "openssl.light",
        "procexp",
        "putty",
        "sourcecodepro",
        "vcxsrv",
        "winscp"
    )
    
    $chocoTools = "c:\tools"
    $chocoPhp73 = "$chocoTools\php73"
    Copy-Item -Path "$configPath\php\php73.ini" -Destination "$chocoPhp73\php.ini"
    Copy-Item -Path "$configPath\php\php_xdebug-2.7.1-7.3-vc15-nts-x86_64.dll" -Destination "$chocoPhp73\ext\php_xdebug.dll"
    
    if ($Chat) {
        # Chat programs.
        Install-ChocolateyPackages @(
            "slack",
            "skype"
        )
    }
    
    if (-not (Get-Module -ListAvailable -Name "Az.Accounts")) {
        Write-Host "Installing Azure PowerShell module"
        Install-Module -Name Az -AllowClobber -Scope CurrentUser -Force
    }
    
    # NodeJS setup.
    Write-Host "Setting up nodejs"
    npm install -g yarn create-react-app
}

function Initialize-Setup {
    if ($PSScriptRoot) {
        $script:configPath = Resolve-Path $PSScriptRoot
    } else {
        $script:configPath = Resolve-Path .
    }
}

function Enable-WindowsOptionalFeatures($Features) {
    $neededFeatures = Get-WindowsOptionalFeature -Online | `
        Where-Object { $_.State -eq "Disabled" -and $features.Contains($_.FeatureName) }

    $neededFeatures | ForEach-Object {
        Enable-WindowsOptionalFeature -Online -FeatureName $_.FeatureName
    }
}

function Install-Chocolatey {
    if (-not [bool](choco -? >$null))  {
        Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
    }
}

function Initialize-Symlinks ($Symlinks) {
    $Symlinks | ForEach-Object {
        $sourcePath = $_[0]
        $targetPath = $_[1]
        
        if (-not (Test-Path $targetPath)) {
            Write-Host "Creating targetPath $targetPath"
            New-Item -ItemType Directory -Path $targetPath -Force
        }

        if ($item = Get-Item $sourcePath -ErrorAction SilentlyContinue) {
            Write-Host "Deleting sourcePath $sourcePath"
            $item.Delete()
        }

        Write-Host "Linking $sourcePath => $targetPath"
        New-Item -ItemType SymbolicLink -Path $sourcePath -Target $targetPath -Force
    }
}

function Install-ChocolateyPackages($Packages) {
    $installed = choco list --local-only --id-only -r | ForEach-Object { $_.ToLower() }

    $Packages | ForEach-Object {
        if (-not $installed.Contains($_)) {
            Write-Host "-= Installing choco package $_ =-`n" -ForegroundColor Cyan
            choco install -r -y $_
            Write-Host "`n`n"
        }
        else {
            Write-Host "-= Already installed choco package $_ =-`n" -ForegroundColor Cyan
        }
    }
}

#******************************************************************************
# Script body
# Execution begins here
#******************************************************************************

$ErrorActionPreference = "Stop"
$VerbosePreference = "Continue"

If (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")){
    $arguments = "& '" + $myinvocation.mycommand.definition + "'"
    Start-Process powershell -Verb runAs -ArgumentList $arguments
    exit 0
}

Invoke-Main