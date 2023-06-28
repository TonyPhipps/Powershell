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
    Set-RegProperty "HKCU:Software\Microsoft\Windows\CurrentVersion\Explorer\EnableAutoTray" "DWORD" 0

    # Set taskbar icons icons to small (1) or large (0)
    Set-RegProperty "HKCU:Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced\TaskbarSmallIcons" "DWORD" 1

    # Apply dark app theme
    Set-RegProperty "HKCU:Software\Microsoft\Windows\CurrentVersion\Themes\Personalize\AppsUseLightTheme" "DWORD" 0
    
    # Disable Tips, Tricks, and Suggestions Notifications
    Set-RegProperty "HKCU:Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager\SoftLandingEnabled" "DWORD" 0

    # Disable Autoplay 
    Set-RegProperty "HKCU:Software\Microsoft\Windows\CurrentVersion\Explorer\AutoplayHandlers\DisableAutoplay" "DWORD" 1
    
    # Disable Taskbar Search
    Set-RegProperty "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search\ShowTaskViewButton" "DWORD" 0
    Set-RegProperty "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search\SearchboxTaskbarMode" "DWORD" 1

    # Privacy -> General -> let websites provide locally relevant content by accessing my language list
    Remove-ItemProperty -Path "HKCU:SOFTWARE\Microsoft\Internet Explorer\International" -Name "AcceptLanguage" -ErrorAction SilentlyContinue
    Set-RegProperty "HKCU:Control Panel\International\User Profile\HttpAcceptLanguageOptOut" "DWORD" 1

    # Privacy -> General -> turn on smartscreen filter to check web content that windows store apps use
    Set-RegProperty "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppHost\EnableWebContentEvaluation" "DWORD" 0

    # Privacy -> Camera -> let apps use my camera
    Set-RegProperty "HKCU:SOFTWARE\Microsoft\Windows\CurrentVersion\DeviceAccess\Global\{E5323777-F976-4f5b-9B55-B94699C46E44}\Value" "STRING" "Deny"

    # Privacy -> Microphone -> let apps use my microphone
    Set-RegProperty "HKCU:SOFTWARE\Microsoft\Windows\CurrentVersion\DeviceAccess\Global\{2EEF81BE-33FA-4800-9670-1CD474972C3F}\Value" "STRING" "Deny"

    # Privacy -> Account info -> let apps access my name, picture and other account info
    Set-RegProperty "HKCU:SOFTWARE\Microsoft\Windows\CurrentVersion\DeviceAccess\Global\{C1D23ACC-752B-43E5-8448-8D0E519CD6D6}\Value" "STRING" "Deny"

    # Privacy -> Calendar -> let apps access my calendar
    Set-RegProperty "HKCU:SOFTWARE\Microsoft\Windows\CurrentVersion\DeviceAccess\Global\{D89823BA-7180-4B81-B50C-7E471E6121A3}\Value" "STRING" "Deny"

    # Privacy -> Messaging -> let apps read or send sms and text messages
    Set-RegProperty "HKCU:SOFTWARE\Microsoft\Windows\CurrentVersion\DeviceAccess\Global\{992AFA70-6F47-4148-B3E9-3003349C1548}\Value" "STRING" "Deny"

    # Privacy -> Radio -> let apps control radios
    Set-RegProperty "HKCU:SOFTWARE\Microsoft\Windows\CurrentVersion\DeviceAccess\Global\{A8804298-2D5F-42E3-9531-9C8C39EB29CE}\Value" "STRING" "Deny"

    # Privacy -> Other devices -> sync with devices
    Set-RegProperty "HKCU:SOFTWARE\Microsoft\Windows\CurrentVersion\DeviceAccess\Global\LooselyCoupled\Value" "STRING" "Deny"

    # Privacy -> Feedback & Diagnostics -> feedback frequency
    Set-RegProperty "HKCU:SOFTWARE\Microsoft\Siuf\Rules\NumberOfSIUFInPeriod" "DWORD" 0
    Remove-ItemProperty -Path "HKCU:SOFTWARE\Microsoft\Siuf\Rules" -Name "PeriodInNanoSeconds" -ErrorAction SilentlyContinue

    # Disable Automatically Installing Suggested Apps
    Set-RegProperty "HKCU:Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager\SilentInstalledAppsEnabled" "DWORD" 0

    # Disable "Suggested Apps" in Start Menu
    Set-RegProperty "HKCU:Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager\SystemPaneSuggestionsEnabled" "DWORD" 0

    # Disable "Show Most Often Used Apps at Top" of Share List
    Set-RegProperty "HKCU:Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced\Start_TrackShareContractMFU" "DWORD" 0

    # Disable "Live Tile Notifications" in Start Menu
    Set-RegProperty "HKCU:Software\Microsoft\Windows\CurrentVersion\PushNotifications\NoTileApplicationNotification" "DWORD" 1

    # Disable "Sync Provider Notifications" within File Explorer
    Set-RegProperty "HKCU:Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced\ShowSyncProviderNotifications" "DWORD" 0

    # Disable location sensor
    Set-RegProperty "HKCU:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Sensor\Permissions\{BFA794E4-F964-4FDB-90F6-51056BFE4B44}\SensorPermissionState" "DWORD" 0

    # Restrict inking and typing settings
    Set-RegProperty "HKCU:\SOFTWARE\Microsoft\InputPersonalization\RestrictImplicitInkCollection" "DWORD" 1
    Set-RegProperty "HKCU:\SOFTWARE\Microsoft\InputPersonalization\RestrictImplicitTextCollection" "DWORD" 1

    # Set privacy policy accepted state to 0
    Set-RegProperty "HKCU:\SOFTWARE\Microsoft\Personalization\Settings\AcceptedPrivacyPolicy" "DWORD" 0

    # Do not scan contact informations
    Set-RegProperty "HKCU:\SOFTWARE\Microsoft\InputPersonalization\TrainedDataStore\HarvestContacts" "DWORD" 0

    # Disable synchronisation of settings
    Set-RegProperty "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\SettingSync\BackupPolicy" "BINARY" 0x3c
    Set-RegProperty "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\SettingSync\DeviceMetadataUploaded" "DWORD" 0
    Set-RegProperty "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\SettingSync\PriorLogons" "DWORD" 1
    $groups = @(
        "Accessibility"
        "AppSync"
        "BrowserSettings"
        "Credentials"
        "DesktopTheme"
        "Language"
        "PackageState"
        "Personalization"
        "StartLayout"
        "Windows"
    );

    foreach ($group in $groups) {
        Set-RegProperty "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\SettingSync\Groups\$group\Enabled" "DWORD" 0
    }

    # Disable access to Speechlist
    Set-RegProperty  "HKCU:\Control Panel\International\User Profile\HttpAcceptLanguageOptOut" "DWORD" 1
    Set-RegProperty "HKCU:\Printers\Defaults\NetID" "STRING" "{00000000-0000-0000-0000-000000000000}"
    
    # Disable Feedback on write
    Set-RegProperty "HKCU:\SOFTWARE\Microsoft\Input\TIPC\Enable" "DWORD" 0
    
    # Privacy: Let apps use my advertising ID: Disable
    Set-RegProperty "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo\Enabled" "DWORD" 0
    
    # Privacy: SmartScreen Filter for Store Apps: Disable
    Set-RegProperty "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppHost\EnableWebContentEvaluation" "DWORD" 0



