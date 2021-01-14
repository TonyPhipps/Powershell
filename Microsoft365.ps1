# References
# - https://docs.microsoft.com/en-us/microsoft-365/compliance/mailitemsaccessed-forensics-investigations?view=o365-worldwide

#Run the following command to sign-out the user of all active sessions.
Connect-AzureAD
Get-AzureADUser -SearchString user@contoso.com | Revoke-AzureADUserAllRefreshToken 
