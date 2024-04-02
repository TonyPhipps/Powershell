# Install-Module -Name vmware.powercli -AllowClobber
# Set-PowerCLIConfiguration -ParticipateInCEIP $true
# Set-PowerCLIConfiguration -InvalidCertificateAction Ignore

$VIServer = "192.168.1.100"
$VIServerCredentials = "user@fqdn.com"
$VIServerCredentials = (Get-Credential $VIServerCredentials)
Connect-VIServer $VIServer -Credential $VIServerCredentials

$GuestCredentials = "guestuser"
$GuestCredentials = (Get-credential $GuestCredentials)

$VM = "vmName"
$Source = "C:\Users\aphipps\Downloads\test.txt"
$Destination = "C:\TEMP\tony"

# Copy From Local to Guest
Copy-VMGuestFile -Source $Source -Destination $Destination -LocalToGuest -VM $VM -GuestCredential $GuestCredentials -Force
[System.Console]::beep(440, 500)

# Copy From Guest to Local
Copy-VMGuestFile -Source $Source -Destination $Destination -GuestToLocal -VM $VM -GuestCredential $GuestCredentials -Force
[System.Console]::beep(440, 500)