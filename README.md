This script sets up a Windows Dev environment that fits my usual work. I hope you find it useful.

To install it, paste the following into a privileged powershell:

```
Set-ExecutionPolicy Bypass -Scope Process -Force;
iex ((New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/misterjoshua/windows-dev-setup-script/master/setup.ps1'));

```