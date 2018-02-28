<#
    .References
    https://github.com/bmrf/tron/
#>

# --- SETUP ---


New-PSDrive -Name HKCR -PSProvider Registry -Root HKEY_CLASSES_ROOT | Out-Null;

# Helper function
    function Publish-RegPath($path) {
        if (!(Test-Path $path)) {
            New-Item -ItemType Directory -Force -Path $path;
        };
    };


# --- SECURITY ---


# Disable Autoplay
    New-ItemProperty -Path "HKCU:Software\Microsoft\Windows\CurrentVersion\Explorer\AutoplayHandlers" -Name "DisableAutoplay" -Value "1" -PropertyType "DWORD" -Force;

# Adjust Screen Saver Password Protected Grace Period (10sec)
    New-ItemProperty -Path "HKLM:Software\Microsoft\Windows NT\CurrentVersion\Winlogon" -Name "ScreenSaverGracePeriod" -Value "10" -PropertyType "DWORD" -Force;


# --- NUISANCE ---


# Disable Tips, Tricks, and Suggestions Notifications
    New-ItemProperty -Path "HKCU:Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "SoftLandingEnabled" -Value "0" -PropertyType "DWORD" -Force;

# Disable Cortana Taskbar Tidbits
    Publish-RegPath "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search";
    New-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" -Name "AllowCortana" -Value "0" -PropertyType "DWORD" -Force;

# Disable Fast Startup
    New-ItemProperty -Path "HKLM:SYSTEM\CurrentControlSet\Control\Session Manager\Power" -Name "HiberbootEnabled" -Value "0" -PropertyType "DWORD" -Force;



# --- PREFERENCE ---


# Set taskbar tray icons to always show (0) or hide (1)
    New-ItemProperty -Path "HKCU:Software\Microsoft\Windows\CurrentVersion\Explorer" -Name "EnableAutoTray" -Value "1" -PropertyType "DWORD" -Force;

# Set taskbar icons icons to small (1) or large (0)
    New-ItemProperty -Path "HKCU:Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "TaskbarSmallIcons" -Value "1" -PropertyType "DWORD" -Force;

# Apply dark app theme
    New-ItemProperty -Path "HKCU:Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name "AppsUseLightTheme" -Value "0" -PropertyType "DWORD" -Force;

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
    );
    
    foreach ($package in $packages) {
        Get-AppxPackage $package | Remove-AppxPackage -ErrorAction SilentlyContinue;
    };

# Remove OneDrive completely
    $OneDrivex86 = "$env:SystemRoot\System32\OneDriveSetup.exe";
    $OneDrivex64 = "$env:SystemRoot\SysWOW64\OneDriveSetup.exe";
 
    Get-Process *OneDrive* | Stop-Process -Force | Out-Null;
    Start-Sleep 3;
 
    if (Test-Path $OneDrivex86)
    {
        & $OneDrivex86 "/uninstall" | Out-Null;
    };
 
    if (Test-Path $OneDrivex64)
    {
        & $OneDrivex64 "/uninstall" | Out-Null;
    };
    Start-Sleep 15; # Uninstallation needs time to let go off the files
 
    # Explorer.exe gets in our way by locking the files for some reason
    taskkill /F /IM explorer.exe | Out-Null;
    
    if (Test-Path "$env:USERPROFILE\OneDrive") { 
        Remove-Item "$env:USERPROFILE\OneDrive" -Recurse -Force | Out-Null 
    };
    
    if (Test-Path "C:\OneDriveTemp") { 
        Remove-Item "C:\OneDriveTemp" -Recurse -Force | Out-Null 
    };
    
    if (Test-Path "$env:LOCALAPPDATA\Microsoft\OneDrive") { 
        Remove-Item "$env:LOCALAPPDATA\Microsoft\OneDrive" -Recurse -Force | Out-Null 
    };
    
    if (Test-Path "$env:PROGRAMDATA\Microsoft OneDrive") { 
        Remove-Item "$env:PROGRAMDATA\Microsoft OneDrive" -Recurse -Force | Out-Null 
    };
    
    Start-Process explorer.exe;

    # Remove OneDrive from the Explorer Side Panel
    if (Test-Path "HKCR:\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}") { 
        Remove-Item -Force -Path "HKCR:\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}" -Recurse | Out-Null 
    };
    
    if (Test-Path "HKCR:\Wow6432Node\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}") { 
        Remove-Item -Force -Path "HKCR:\Wow6432Node\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}" -Recurse | Out-Null
    };

# Folder view options
    # Show Hidden Files
    Set-ItemProperty "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "Hidden" 1;

    # Show file extensions
    Set-ItemProperty "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "HideFileExt" 0;

    # Show drives with no media
    Set-ItemProperty "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "HideDrivesWithNoMedia" 0;
 
# Remove 'Share with' from context menu
    Remove-Item -Path "HKCR:\Directory\Background\shellex\ContextMenuHandlers\Sharing" -Force -Recurse | Out-Null;
    Remove-Item -Path "HKCR:\Directory\shellex\ContextMenuHandlers\Sharing" -Force -Recurse | Out-Null;
    Remove-Item -Path "HKCR:\Directory\shellex\CopyHookHandlers\Sharing" -Force -Recurse | Out-Null;
    Remove-Item -Path "HKCR:\Directory\shellex\PropertySheetHandlers\Sharing" -Force -Recurse | Out-Null;
    Remove-Item -Path "HKCR:\Drive\shellex\ContextMenuHandlers\Sharing" -Force -Recurse | Out-Null;
    Remove-Item -Path "HKCR:\Drive\shellex\PropertySheetHandlers\Sharing" -Force -Recurse | Out-Null;
    Remove-Item -Path "HKCR:\LibraryFolder\background\shellex\ContextMenuHandlers\Sharing" -Force -Recurse | Out-Null;
    Remove-Item -Path "HKCR:\UserLibraryFolder\shellex\ContextMenuHandlers\Sharing" -Force -Recurse | Out-Null;
    New-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name SharingWizardOn -PropertyType DWORD -Value 0 -Force | Out-Null;

# Remove 'Include in library' from context menu
    Remove-Item "HKLM:\SOFTWARE\Classes\Folder\ShellEx\ContextMenuHandlers\Library Location" -Force -Recurse | Out-Null;

# Remove 'Send to' from context menu
    Remove-Item -Path "HKCR:\AllFilesystemObjects\shellex\ContextMenuHandlers\SendTo" -Force -Recurse | Out-Null;

# Disable Services
    $services = @(
        "diagnosticshub.standardcollector.service" # Microsoft (R) Diagnostics Hub Standard Collector Service
        "DiagTrack"                                # Diagnostics Tracking Service
        "dmwappushservice"                         # WAP Push Message Routing Service (see known issues)
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
    );

    foreach ($service in $services) {
        Write-Output "Trying to disable $service";
        Get-Service -Name $service | Set-Service -StartupType Disabled;
    };

# Restart explorer to cause some settings to take affect
    Stop-Process -ProcessName explorer;