# --- SYSTEM PREFERENCE ---

    #New-PSDrive -Name HKCR -PSProvider Registry -Root HKEY_CLASSES_ROOT -ErrorAction SilentlyContinue | Out-Null

    # Allow accessing anonymous shares on other systems
    Set-RegProperty "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanWorkstation\Parameters\AllowInsecureGuestAuth" "DWORD" 1
    
    # Adjust Screen Saver Password Protected Grace Period (10sec)
    Set-RegProperty "HKLM:Software\Microsoft\Windows NT\CurrentVersion\Winlogon\ScreenSaverGracePeriod" "DWORD" 10

    # Disable Cortana Taskbar Tidbits
    Set-RegProperty "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search\AllowCortana" "DWORD" 0
    Set-RegProperty "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search\AllowCortana" "DWORD" 0
    Set-RegProperty "HKLM:\SOFTWARE\Microsoft\Personalization\Settings\AcceptedPrivacyPolicy" "DWORD" 0
    Set-RegProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\SettingSync\Groups\Language\Enabled" "DWORD" 0
    Set-RegProperty "HKLM:\SOFTWARE\Microsoft\InputPersonalization\RestrictImplicitTextCollection" "DWORD" 1
    Set-RegProperty "HKLM:\SOFTWARE\Microsoft\InputPersonalization\RestrictImplicitInkCollection" "DWORD" 1
    Set-RegProperty "HKLM:\SOFTWARE\Microsoft\InputPersonalization\TrainedDataStore\HarvestContacts" "DWORD" 0

    # Disable Fast Startup
    Set-RegProperty "HKLM:SYSTEM\CurrentControlSet\Control\Session Manager\Power\HiberbootEnabled" "DWORD" 0

    # Clear Recent Docs on Exit
    Set-RegProperty "HKLM:Software\Microsoft\Windows\CurrentVersion\Policies\Explorer\ClearRecentDocsOnExit" "DWORD" 1

    # Disable 'Recent Items' and 'Frequent Places'
    Set-RegProperty "HKCU:Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced\Start_TrackDocs" "DWORD" 0

    # Clear Recent Docs on Exit
    Set-RegProperty "HKLM:Software\Microsoft\Windows\CurrentVersion\Policies\Explorer\ClearRecentDocsOnExit" "DWORD" 1

    # Change "Diagnostic and Usage Data Collection Settings" to 1 (Basic)
    Set-RegProperty "HKLM:Software\Microsoft\Windows\CurrentVersion\Policies\DataCollection\AllowTelemetry" "DWORD" 1

    # Disable Services
    $services = @(
        "diagnosticshub.standardcollector.service" # Microsoft (R) Diagnostics Hub Standard Collector Service
        "DiagTrack"                                # Diagnostics Tracking Service
        "dmwappushservice"                         # WAP Push Message Routing Service
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

    # Do not share wifi networks
    Set-RegProperty "HKLM:\SOFTWARE\Microsoft\WcmSvc\wifinetworkmanager\features\WiFiSenseCredShared" "DWORD" 0
    Set-RegProperty "HKLM:\SOFTWARE\Microsoft\WcmSvc\wifinetworkmanager\features\WiFiSenseOpen" "DWORD" 0

     # Add telemetry ips to firewall
    $ips = @(
        "134.170.30.202"
        "137.116.81.24"
        "157.56.106.189"
        "184.86.53.99"
        "2.22.61.43"
        "2.22.61.66"
        "204.79.197.200"
        "23.218.212.69"
        "65.39.117.230"
        "65.52.108.33"
        "65.55.108.23"
        "64.4.54.254"
    );

    Remove-NetFirewallRule -DisplayName "Block Telemetry IPs";
    New-NetFirewallRule -DisplayName "Block Telemetry IPs" -Direction Outbound -Action Block -RemoteAddress ([string[]]$ips);


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



# --- CLEANUP ---

# Restart explorer to cause some settings to take affect
Stop-Process -ProcessName explorer
Start-Process explorer
