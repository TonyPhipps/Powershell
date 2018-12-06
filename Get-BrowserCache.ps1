$Source = "\\target\c$\users\"
$Destination = "\\mysystem\c$\temp\results\"

$InternetExplorer = '*\AppData\Local\Microsoft\Windows\INetCache'
$InternetExplorerVirtualized = '*Virtualized*'
$Firefox = '*\AppData\Local\Mozilla\Firefox\Profiles\*.default\cache2'
$Chrome = '*\AppData\Local\Google\Chrome\User Data\Default\Cache'

$UserFolderArray = Get-Childitem $Source -Directory -Recurse -Force | Select-Object FullName -ExpandProperty FullName 
$UserFolderArray = $UserFolderArray | Where-Object {$_ -like $InternetExplorer -or $_ -like $Firefox -or $_ -like $Chrome}
$UserFolderArray = $UserFolderArray | Where-Object {$_ -notlike $InternetExplorerVirtualized}

foreach ($UserFolder in $ $UserFolderArray) {

    Copy-Item $UserFolder $Destination -Force -Recurse
}