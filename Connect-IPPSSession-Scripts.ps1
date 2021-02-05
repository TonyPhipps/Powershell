# Connect
$UserCredential = Get-Credential
Connect-IPPSSession -Credential $UserCredential

# List Security and Compliance Center configured alert policies
Get-ProtectionAlert | Format-List Name,Category,Comment,NotifyUser
