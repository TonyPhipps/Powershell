<#
    Windows 11 privacy / debloat script

    NOTES
    - Run in an elevated PowerShell session (Administrator) for the HKLM,
      service, firewall, and OneDrive sections.
    - Toggle features on/off in the CONFIG block below. $true = apply,
      $false = skip. Defaults reflect a work-safe setup.

    .References
    https://github.com/bmrf/tron/
    https://www.elevenforum.com/t/disable-show-more-options-context-menu-in-windows-11.1589/
#>


# =====================================================================
#  CONFIG  -  flip these to $true / $false to enable / disable sections
# =====================================================================

    # --- User preference toggles ---
    $ApplyExplorerTweaks      = $true    # show hidden files/extensions/empty drives, force all tray icons visible
    $ApplyTaskbarTweaks       = $true    # hide Task View/Search/Widgets/Chat, left-align, always combine buttons
    $ApplyStartMenuTweaks     = $true    # "More Pins" layout, kill app suggestions/recommendations/tips/autoplay
    $ApplyContextMenuTweak    = $true    # restore the Win10-style "show more options" right-click menu
    $ApplyCursorTweaks        = $true    # enlarge cursor and switch it to the inverted color scheme
    $ApplyMouseTweaks         = $true    # turn off Enhanced Pointer Precision (mouse acceleration)
    $ApplyThemeTweaks         = $true    # switch apps to the dark theme

    # --- Privacy toggles (per-app device access) ---
    $PrivCamera               = $false   # deny apps access to the camera
    $PrivMicrophone           = $false   # deny apps access to the microphone
    $PrivAccountInfo          = $false   # deny apps access to your name/picture/account info
    $PrivCalendar             = $false   # deny apps access to the calendar
    $PrivMessaging            = $true    # deny apps access to SMS/MMS messaging
    $PrivRadio                = $false   # deny apps control of radios (e.g. Bluetooth)
    $PrivSyncWithDevices      = $true    # deny apps syncing with unpaired wireless devices
    $PrivLanguageList         = $true    # stop websites from reading your language list
    $PrivFeedback             = $true    # disable Windows feedback prompts and write feedback
    $PrivInkingTyping         = $true    # stop collection of inking/typing data for personalization
    $PrivLocationSensor       = $true    # turn off the location sensor
    $PrivAdvertisingId        = $true    # disable the advertising ID used for personalized ads
    $PrivRecentItems          = $true    # stop tracking recently opened documents

    # --- System preference toggles (need elevation) ---
    $InstallRsatTools         = $false   # install RSAT admin tools (AD / GPO / DNS)
    $ApplyAnonymousShares     = $true    # allow connecting to anonymous (guest) network shares
    $ApplyScreenSaverGrace    = $true    # set a 10-second grace period before screen-saver password locks
    $ApplySystemPrivacy       = $true    # apply machine-wide personalization / inking privacy policy
    $ApplyFastStartupDisable  = $true    # disable Fast Startup (hiberboot)
    $ApplyPowerPlan           = $true    # enable Ultimate Performance, disable standby/hibernate timeouts
    $ApplyRecentDocsClear     = $true    # clear the recent-documents list on every logoff
    $ApplyTelemetryLevel      = $true    # set diagnostic data to Basic/Required (level 1)
    $ApplyConsumerFeatures    = $true    # disable Windows consumer features (auto-installed promo apps)
    $ApplyDriverUpdateBlock   = $false   # block driver delivery via Windows Update / device metadata
    $ApplyServiceDisable      = $true    # disable the services selected in the block below

    # --- Individual service toggles (only used if $ApplyServiceDisable) ---
    $SvcDiagTrack             = $true    # disable Connected User Experiences and Telemetry
    $SvcGeolocation           = $true    # disable the Geolocation service
    $SvcMapsBroker            = $true    # disable the Downloaded Maps Manager
    $SvcNetTcpPortSharing     = $true    # disable the Net.Tcp Port Sharing service
    $SvcRemoteAccess          = $false   # disable Routing and Remote Access
    $SvcRemoteRegistry        = $false   # disable Remote Registry
    $SvcTrkWks                = $true    # disable Distributed Link Tracking Client
    $SvcBiometric             = $false   # disable the Windows Biometric service (leave off if you use Windows Hello)
    $SvcXbox                  = $true    # disable Xbox services (breaks Game Bar / Store if disabled)

    # --- Software removal toggles ---
    $RemoveApps               = $true    # remove the bundled bloat apps listed later
    $RemoveTeamsConsumer      = $false   # also remove the consumer Teams / Chat app
    $RemoveOneDrive           = $false   # uninstall OneDrive and strip it from Explorer

    # --- Cleanup ---
    $RestartExplorer          = $true    # restart explorer.exe so all changes take effect


