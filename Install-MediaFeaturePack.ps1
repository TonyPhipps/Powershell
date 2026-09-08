DISM /online /add-capability /capabilityname:Media.WindowsMediaPlayer~~~~0.0.12.0 

Set-Service -Name wuauserv -StartupType Automatic
net stop wuauserv
net stop trustedinstaller
net start trustedinstaller
net start wuauserv
dism.exe /online /cleanup-image /revertpendingactions
sfc /scannow
dism.exe /online /cleanup-image /restorehealth
dism.exe /Online /Cleanup-Image /RestoreHealth /Source:WIM:D:\Sources\install.wim:1 /LimitAccess

DISM /Online /Add-Capability /CapabilityName:Media.MediaFeaturePack~~~~0.0.1.0
