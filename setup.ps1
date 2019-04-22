param(
    [switch] $Confirm,
    [switch] $Chat
)

function Initialize-Setup {
    If (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")){
        $arguments = "& '" + $myinvocation.mycommand.definition + "'"
        Start-Process powershell -Verb runAs -ArgumentList $arguments
        exit 0
    }
    
    $script:configPath = Resolve-Path $PSScriptRoot
}

function Get-Confirmation {
    if (-not $Confirm) {
        Write-Host "Setup script will nuke userdir things linking them to $configPath. Type yes to continue." -ForegroundColor Red
        $confirm = Read-Host -Prompt "Type yes to confirm:"
        if ($confirm -notlike "yes") {
            Write-Host "Aborted" -ForegroundColor Green
            throw "Aborted."
        }
    }
}

function Install-Chocolatey {
    Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
}

function Initialize-Symlinks ($Symlinks) {
    $Symlinks | ForEach-Object {
        $sourcePath = $_[0]
        $targetPath = $_[1]
        
        if (-not (Test-Path $targetPath)) {
            Write-Host "Creating targetPath $targetPath"
            New-Item -ItemType Directory $targetPath
        }

        if (-not ($item = Get-Item $sourcePath -ErrorAction SilentlyContinue)) {
            Write-Host "Deleting sourcePath $sourcePath"
            $item.Delete()
        }

        Write-Host "Linking $sourcePath => $targetPath"
        New-Item -ItemType SymbolicLink -Path $sourcePath -Target $targetPath -Force
    }
}

function Install-ChocolateyPackages($Packages) {
    $Packages | ForEach-Object {
        Write-Host "`n`n-= Installing choco package $_ =-`n" -ForegroundColor Cyan
        choco install -r -y $_
    }
}

#******************************************************************************
# Script body
# Execution begins here
#******************************************************************************

$ErrorActionPreference = "Stop"
$VerbosePreference = "Continue"

Initialize-Setup
Install-Chocolatey

Initialize-Symlinks @(
    @("$home\.ssh", "$configPath\ssh"),
    @("$home\.aws", "$configPath\aws")
)

Install-ChocolateyPackages @(
    # Terminals
    "putty.install",
    "winscp.install",

    # Frameworks
    "golang",
    "jdk11",
    "jdk8",
    "nodejs.install",
    "python",

    # Dev tools
    "git",
    "gradle",
    "jetbrainstoolbox",
    "vscode",

    # Deployment tools
    "terraform",
    "packer",
    "heroku-cli",
    "docker-desktop",
    "azure-cli",
    "awstools.powershell",
    "awscli",

    # Utilities
    "7zip.install",
    "keepass.install"
)

Write-Host "Installing Azure PowerShell module"
Install-Module -Name Az -AllowClobber -Scope CurrentUser -Force

if ($Chat) {
    # Chat programs.
    Install-ChocolateyPackages @(
        "slack",
        "skype"
    )
}

refreshenv

# NodeJS setup.
Write-Host "Setting up nodejs"
npm install -g yarn create-react-app