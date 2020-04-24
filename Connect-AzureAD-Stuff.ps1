# Create a lookup table for ResourceAppId GUID's
Get-AzureADServicePrincipal -All:$True | Select-Object AppId, Displayname | Sort-Object DisplayName | export-csv -NoTypeInformation principal-appid.csv
