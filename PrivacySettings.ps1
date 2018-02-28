# --- PRIVACY ---

# Privacy -> General -> let websites provide locally relevant content by accessing my language list
    Remove-ItemProperty -Path "HKCU:SOFTWARE\Microsoft\Internet Explorer\International" -Name "AcceptLanguage";
    New-ItemProperty -Force -Path "HKCU:Control Panel\International\User Profile" -Name "HttpAcceptLanguageOptOut" -Value 1;

# Privacy -> General -> turn on smartscreen filter to check web content that windows store apps use
    New-ItemProperty -Force -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppHost\" -Name "EnableWebContentEvaluation" -Value 0;

# Privacy -> Camera -> let apps use my camera
    New-ItemProperty -Force -Path "HKCU:SOFTWARE\Microsoft\Windows\CurrentVersion\DeviceAccess\Global\{E5323777-F976-4f5b-9B55-B94699C46E44}" -Name "Value" -Value "Deny";

# Privacy -> Microphone -> let apps use my microphone
    New-ItemProperty -Force -Path "HKCU:SOFTWARE\Microsoft\Windows\CurrentVersion\DeviceAccess\Global\{2EEF81BE-33FA-4800-9670-1CD474972C3F}\" -Name "Value" -Value "Deny";

# Privacy -> Account info -> let apps access my name, picture and other account info
    New-ItemProperty -Force -Path "HKCU:SOFTWARE\Microsoft\Windows\CurrentVersion\DeviceAccess\Global\{C1D23ACC-752B-43E5-8448-8D0E519CD6D6}\" -Name "Value" -Value "Deny";

# Privacy -> Calendar -> let apps access my calendar
    New-ItemProperty -Force -Path "HKCU:SOFTWARE\Microsoft\Windows\CurrentVersion\DeviceAccess\Global\{D89823BA-7180-4B81-B50C-7E471E6121A3}\" -Name "Value" -Value "Deny";

# Privacy -> Messaging -> let apps read or send sms and text messages
    New-ItemProperty -Force -Path "HKCU:SOFTWARE\Microsoft\Windows\CurrentVersion\DeviceAccess\Global\{992AFA70-6F47-4148-B3E9-3003349C1548}\" -Name "Value" -Value "Deny";

# Privacy -> Radio -> let apps control radios
    New-ItemProperty -Force -Path "HKCU:SOFTWARE\Microsoft\Windows\CurrentVersion\DeviceAccess\Global\{A8804298-2D5F-42E3-9531-9C8C39EB29CE}\" -Name "Value" -Value "Deny";

# Privacy -> Other devices -> sync with devices
    New-ItemProperty -Force -Path "HKCU:SOFTWARE\Microsoft\Windows\CurrentVersion\DeviceAccess\Global\LooselyCoupled\" -Name "Value" -Value "Deny";

# Privacy -> Feedback & Diagnostics -> feedback frequency
    Publish-RegPath "HKCU:SOFTWARE\Microsoft\Siuf\Rules";
    New-ItemProperty -Force -Path "HKCU:SOFTWARE\Microsoft\Siuf\Rules" -Name "NumberOfSIUFInPeriod" -Value 0;
    Remove-ItemProperty -Path "HKCU:SOFTWARE\Microsoft\Siuf\Rules" -Name "PeriodInNanoSeconds";

# Remove advertisements/malware/adware/tracking/popup sites
    Invoke-WebRequest http://someonewhocares.org/hosts/hosts -UseBasicParsing | Select-Object -ExpandProperty Content | out-file "C:\Windows\System32\drivers\etc\hosts";

# Disable Automatically Installing Suggested Apps
    New-ItemProperty -Force -Path "HKCU:Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "SilentInstalledAppsEnabled" -Value "0" -PropertyType "DWORD";

# Disable "Suggested Apps" in Start Menu
    New-ItemProperty -Force -Path "HKCU:Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "SystemPaneSuggestionsEnabled" -Value "0" -PropertyType "DWORD";

