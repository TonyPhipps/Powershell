Registers a scheduled task which runs a PowerShell script file daily at 10am
```
$Action = New-ScheduledTaskAction -Execute 'Powershell.exe' -Argument '-ExecutionPolicy Bypass -Windowstyle Hidden -File "C:\Users\Daft\Documents\threcon.ps1"'
$Trigger = New-ScheduledTaskTrigger -Daily -At 10am
Register-ScheduledTask -Action $Action -Trigger $Trigger -TaskName "Powershell Script" -Description "Why did I do this?"
```

Registers a scheduled task which runs a command directly, every hour starting now, with highest rights
```
$Action = New-ScheduledTaskAction -Execute 'Powershell.exe' -Argument '-ExecutionPolicy Bypass -Windowstyle Hidden -Command "mkdir c:\test"'
$Trigger = New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionDuration (New-TimeSpan -Days (365 * 20)) -RepetitionInterval  (New-TimeSpan -Minutes 60)
$Principal = New-ScheduledTaskPrincipal -UserID "NT AUTHORITY\SYSTEM" -RunLevel Highest
Register-ScheduledTask -Action $Action -Trigger $Trigger -Principal $Principal -TaskName "Powershell Command" -Description "Elevated!"
```

Set a newtork adapter to Private at startup
```
$PowerShellCommand = "Set-NetConnectionProfile -InterfaceAlias Eth1 -NetworkCategory Private"

$Action = New-ScheduledTaskAction -Execute "Powershell.exe" -Argument "-ExecutionPolicy Bypass -Windowstyle Hidden -Command `"$PowerShellCommand`""
$Trigger = New-ScheduledTaskTrigger -AtStartup
$Principal = New-ScheduledTaskPrincipal -RunLevel Highest -UserId "NT AUTHORITY\SYSTEM" -LogonType ServiceAccount

Register-ScheduledTask -Action $Action -Trigger $Trigger -Principal $Principal -TaskName "Set Eth1 to Private" -Description "Set Interface Profile to Private"
```