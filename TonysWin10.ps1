<#
    .TODO
    Separate user from admin

    .References
    https://github.com/bmrf/tron/
#>



# --- SETUP ---

    function Set-RegProperty($FullPath, $PropertyType, $Value){
        $Path = Split-Path -Path $FullPath
        $Name = Split-Path -Path $FullPath -Leaf

        if (!(Test-Path $Path)) {
            
            New-Item -ItemType Directory -Path $Path -Force -ErrorAction SilentlyContinue | Out-Null
        }

        New-ItemProperty -Path $Path -Name $Name -Value $Value -PropertyType $PropertyType -Force -ErrorAction SilentlyContinue | Out-Null
        
    }

    
# --- USER PREFERENCE ---

    # Show Hidden Files
    Set-RegProperty "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced\Hidden" "DWORD" 1

    # Show file extensions
    Set-RegProperty "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced\HideFileExt" "DWORD" 0

    # Show drives with no media
    Set-RegProperty "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced\HideDrivesWithNoMedia" "DWORD" 0

    # Set taskbar tray icons to always show (0) or hide (1)
    Set-RegProperty "HKCU:Software\Microsoft\Windows\CurrentVersion\Explorer\EnableAutoTray" "DWORD" 1

    # Set taskbar icons icons to small (1) or large (0)
    Set-RegProperty "HKCU:Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced\TaskbarSmallIcons" "DWORD" 1

    # Apply dark app theme
    Set-RegProperty "HKCU:Software\Microsoft\Windows\CurrentVersion\Themes\Personalize\AppsUseLightTheme" "DWORD" 0
    
    # Disable Tips, Tricks, and Suggestions Notifications
    Set-RegProperty "HKCU:Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager\SoftLandingEnabled" "DWORD" 0

    # Disable Autoplay 
    Set-RegProperty "HKCU:Software\Microsoft\Windows\CurrentVersion\Explorer\AutoplayHandlers\DisableAutoplay" "DWORD" 1



# --- SYSTEM PREFERENCE ---

    New-PSDrive -Name HKCR -PSProvider Registry -Root HKEY_CLASSES_ROOT -ErrorAction SilentlyContinue | Out-Null

    # Adjust Screen Saver Password Protected Grace Period (10sec)
    Set-RegProperty "HKLM:Software\Microsoft\Windows NT\CurrentVersion\Winlogon\ScreenSaverGracePeriod" "DWORD" 10

    # Disable Cortana Taskbar Tidbits
    Set-RegProperty "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search\AllowCortana" "DWORD" 0

    # Disable Fast Startup
    Set-RegProperty "HKLM:SYSTEM\CurrentControlSet\Control\Session Manager\Power\HiberbootEnabled" "DWORD" 0

    # Disable Services
    $services = @(
        "diagnosticshub.standardcollector.service" # Microsoft (R) Diagnostics Hub Standard Collector Service
        "DiagTrack"                                # Diagnostics Tracking Service
        "dmwappushservice"                         # WAP Push Message Routing Service
        "HomeGroupListener"                        # HomeGroup Listener
        "HomeGroupProvider"                        # HomeGroup Provider
        "lfsvc"                                    # Geolocation Service
        "MapsBroker"                               # Downloaded Maps Manager
        "NetTcpPortSharing"                        # Net.Tcp Port Sharing Service
        "RemoteAccess"                             # Routing and Remote Access
        "RemoteRegistry"                           # Remote Registry
        "SharedAccess"                             # Internet Connection Sharing (ICS)
        "TrkWks"                                   # Distributed Link Tracking Client
        "WbioSrvc"                                 # Windows Biometric Service
        "WMPNetworkSvc"                            # Windows Media Player Network Sharing Service
        "XblAuthManager"                           # Xbox Live Auth Manager
        "XblGameSave"                              # Xbox Live Game Save Service
        "XboxNetApiSvc"                            # Xbox Live Networking Service
    )

    foreach ($service in $services) {
        Write-Output "Trying to disable $service"
        Get-Service -Name $service | Set-Service -StartupType Disabled
    }



# --- SOFTWARE/FEATURE REMOVAL ---  

    # Remove apps
    $packages = @(
        "*Advertising*"
        "*WindowsMaps*"
        "*People*"
        "*bing*"
        "*zune*"
        "*xbox*"
        "*twitter*"
        "Microsoft.CommsPhone"
        "Microsoft.ConnectivityStore"
        "Microsoft.Getstarted"
        "Microsoft.Messaging"
        "Microsoft.OneConnect"
    )
    
    foreach ($package in $packages) {
        Get-AppxPackage $package | Remove-AppxPackage -ErrorAction SilentlyContinue
    }

    # Remove OneDrive completely
    $OneDrivex86 = "$env:SystemRoot\System32\OneDriveSetup.exe"
    $OneDrivex64 = "$env:SystemRoot\SysWOW64\OneDriveSetup.exe"
 
    Get-Process *OneDrive* | Stop-Process -Force | Out-Null
    Start-Sleep 3
 
    if (Test-Path $OneDrivex86)
    {
        & $OneDrivex86 "/uninstall" | Out-Null
    }
 
    if (Test-Path $OneDrivex64)
    {
        & $OneDrivex64 "/uninstall" | Out-Null
    }
    Start-Sleep 15 # Uninstallation needs time to let go off the files
 
    taskkill /F /IM explorer.exe | Out-Null     # Explorer.exe gets in our way by locking the files for some reason

    Remove-Item "$env:USERPROFILE\OneDrive" -Force -Recurse -ErrorAction SilentlyContinue | Out-Null
    Remove-Item "C:\OneDriveTemp" -Force -Recurse -ErrorAction SilentlyContinue | Out-Null
    Remove-Item "$env:LOCALAPPDATA\Microsoft\OneDrive" -Force -Recurse -ErrorAction SilentlyContinue | Out-Null
    Remove-Item "$env:PROGRAMDATA\Microsoft OneDrive" -Force -Recurse -ErrorAction SilentlyContinue | Out-Null

    # Remove OneDrive from the Explorer Side Panel
    Remove-Item -Path "HKCR:\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}" -Force -Recurse -ErrorAction SilentlyContinue | Out-Null
    Remove-Item -Path "HKCR:\Wow6432Node\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}" -Force -Recurse -ErrorAction SilentlyContinue | Out-Null 

    Start-Process explorer.exe



# --- CLEANUP ---

# Restart explorer to cause some settings to take affect
    Stop-Process -ProcessName explorer