# =====================================================================
#  SETUP
# =====================================================================

    # Mount HKEY_CLASSES_ROOT so HKCR: paths work
    if (!(Test-Path "HKCR:")) {
        New-PSDrive -Name HKCR -PSProvider Registry -Root HKEY_CLASSES_ROOT -ErrorAction SilentlyContinue | Out-Null
    }

    function Set-RegProperty($FullPath, $PropertyType, $Value){
        $Path = Split-Path -Path $FullPath
        $Name = Split-Path -Path $FullPath -Leaf

        if (!(Test-Path $Path)) {
            New-Item -ItemType Directory -Path $Path -Force -ErrorAction SilentlyContinue | Out-Null
        }

        New-ItemProperty -Path $Path -Name $Name -Value $Value -PropertyType $PropertyType -Force -ErrorAction SilentlyContinue | Out-Null
    }


# =====================================================================
#  USER PREFERENCE
# =====================================================================

    if ($ApplyExplorerTweaks) {
        # Show Hidden Files
        Set-RegProperty "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced\Hidden" "DWORD" 1
        # Show file extensions
        Set-RegProperty "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced\HideFileExt" "DWORD" 0
        # Show drives with no media
        Set-RegProperty "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced\HideDrivesWithNoMedia" "DWORD" 0
        # Set taskbar tray icons to always show (0) or hide (1)
        Set-RegProperty "HKCU:Software\Microsoft\Windows\CurrentVersion\Explorer\EnableAutoTray" "DWORD" 0
        # Show all tray icons (promote every notify icon)
        Get-ChildItem -Path 'HKCU:\Control Panel\NotifyIconSettings' -ErrorAction SilentlyContinue | ForEach-Object {
            Set-ItemProperty -Path ($_.PSPath) -Name 'IsPromoted' -Value 1 -ErrorAction SilentlyContinue
        }
    }

    if ($ApplyThemeTweaks) {
        # Apply dark app theme
        Set-RegProperty "HKCU:Software\Microsoft\Windows\CurrentVersion\Themes\Personalize\AppsUseLightTheme" "DWORD" 0
    }

    if ($ApplyTaskbarTweaks) {
        # Hide Task View button
        Set-RegProperty "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced\ShowTaskViewButton" "DWORD" 0
        # Hide the taskbar search box (0 = hidden, 1 = icon, 2 = box)
        Set-RegProperty "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search\SearchboxTaskbarMode" "DWORD" 0
        # Disable Widgets button
        Set-RegProperty "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced\TaskbarDa" "DWORD" 0
        # Disable Chat (Teams consumer) button
        Set-RegProperty "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced\TaskbarMn" "DWORD" 0
        # Left-align the taskbar (0 = Left, 1 = Center)
        Set-RegProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced\TaskbarAl" "DWORD" 0
        # Combine taskbar buttons (0 = Always, 1 = When full, 2 = Never)
        Set-RegProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced\TaskbarGlomLevel" "DWORD" 0
    }

    if ($ApplyStartMenuTweaks) {
        # Force Start layout to "More Pins" (0 = Default, 1 = More Pins, 2 = More Recommendations)
        Set-RegProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced\Start_Layout" "DWORD" 1
        # Disable automatically installing suggested apps
        Set-RegProperty "HKCU:Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager\SilentInstalledAppsEnabled" "DWORD" 0
        # Disable "Suggested Apps" in Start Menu
        Set-RegProperty "HKCU:Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager\SystemPaneSuggestionsEnabled" "DWORD" 0
        # Disable Start menu recommendations
        Set-RegProperty "HKCU:Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager\Start_IrisRecommendationEnabled" "DWORD" 0
        # Disable "Show Most Often Used Apps at Top" of Share List
        Set-RegProperty "HKCU:Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced\Start_TrackShareContractMFU" "DWORD" 0
        # Disable Tips, Tricks, and Suggestions Notifications
        Set-RegProperty "HKCU:Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager\SoftLandingEnabled" "DWORD" 0
        # Disable Autoplay
        Set-RegProperty "HKCU:Software\Microsoft\Windows\CurrentVersion\Explorer\AutoplayHandlers\DisableAutoplay" "DWORD" 1
        # Disable "Sync Provider Notifications" within File Explorer
        Set-RegProperty "HKCU:Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced\ShowSyncProviderNotifications" "DWORD" 0
    }

    if ($ApplyContextMenuTweak) {
        # Restore full Win10-style context menu (needs EMPTY default string value)
        Set-RegProperty "HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32\(default)" "STRING" ""
    }

    if ($ApplyCursorTweaks) {
        # Larger, inverted cursor
        Set-RegProperty "HKCU:\Software\Microsoft\Accessibility\CursorSize" "DWORD" 5
        Set-RegProperty "HKCU:\Software\Microsoft\Accessibility\CursorType" "DWORD" 2
        Set-RegProperty "HKCU:\Software\Microsoft\Accessibility\CursorColorType" "DWORD" 2
        Set-RegProperty "HKCU:\Control Panel\Cursors\CursorBaseSize" "DWORD" 64
        Set-RegProperty "HKCU:\Control Panel\Cursors\Scheme Source" "DWORD" 1
    }

    if ($ApplyMouseTweaks) {
        # Disable Enhanced Pointer Precision (auto mouse speed)
        Set-RegProperty "HKCU:\Control Panel\Mouse\MouseSpeed" "STRING" 0
        Set-RegProperty "HKCU:\Control Panel\Mouse\MouseThreshold1" "STRING" 0
        Set-RegProperty "HKCU:\Control Panel\Mouse\MouseThreshold2" "STRING" 0
    }


