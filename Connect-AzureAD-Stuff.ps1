# Get AppID DisplayName for lookup table
$Pricipals | Select-Object AppId, Displayname | Sort-Object DisplayName | export-csv -NoTypeInformation principal-appid.csv