# Disable "Show Most Often Used Apps at Top" of Share List
    New-ItemProperty -Force -Path "HKCU:Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "Start_TrackShareContractMFU" -Value "0" -PropertyType "DWORD";

# Disable "Live Tile Notifications" in Start Menu
    New-ItemProperty -Force -Path "HKCU:Software\Microsoft\Windows\CurrentVersion\PushNotifications" -Name "NoTileApplicationNotification" -Value "1" -PropertyType "DWORD";

# Disable "Sync Provider Notifications" within File Explorer
    New-ItemProperty -Force -Path "HKCU:Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "ShowSyncProviderNotifications" -Value "0" -PropertyType "DWORD";

# Change "Diagnostic and Usage Data Collection Settings" to 1 (Basic)
    Publish-RegPath "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection";
    New-ItemProperty -Force -Path "HKLM:Software\Microsoft\Windows\CurrentVersion\Policies\DataCollection" -Name "AllowTelemetry" -Value "1" -PropertyType "DWORD";

# Clear Page File at each shutdown
    New-ItemProperty -Force -Path "HKLM:SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" -Name "ClearPageFileAtShutdown" -Value "1" -PropertyType "DWORD";

# Remove "Most Used Apps" on Start Menu
    New-ItemProperty -Force -Path "HKCU:Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "Start_TrackProgs" -Value "0" -PropertyType "DWORD";

# Disable "Show Frequent Folders" in File Explorer
    New-ItemProperty -Force -Path "HKCU:Software\Microsoft\Windows\CurrentVersion\Explorer" -Name "ShowFrequent" -Value "0" -PropertyType "DWORD";

# Disable and clear 'Recent Items' and 'Frequent Places'
    $appdata = [Environment]::GetFolderPath('ApplicationData')
    Remove-item $appdata\Microsoft\Windows\Recent\* -Recurse
    New-ItemProperty -Force -Path "HKCU:Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "Start_TrackDocs" -Value "0" -PropertyType "DWORD";

# Clear Recent Docs on Exit
    New-ItemProperty -Force -Path "HKLM:Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" -Name "ClearRecentDocsOnExit" -Value "1" -PropertyType "DWORD";


# Helper function
    function Publish-RegPath($path) {
        if (!(Test-Path $path)) {
            #Write-Host "-- Creating full path to: " $path -ForegroundColor White -BackgroundColor DarkGreen
            New-Item -ItemType Directory  -Path $path;
        }
    }


    New-ItemProperty -Force "HKCU:\Control Panel\International\User Profile" "HttpAcceptLanguageOptOut" -Value 1;

# Disable location sensor
    Publish-RegPath "HKCU:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Sensor\Permissions\{BFA794E4-F964-4FDB-90F6-51056BFE4B44}";
    New-ItemProperty -Force "HKCU:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Sensor\Permissions\{BFA794E4-F964-4FDB-90F6-51056BFE4B44}" "SensorPermissionState" -Value 0;

