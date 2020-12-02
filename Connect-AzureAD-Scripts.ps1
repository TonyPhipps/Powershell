# Install-Module -Name Msonline
# Install-Module -Name AzureADPreview -AllowClobber

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
