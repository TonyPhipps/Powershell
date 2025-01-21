Install-Module -Name vmware.powercli -AllowClobber
# Set-PowerCLIConfiguration -ParticipateInCEIP $true
# Set-PowerCLIConfiguration -InvalidCertificateAction Ignore
# Set-PowerCLIConfiguration -WebOperationTimeoutSeconds 1800 -Scope User
# Import-Module VMware.VimAutomation.Core

$VIServer = "server"
$VIServerCredentials = "administrator@server"
$VIServerCredentials = (Get-Credential $VIServerCredentials)


$GuestCredentials = "guest_admin"
$GuestCredentials = (Get-credential $GuestCredentials)

$VM = "vm_name"

$Source = "D:\vmware_LocalToGuest"
$Destination = "D:\vmware_LocalToGuest"

Connect-VIServer $VIServer -Credential $VIServerCredentials

Copy-VMGuestFile -Source $Source -Destination $Destination -LocalToGuest -VM $VM -GuestCredential $GuestCredentials -Force
[System.Console]::beep(440, 500)

$Source = "D:\vmware_GuestToLocal"
$Destination = "D:\vmware_GuestToLocal"

Copy-VMGuestFile -Source $Source -Destination $Destination -GuestToLocal -VM $VM -GuestCredential $GuestCredentials -Force
[System.Console]::beep(440, 500)
