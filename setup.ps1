param(
    [switch] $Confirm
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
        
        if (Test-Path $targetPath) {
            if (-not ($item = Get-Item $sourcePath -ErrorAction SilentlyContinue)) {
                Write-Host "Deleting sourcePath $sourcePath"
                $item.Delete()
            }

            Write-Host "Linking $sourcePath => $targetPath"
            New-Item -ItemType SymbolicLink -Path $sourcePath -Target $targetPath -Force
        }
    }
}

function Install-ChocolateyPackages($Packages) {
    $Packages | ForEach-Object {
        Write-Host "Installing choco package $_" -ForegroundColor Cyan
        choco install -y $_
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
    "putty.install", "winscp.install",
    "jdk11", "jdk8","nodejs.install","python",
    "gradle","vscode", "jetbrainstoolbox",
    "heroku-cli","awscli","awstools.powershell","azure-cli",
    "docker-desktop",
    "packer","terraform"
)

Install-Module -Name Az -AllowClobber -Scope CurrentUser -Force

# Chat programs.
# Install-ChocolateyPackages @(
#     "slack","skype","telegram.install","discord.install"
# )

refreshenv

npm install -g yarn