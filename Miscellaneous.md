
Install Remote Server Administration Tools (RSAT)
```
**Get-WindowsCapability -Name RSAT* -Online | Add-WindowsCapability -Online**
```

Get Windows 7, 10 Product Key from current system
```
(Get-WmiObject -Query 'select * from SoftwareLicensingService').OA3xOriginalProductKey
```

Clear all event logs
```
wevtutil el | Foreach-Object {wevtutil cl "$_"}
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

Registers a scheduled task which runs a PowerShell script file daily at 10am
```
$Action = New-ScheduledTaskAction -Execute 'Powershell.exe' -Argument '-ExecutionPolicy Bypass -Windowstyle Hidden -File "C:\Users\Daft\Documents\threcon.ps1"'
$Trigger = New-ScheduledTaskTrigger -Daily -At 10am
Register-ScheduledTask -Action $Action -Trigger $Trigger -TaskName "Powershell Script" -Description "Why did I do this?"
```

Registers a scheduled task which runs a command directly, every hour starting now, with highest rights
```
$Action2 = New-ScheduledTaskAction -Execute 'Powershell.exe' -Argument '-ExecutionPolicy Bypass -Windowstyle Hidden -Command "mkdir c:\test"'
$Trigger2 = New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionDuration (New-TimeSpan -Days (365 * 20)) -RepetitionInterval  (New-TimeSpan -Minutes 60)
$Principal = New-ScheduledTaskPrincipal -UserID "NT AUTHORITY\SYSTEM" -RunLevel Highest
Register-ScheduledTask -Action $Action2 -Trigger $Trigger2 -Principal $Principal -TaskName "Powershell Command" -Description "Elevated!"
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