# Do not share wifi networks
    $user = New-Object System.Security.Principal.NTAccount($env:UserName);
    $sid = $user.Translate([System.Security.Principal.SecurityIdentifier]).value;
    Publish-RegPath ("HKLM:\SOFTWARE\Microsoft\WcmSvc\wifinetworkmanager\features\" + $sid);
    New-ItemProperty -Force ("HKLM:\SOFTWARE\Microsoft\WcmSvc\wifinetworkmanager\features\" + $sid) "FeatureStates" -Value 0x33c;
    New-ItemProperty -Force "HKLM:\SOFTWARE\Microsoft\WcmSvc\wifinetworkmanager\features" "WiFiSenseCredShared" -Value 0;
    New-ItemProperty -Force "HKLM:\SOFTWARE\Microsoft\WcmSvc\wifinetworkmanager\features" "WiFiSenseOpen" -Value 0;

# Inking and typing settings
    Publish-RegPath "HKCU:\SOFTWARE\Microsoft\InputPersonalization";
    New-ItemProperty -Force "HKCU:\SOFTWARE\Microsoft\InputPersonalization" "RestrictImplicitInkCollection" -Value 1;
    New-ItemProperty -Force "HKCU:\SOFTWARE\Microsoft\InputPersonalization" "RestrictImplicitTextCollection" -Value 1;

# Set privacy policy accepted state to 0
    Publish-RegPath "HKCU:\SOFTWARE\Microsoft\Personalization\Settings";
    New-ItemProperty -Force "HKCU:\SOFTWARE\Microsoft\Personalization\Settings" "AcceptedPrivacyPolicy" -Value 0;

# echo "Do not scan contact informations
    Publish-RegPath "HKCU:\SOFTWARE\Microsoft\InputPersonalization\TrainedDataStore";
    New-ItemProperty -Force "HKCU:\SOFTWARE\Microsoft\InputPersonalization\TrainedDataStore" "HarvestContacts" -Value 0;

# Disable synchronisation of settings
    New-ItemProperty -Force "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\SettingSync" "BackupPolicy" -Value 0x3c;
    New-ItemProperty -Force "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\SettingSync" "DeviceMetadataUploaded" -Value 0;
    New-ItemProperty -Force "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\SettingSync" "PriorLogons" -Value 1;
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
        Publish-RegPath "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\SettingSync\Groups\$group";
        New-ItemProperty -Force "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\SettingSync\Groups\$group" -Name "Enabled" -Value 0;
    };

# echo "Set general privacy options"
    # Disable access to Speechlist
    New-ItemProperty -Force -Path "HKCU:\Control Panel\International\User Profile" -Name "HttpAcceptLanguageOptOut" -Value 1;
    
    Publish-RegPath "HKCU:\Printers\Defaults";
    New-ItemProperty -Force -Path "HKCU:\Printers\Defaults" -Name "NetID" -Value "{00000000-0000-0000-0000-000000000000}";
    
    # Disable Feedback on write
    Publish-RegPath "HKCU:\SOFTWARE\Microsoft\Input\TIPC";
    New-ItemProperty -Force "HKCU:\SOFTWARE\Microsoft\Input\TIPC" -Name "Enable" -Value 0;
    
    # Privacy: Let apps use my advertising ID: Disable
    Publish-RegPath "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo";
    New-ItemProperty -Force -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo" -Name Enabled -Type DWord -Value 0;
    
    # Privacy: SmartScreen Filter for Store Apps: Disable
	New-ItemProperty -Force "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppHost" -Name "EnableWebContentEvaluation" -Value 0;

    # Disable Cortana
    Publish-RegPath  "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search";
    New-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" -Name "AllowCortana" -Value "0" -PropertyType DWORD -Force;
    Publish-RegPath  "SOFTWARE\Microsoft\Personalization\Settings";
    New-ItemProperty -Path "SOFTWARE\Microsoft\Personalization\Settings" -Name "AcceptedPrivacyPolicy" -Value 0 -Type DWORD -Force;
    Publish-RegPath  "SOFTWARE\Microsoft\Windows\CurrentVersion\SettingSync\Groups\Language";
    New-ItemProperty -Path "SOFTWARE\Microsoft\Windows\CurrentVersion\SettingSync\Groups\Language" -Name "Enabled" -Value 0 -Type DWORD -Force;
    New-ItemProperty -Path "SOFTWARE\Microsoft\InputPersonalization" -Name "RestrictImplicitTextCollection" -Value 1 -Type DWORD -Force;
    New-ItemProperty -Path "SOFTWARE\Microsoft\InputPersonalization" -Name "RestrictImplicitInkCollection" -Value 1 -Type DWORD -Force;
    Publish-RegPath  "SOFTWARE\Microsoft\InputPersonalization\TrainedDataStore";
    New-ItemProperty -Path "SOFTWARE\Microsoft\InputPersonalization\TrainedDataStore" -Name "HarvestContacts" -Value 0 -Type DWORD -Force;


# Adding telemetry domains to hosts file
$hosts_file = "$env:systemroot\System32\drivers\etc\hosts";

    $domains = @(
        "vortex.data.microsoft.com"
        "vortex-win.data.microsoft.com"
        "telecommand.telemetry.microsoft.com"
        "telecommand.telemetry.microsoft.com.nsatc.net"
        "oca.telemetry.microsoft.com"
        "oca.telemetry.microsoft.com.nsatc.net"
        "sqm.telemetry.microsoft.com"
        "sqm.telemetry.microsoft.com.nsatc.net"
        "watson.telemetry.microsoft.com"
        "watson.telemetry.microsoft.com.nsatc.net"
        "redir.metaservices.microsoft.com"
        "choice.microsoft.com"
        "choice.microsoft.com.nsatc.net"
        "df.telemetry.microsoft.com"
        "reports.wes.df.telemetry.microsoft.com"
        "services.wes.df.telemetry.microsoft.com"
        "sqm.df.telemetry.microsoft.com"
        "telemetry.microsoft.com"
        "watson.ppe.telemetry.microsoft.com"
        "telemetry.appex.bing.net"
        "telemetry.urs.microsoft.com"
        "telemetry.appex.bing.net:443"
        "vortex-sandbox.data.microsoft.com"
        "settings-sandbox.data.microsoft.com"
        "vortex.data.microsoft.com"
        "vortex-win.data.microsoft.com"
        "telecommand.telemetry.microsoft.com"
        "telecommand.telemetry.microsoft.com.nsatc.net"
        "oca.telemetry.microsoft.com"
        "oca.telemetry.microsoft.com.nsatc.net"
        "sqm.telemetry.microsoft.com"
        "sqm.telemetry.microsoft.com.nsatc.net"
        "watson.telemetry.microsoft.com"
        "watson.telemetry.microsoft.com.nsatc.net"
        "redir.metaservices.microsoft.com"
        "choice.microsoft.com"
        "choice.microsoft.com.nsatc.net"
        "vortex-sandbox.data.microsoft.com"
        "settings-sandbox.data.microsoft.com"
        "df.telemetry.microsoft.com"
        "reports.wes.df.telemetry.microsoft.com"
        "sqm.df.telemetry.microsoft.com"
        "telemetry.microsoft.com"
        "watson.microsoft.com"
        "watson.ppe.telemetry.microsoft.com"
        "wes.df.telemetry.microsoft.com"
        "telemetry.appex.bing.net"
        "telemetry.urs.microsoft.com"
        "survey.watson.microsoft.com"
        "watson.live.com"
        "services.wes.df.telemetry.microsoft.com"
        "telemetry.appex.bing.net"
        "vortex.data.microsoft.com"
        "vortex-win.data.microsoft.com"
        "telecommand.telemetry.microsoft.com"
        "telecommand.telemetry.microsoft.com.nsatc.net"
        "oca.telemetry.microsoft.com"
        "oca.telemetry.microsoft.com.nsatc.net"
        "sqm.telemetry.microsoft.com"
        "sqm.telemetry.microsoft.com.nsatc.net"
        "watson.telemetry.microsoft.com"
        "watson.telemetry.microsoft.com.nsatc.net"
        "redir.metaservices.microsoft.com"
        "choice.microsoft.com"
        "choice.microsoft.com.nsatc.net"
        "df.telemetry.microsoft.com"
        "reports.wes.df.telemetry.microsoft.com"
        "wes.df.telemetry.microsoft.com"
        "services.wes.df.telemetry.microsoft.com"
        "sqm.df.telemetry.microsoft.com"
        "telemetry.microsoft.com"
        "watson.ppe.telemetry.microsoft.com"
        "telemetry.appex.bing.net"
        "telemetry.urs.microsoft.com"
        "telemetry.appex.bing.net:443"
        "settings-sandbox.data.microsoft.com"
        "vortex-sandbox.data.microsoft.com"
        "survey.watson.microsoft.com"
        "watson.live.com"
        "watson.microsoft.com"
        "statsfe2.ws.microsoft.com"
        "corpext.msitadfs.glbdns2.microsoft.com"
        "compatexchange.cloudapp.net"
        "cs1.wpc.v0cdn.net"
        "a-0001.a-msedge.net"
        "a-0002.a-msedge.net"
        "a-0003.a-msedge.net"
        "a-0004.a-msedge.net"
        "a-0005.a-msedge.net"
        "a-0006.a-msedge.net"
        "a-0007.a-msedge.net"
        "a-0008.a-msedge.net"
        "a-0009.a-msedge.net"
        "msedge.net"
        "a-msedge.net"
        "statsfe2.update.microsoft.com.akadns.net"
        "sls.update.microsoft.com.akadns.net"
        "fe2.update.microsoft.com.akadns.net"
        "diagnostics.support.microsoft.com"
        "corp.sts.microsoft.com"
        "statsfe1.ws.microsoft.com"
        "pre.footprintpredict.com"
        "i1.services.social.microsoft.com"
        "i1.services.social.microsoft.com.nsatc.net"
        "feedback.windows.com"
        "feedback.microsoft-hohm.com"
        "feedback.search.microsoft.com"
        "184-86-53-99.deploy.static.akamaitechnologies.com"
        "a-0001.a-msedge.net"
        "a-0002.a-msedge.net"
        "a-0003.a-msedge.net"
        "a-0004.a-msedge.net"
        "a-0005.a-msedge.net"
        "a-0006.a-msedge.net"
        "a-0007.a-msedge.net"
        "a-0008.a-msedge.net"
        "a-0009.a-msedge.net"
        "a1621.g.akamai.net"
        "a1856.g2.akamai.net"
        "a1961.g.akamai.net"
        "a978.i6g1.akamai.net"
        "a.ads1.msn.com"
        "a.ads2.msads.net"
        "a.ads2.msn.com"
        "ac3.msn.com"
        "ad.doubleclick.net"
        "adnexus.net"
        "adnxs.com"
        "ads1.msads.net"
        "ads1.msn.com"
        "ads.msn.com"
        "aidps.atdmt.com"
        "aka-cdn-ns.adtech.de"
        "a-msedge.net"
        "any.edge.bing.com"
        "a.rad.msn.com"
        "az361816.vo.msecnd.net"
        "az512334.vo.msecnd.net"
        "b.ads1.msn.com"
        "b.ads2.msads.net"
        "bingads.microsoft.com"
        "b.rad.msn.com"
        "bs.serving-sys.com"
        "c.atdmt.com"
        "cdn.atdmt.com"
        "cds26.ams9.msecn.net"
        "choice.microsoft.com"
        "choice.microsoft.com.nsatc.net"
        "compatexchange.cloudapp.net"
        "corpext.msitadfs.glbdns2.microsoft.com"
        "corp.sts.microsoft.com"
        "cs1.wpc.v0cdn.net"
        "db3aqu.atdmt.com"
        "df.telemetry.microsoft.com"
        "diagnostics.support.microsoft.com"
        "e2835.dspb.akamaiedge.net"
        "e7341.g.akamaiedge.net"
        "e7502.ce.akamaiedge.net"
        "e8218.ce.akamaiedge.net"
        "ec.atdmt.com"
        "fe2.update.microsoft.com.akadns.net"
        "feedback.microsoft-hohm.com"
        "feedback.search.microsoft.com"
        "feedback.windows.com"
        "flex.msn.com"
        "g.msn.com"
        "h1.msn.com"
        "h2.msn.com"
        "hostedocsp.globalsign.com"
        "i1.services.social.microsoft.com"
        "i1.services.social.microsoft.com.nsatc.net"
        "ipv6.msftncsi.com"
        "ipv6.msftncsi.com.edgesuite.net"
        "lb1.www.ms.akadns.net"
        "live.rads.msn.com"
        "m.adnxs.com"
        "msedge.net"
        "msftncsi.com"
        "msnbot-65-55-108-23.search.msn.com"
        "msntest.serving-sys.com"
        "oca.telemetry.microsoft.com"
        "oca.telemetry.microsoft.com.nsatc.net"
        "onesettings-db5.metron.live.nsatc.net"
        "pre.footprintpredict.com"
        "preview.msn.com"
        "rad.live.com"
        "rad.msn.com"
        "redir.metaservices.microsoft.com"
        "reports.wes.df.telemetry.microsoft.com"
        "schemas.microsoft.akadns.net"
        "secure.adnxs.com"
        "secure.flashtalking.com"
        "services.wes.df.telemetry.microsoft.com"
        "settings-sandbox.data.microsoft.com"
        "settings-win.data.microsoft.com"
        "sls.update.microsoft.com.akadns.net"
        "sqm.df.telemetry.microsoft.com"
        "sqm.telemetry.microsoft.com"
        "sqm.telemetry.microsoft.com.nsatc.net"
        "ssw.live.com"
        "static.2mdn.net"
        "statsfe1.ws.microsoft.com"
        "statsfe2.update.microsoft.com.akadns.net"
        "statsfe2.ws.microsoft.com"
        "survey.watson.microsoft.com"
        "telecommand.telemetry.microsoft.com"
        "telecommand.telemetry.microsoft.com.nsatc.net"
        "telemetry.appex.bing.net"
        "telemetry.appex.bing.net:443"
        "telemetry.microsoft.com"
        "telemetry.urs.microsoft.com"
        "vortex-bn2.metron.live.com.nsatc.net"
        "vortex-cy2.metron.live.com.nsatc.net"
        "vortex.data.microsoft.com"
        "vortex-sandbox.data.microsoft.com"
        "vortex-win.data.microsoft.com"
        "cy2.vortex.data.microsoft.com.akadns.net"
        "watson.live.com"
        "watson.microsoft.com"
        "watson.ppe.telemetry.microsoft.com"
        "watson.telemetry.microsoft.com"
        "watson.telemetry.microsoft.com.nsatc.net"
        "wes.df.telemetry.microsoft.com"
        "win10.ipv6.microsoft.com"
        "www.bingads.microsoft.com"
        "www.go.microsoft.akadns.net"
        "www.msftncsi.com"
        "m.hotmail.com"

        # extra
        "fe2.update.microsoft.com.akadns.net"
        "s0.2mdn.net"
        "statsfe2.update.microsoft.com.akadns.net",
        "survey.watson.microsoft.com"
        "view.atdmt.com"
        "watson.microsoft.com",
        "watson.ppe.telemetry.microsoft.com"
        "watson.telemetry.microsoft.com",
        "watson.telemetry.microsoft.com.nsatc.net"
        "wes.df.telemetry.microsoft.com"

        #"a248.e.akamai.net"            # makes iTunes download button disappear
        
        # Can cause issues with Skype
        #"c.msn.com"
        #"ui.skype.com"
        #"pricelist.skype.com"
        #"apps.skype.com"
        #"s.gateway.messenger.live.com"
    );

    Write-Output "" | Out-File -Encoding ASCII -Append $hosts_file;

    foreach ($domain in $domains) {
        if (-Not (Select-String -Path $hosts_file -Pattern $domain)) {
            Write-Output "0.0.0.0 $domain" | Out-File -Encoding ASCII -Append $hosts_file -ErrorAction SilentlyContinue;
        };
    };    


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


# Restart explorer to cause some settings to take affect
    Stop-Process -ProcessName explorer;
