# WARNING
# Enabling anonymous access and sharing the root of every disk, even with read-only permissions, can expose sensitive data. 
# This setup is generally not recommended for production environments and should only be used in controlled scenarios.

# Function to enable required settings for anonymous file sharing
function Enable-AnonymousFileSharing {
    # Set permissions for everyone to access the shares
    $registryPath = "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters"
    Set-ItemProperty -Path $registryPath -Name "NullSessionShares" -Value "*"

    # Enable guest access
    net user guest /active:yes

    # Set sharing permissions for the guest account
    net localgroup "Guests" /add
    net localgroup "Guests" guest /add

    # Enable anonymous access in the registry
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters" -Name "RestrictNullSessAccess" -Value 0
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa" -Name "everyoneincludesanonymous" -Value 1
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa" -Name "restrictanonymous" -Value 0
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa" -Name "restrictanonymoussam" -Value 0
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanWorkstation\Parameters" -Name "AllowInsecureGuestAuth" -Value 1

    # Disable password protected sharing
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters" -Name "AutoShareWks" -Value 0
    Set-NetFirewallRule -DisplayName "File and Printer Sharing (SMB-In)" -Enabled True

    # Restart the server service to apply changes
    Restart-Service "lanmanserver"
}

# Function to share the root of every disk
function Share-AllDisks {
    # Get all drives on the system
    $drives = Get-PSDrive -PSProvider FileSystem

    foreach ($drive in $drives) {
        $driveLetter = $drive.Name + "$"
        $drivePath = $drive.Root

        # Create the share
        net share $driveLetter=$drivePath /GRANT:Everyone,READ # or FULL
    }
}

# Enable anonymous file sharing
Enable-AnonymousFileSharing

# Share the root of every disk
Share-AllDisks

Write-Host "All disks have been shared. Anonymous file sharing has been enabled."
