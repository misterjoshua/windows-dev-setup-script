$keys = Get-ChildItem "$PSScriptRoot\ssh\keys" -Filter "josh-desktop.ppk" `
    | ForEach-Object { $_.FullName }

foreach ($key in $keys) {
    Write-Host "Importing $key"
    & 'C:\Program Files\PuTTY\pageant.exe' $key
}