# =====================================================================
#  PRIVACY
# =====================================================================

    if ($PrivLanguageList) {
        # Let websites access my language list -> off
        Remove-ItemProperty -Path "HKCU:SOFTWARE\Microsoft\Internet Explorer\International" -Name "AcceptLanguage" -ErrorAction SilentlyContinue
        Set-RegProperty "HKCU:Control Panel\International\User Profile\HttpAcceptLanguageOptOut" "DWORD" 1
    }

    if ($PrivCamera) {
        Set-RegProperty "HKCU:SOFTWARE\Microsoft\Windows\CurrentVersion\DeviceAccess\Global\{E5323777-F976-4f5b-9B55-B94699C46E44}\Value" "STRING" "Deny"
    }
    if ($PrivMicrophone) {
        Set-RegProperty "HKCU:SOFTWARE\Microsoft\Windows\CurrentVersion\DeviceAccess\Global\{2EEF81BE-33FA-4800-9670-1CD474972C3F}\Value" "STRING" "Deny"
    }
    if ($PrivAccountInfo) {
        Set-RegProperty "HKCU:SOFTWARE\Microsoft\Windows\CurrentVersion\DeviceAccess\Global\{C1D23ACC-752B-43E5-8448-8D0E519CD6D6}\Value" "STRING" "Deny"
    }
    if ($PrivCalendar) {
        Set-RegProperty "HKCU:SOFTWARE\Microsoft\Windows\CurrentVersion\DeviceAccess\Global\{D89823BA-7180-4B81-B50C-7E471E6121A3}\Value" "STRING" "Deny"
    }
    if ($PrivMessaging) {
        Set-RegProperty "HKCU:SOFTWARE\Microsoft\Windows\CurrentVersion\DeviceAccess\Global\{992AFA70-6F47-4148-B3E9-3003349C1548}\Value" "STRING" "Deny"
    }
    if ($PrivRadio) {
        Set-RegProperty "HKCU:SOFTWARE\Microsoft\Windows\CurrentVersion\DeviceAccess\Global\{A8804298-2D5F-42E3-9531-9C8C39EB29CE}\Value" "STRING" "Deny"
    }
    if ($PrivSyncWithDevices) {
        Set-RegProperty "HKCU:SOFTWARE\Microsoft\Windows\CurrentVersion\DeviceAccess\Global\LooselyCoupled\Value" "STRING" "Deny"
    }

    if ($PrivFeedback) {
        Set-RegProperty "HKCU:SOFTWARE\Microsoft\Siuf\Rules\NumberOfSIUFInPeriod" "DWORD" 0
        Remove-ItemProperty -Path "HKCU:SOFTWARE\Microsoft\Siuf\Rules" -Name "PeriodInNanoSeconds" -ErrorAction SilentlyContinue
        # Disable feedback on write
        Set-RegProperty "HKCU:\SOFTWARE\Microsoft\Input\TIPC\Enable" "DWORD" 0
    }

    if ($PrivInkingTyping) {
        Set-RegProperty "HKCU:\SOFTWARE\Microsoft\InputPersonalization\RestrictImplicitInkCollection" "DWORD" 1
        Set-RegProperty "HKCU:\SOFTWARE\Microsoft\InputPersonalization\RestrictImplicitTextCollection" "DWORD" 1
        Set-RegProperty "HKCU:\SOFTWARE\Microsoft\Personalization\Settings\AcceptedPrivacyPolicy" "DWORD" 0
        Set-RegProperty "HKCU:\SOFTWARE\Microsoft\InputPersonalization\TrainedDataStore\HarvestContacts" "DWORD" 0
    }

    if ($PrivLocationSensor) {
        Set-RegProperty "HKCU:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Sensor\Permissions\{BFA794E4-F964-4FDB-90F6-51056BFE4B44}\SensorPermissionState" "DWORD" 0
    }

    if ($PrivAdvertisingId) {
        Set-RegProperty "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo\Enabled" "DWORD" 0
    }

    if ($PrivRecentItems) {
        Set-RegProperty "HKCU:Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced\Start_TrackDocs" "DWORD" 0
    }


