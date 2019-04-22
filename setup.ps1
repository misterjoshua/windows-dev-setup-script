If (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")){
    $arguments = "& '" + $myinvocation.mycommand.definition + "'"
    Start-Process powershell -Verb runAs -ArgumentList $arguments
    Break
}

$configPath = Resolve-Path $PSScriptRoot

Write-Host "Setup script will nuke userdir things linking them to $configPath. Type yes to continue." -ForegroundColor Red
$confirm = Read-Host -Prompt "Type yes to confirm:"
if ($confirm -notlike "yes") {
    Write-Host "Aborted" -ForegroundColor Green
    throw "Aborted."
}

$symlinks = @(
    @("$home\.ssh", "$configPath\ssh"),
    @("$home\.aws", "$configPath\aws")
) | ForEach-Object {
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

Read-Host -Prompt "Press enter to end"