# Install-Module -Name Msonline
# Install-Module -Name AzureADPreview -AllowClobber

# Connect to AzureAD
$UserCredential = Get-Credential
Connect-MsolService -Credential $UserCredential
Connect-AzureAD -Credential $UserCredential

$UPN = "tony@sample.com"


# Get All Logs
Get-AzureADAuditSignInLogs -Filter "userPrincipalName eq '$UPN'"


# Save Logs to JSON File
$Logs = Get-AzureADAuditSignInLogs -Filter "userPrincipalName eq '$UPN'"

foreach ($log in $Logs){
  $log | ConvertTo-Json -Compress | Out-File AzureADAuditSignInLogs.json -Append
}


# Get Last Login
Get-AzureAdAuditSigninLogs -top 1 -filter "userprincipalname eq '$UPN'" | select CreatedDateTime


# Create a lookup table for ResourceAppId GUID's
Get-AzureADServicePrincipal -All:$True | Select-Object AppId, Displayname | Sort-Object DisplayName | export-csv -NoTypeInformation principal-appid.csv


# Sign out a user from all active sessions and disable account
Get-AzureADUser -SearchString user@contoso.com | Revoke-AzureADUserAllRefreshToken 
Get-AzureADUser -SearchString user@contoso.com | Disable-ADAccount