# =====================================================================
#  SYSTEM PREFERENCE  (requires elevation)
# =====================================================================

    if ($InstallRsatTools) {
        Get-WindowsCapability -Online -Name "Rsat.ActiveDirectory.DS-LDS.Tools*" | Add-WindowsCapability -Online
        Get-WindowsCapability -Online -Name "Rsat.GroupPolicy.Management.Tools*"  | Add-WindowsCapability -Online
        Get-WindowsCapability -Online -Name "Rsat.Dns.Tools*"                     | Add-WindowsCapability -Online
    }

    if ($ApplyAnonymousShares) {
        # Allow accessing anonymous shares on other systems
        Set-RegProperty "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanWorkstation\Parameters\AllowInsecureGuestAuth" "DWORD" 1
    }

    if ($ApplyScreenSaverGrace) {
        # Screen saver password grace period (10 sec)
        Set-RegProperty "HKLM:Software\Microsoft\Windows NT\CurrentVersion\Winlogon\ScreenSaverGracePeriod" "DWORD" 10
    }

    if ($ApplySystemPrivacy) {
        Set-RegProperty "HKLM:\SOFTWARE\Microsoft\Personalization\Settings\AcceptedPrivacyPolicy" "DWORD" 0
        Set-RegProperty "HKLM:\SOFTWARE\Microsoft\InputPersonalization\RestrictImplicitTextCollection" "DWORD" 1
        Set-RegProperty "HKLM:\SOFTWARE\Microsoft\InputPersonalization\RestrictImplicitInkCollection" "DWORD" 1
        Set-RegProperty "HKLM:\SOFTWARE\Microsoft\InputPersonalization\TrainedDataStore\HarvestContacts" "DWORD" 0
    }

    if ($ApplyFastStartupDisable) {
        Set-RegProperty "HKLM:SYSTEM\CurrentControlSet\Control\Session Manager\Power\HiberbootEnabled" "DWORD" 0
    }

    if ($ApplyPowerPlan) {
        # Ultimate Performance, no monitor/standby timeout, no hibernation
        powercfg /duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61 2>$null
        $ultimatePlan = powercfg /list | Select-String "Ultimate Performance"
        if ($ultimatePlan) {
            $guid = $ultimatePlan.ToString().Split()[3]
            powercfg /setactive $guid
        }
        powercfg /x -standby-timeout-ac 0
        powercfg /x -standby-timeout-dc 0
        powercfg /h off
        powercfg /setacvalueindex SCHEME_CURRENT SUB_PROCESSOR PROCTHROTTLEMIN 100
        powercfg /setacvalueindex SCHEME_CURRENT SUB_PROCESSOR PROCTHROTTLEMAX 100
        powercfg /setactive SCHEME_CURRENT
    }

    if ($ApplyRecentDocsClear) {
        Set-RegProperty "HKLM:Software\Microsoft\Windows\CurrentVersion\Policies\Explorer\ClearRecentDocsOnExit" "DWORD" 1
    }

    if ($ApplyTelemetryLevel) {
        # Diagnostic data collection -> 1 (Basic/Required)
        Set-RegProperty "HKLM:Software\Microsoft\Windows\CurrentVersion\Policies\DataCollection\AllowTelemetry" "DWORD" 1
    }

    if ($ApplyConsumerFeatures) {
        Set-RegProperty "HKLM:SOFTWARE\Policies\Microsoft\Windows\CloudContent\DisableWindowsConsumerFeatures" "DWORD" 1
    }

    if ($ApplyDriverUpdateBlock) {
        Set-RegProperty "HKLM:SOFTWARE\Microsoft\Windows\CurrentVersion\DriverSearching\SearchOrderConfig" "DWORD" 3
        Set-RegProperty "HKLM:SOFTWARE\Microsoft\Windows\CurrentVersion\Device Metadata\PreventDeviceMetadataFromNetwork" "DWORD" 1
        Set-RegProperty "HKLM:SOFTWARE\Microsoft\Windows\WindowsUpdate\ExcludeWUDriversInQualityUpdate" "DWORD" 1
    }

    if ($ApplyServiceDisable) {
        $services = @()
        if ($SvcDiagTrack)         { $services += "DiagTrack" }
        if ($SvcGeolocation)       { $services += "lfsvc" }
        if ($SvcMapsBroker)        { $services += "MapsBroker" }
        if ($SvcNetTcpPortSharing) { $services += "NetTcpPortSharing" }
        if ($SvcRemoteAccess)      { $services += "RemoteAccess" }
        if ($SvcRemoteRegistry)    { $services += "RemoteRegistry" }
        if ($SvcTrkWks)            { $services += "TrkWks" }
        if ($SvcBiometric)         { $services += "WbioSrvc" }
        if ($SvcXbox)              { $services += "XblAuthManager","XblGameSave","XboxNetApiSvc" }

        foreach ($service in $services) {
            $svc = Get-Service -Name $service -ErrorAction SilentlyContinue
            if ($svc) {
                Write-Output "Disabling $service"
                Set-Service -Name $service -StartupType Disabled -ErrorAction SilentlyContinue
                Stop-Service  -Name $service -Force -ErrorAction SilentlyContinue
            } else {
                Write-Output "Service not present, skipping: $service"
            }
        }
    }


