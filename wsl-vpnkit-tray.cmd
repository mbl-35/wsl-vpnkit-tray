REM Command Tray Startup to alias on Windows Startup Menue
SET mypath="%~dp0"
powershell -WindowStyle hidden "%mypath:~0,-1%wsl-vpnkit-tray.ps1"
