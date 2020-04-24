# Get AppID DisplayName for lookup table
Get-AzureADServicePrincipal -All:$True | Select-Object AppId, Displayname | Sort-Object DisplayName | export-csv -NoTypeInformation principal-appid.csv