# =====================================================================
#  SOFTWARE / FEATURE REMOVAL
# =====================================================================

    if ($RemoveApps) {
        $packages = @(
            "*Microsoft.BingNews*"
            "*Microsoft.BingWeather*"
            "*Microsoft.WindowsMaps*"
            "*Microsoft.People*"
            "*Microsoft.Xbox*"
            "*Microsoft.XboxGamingOverlay*"
            "*Microsoft.GamingApp*"
            "*Microsoft.ZuneMusic*"
            "*Microsoft.ZuneVideo*"
            "*Microsoft.Clipchamp*"
            "*Microsoft.Todos*"
            "*Microsoft.PowerAutomateDesktop*"
            "*Microsoft.WindowsFeedbackHub*"
            "*Microsoft.MicrosoftSolitaireCollection*"
        )
        if ($RemoveTeamsConsumer) { $packages += "*MicrosoftTeams*" }

        foreach ($package in $packages) {
            Get-AppxPackage $package | Remove-AppxPackage -ErrorAction SilentlyContinue
            Get-AppxPackage -AllUsers $package | Remove-AppxPackage -AllUsers -ErrorAction SilentlyContinue
        }
    }

    if ($RemoveOneDrive) {
        $OneDrivex86 = "$env:SystemRoot\System32\OneDriveSetup.exe"
        $OneDrivex64 = "$env:SystemRoot\SysWOW64\OneDriveSetup.exe"

        Get-Process *OneDrive* -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue | Out-Null
        Start-Sleep 3

        if (Test-Path $OneDrivex86) { & $OneDrivex86 "/uninstall" | Out-Null }
        if (Test-Path $OneDrivex64) { & $OneDrivex64 "/uninstall" | Out-Null }
        Start-Sleep 15

        taskkill /F /IM explorer.exe 2>$null | Out-Null

        Remove-Item "$env:USERPROFILE\OneDrive"            -Force -Recurse -ErrorAction SilentlyContinue | Out-Null
        Remove-Item "C:\OneDriveTemp"                      -Force -Recurse -ErrorAction SilentlyContinue | Out-Null
        Remove-Item "$env:LOCALAPPDATA\Microsoft\OneDrive" -Force -Recurse -ErrorAction SilentlyContinue | Out-Null
        Remove-Item "$env:PROGRAMDATA\Microsoft OneDrive"  -Force -Recurse -ErrorAction SilentlyContinue | Out-Null

        # Remove OneDrive from the Explorer side panel (HKCR: mounted in SETUP)
        Remove-Item -Path "HKCR:\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}" -Force -Recurse -ErrorAction SilentlyContinue | Out-Null
        Remove-Item -Path "HKCR:\Wow6432Node\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}" -Force -Recurse -ErrorAction SilentlyContinue | Out-Null
    }


# =====================================================================
#  CLEANUP
# =====================================================================

    if ($RestartExplorer) {
        Stop-Process -ProcessName explorer -ErrorAction SilentlyContinue
        Start-Process explorer
    }