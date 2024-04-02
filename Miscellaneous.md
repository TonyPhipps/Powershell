
Install Remote Server Administration Tools (RSAT)
```
**Get-WindowsCapability -Name RSAT* -Online | Add-WindowsCapability -Online**
```

Get Windows 7, 10 Product Key from current system
```
(Get-WmiObject -Query 'select * from SoftwareLicensingService').OA3xOriginalProductKey
```

Resolve Shortened URL
```
$URL = "http://tinyurl.com/KindleWireless"
(Invoke-WebRequest -Uri $URL -MaximumRedirection 0 -ErrorAction Ignore).Headers.Location
```

List mapped drives
```
get-wmiobject -class 'Win32_LogicalDisk' -Filter 'drivetype=4'
```

Drives Reference
```
Get-Disk
Get-Partition -DiskNumber 1
Remove-Partition -DiskNumber 1 -PartitionNumber 1
New-Partition -DiskNumber 1 -UseMaximumSize -AssignDriveLetter
Format-Volume -DriveLetter F -FileSystem NTFS -NewFileSystemLabel "Label"
```



Get BitLocker Keys
```
ForEach ($Volume in Get-BitLockerVolume) {
    $Volume | Add-Member -MemberType NoteProperty -Name Key -Value (($Volume).KeyProtector.RecoveryPassword[1])
    $Volume | Select-Object *
}
```


Change the Network Profile Associated with a Network Connection (e.g. Public, Private, etc.)
```
Get-NetConnectionProfile
Set-NetConnectionProfile -Name "Unidentified network" -NetworkCategory Private

```
