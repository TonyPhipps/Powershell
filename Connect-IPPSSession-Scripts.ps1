# Configure
# https://docs.microsoft.com/en-us/powershell/exchange/connect-to-scc-powershell?view=exchange-ps
Import-Module ExchangeOnlineManagement

# Connect
$UserCredential = Get-Credential
Connect-IPPSSession -Credential $UserCredential

# List Security and Compliance Center configured alert policies
Get-ProtectionAlert | Format-List Name,Category,Comment,NotifyUser
