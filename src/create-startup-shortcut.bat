
powershell -WindowStyle hidden "$s=(New-Object -COM WScript.Shell).CreateShortcut('%userprofile%\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup\Wsl Vpnkit Tray.lnk');$s.TargetPath='%~dp0wsl-vpnkit-tray.cmd';$s.WindowStyle=7;$s.IconLocation='%~dp0wsl-vpnkit-tray.ico';$s.Save()"
