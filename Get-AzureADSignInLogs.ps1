# Install-Module -Name Msonline
# Install-Module -Name AzureADPreview -AllowClobber

$UserCredential = Get-Credential
Connect-MsolService -Credential $UserCredential
Connect-AzureAD -Credential $UserCredential

$UPN = "tony@sample.com"

# Get All Logs
Get-AzureADAuditSignInLogs -Filter "userPrincipalName eq '$UPN'"

# Get Last Login
Get-AzureAdAuditSigninLogs -top 1 -filter "userprincipalname eq '$UPN'" | select CreatedDateTime

