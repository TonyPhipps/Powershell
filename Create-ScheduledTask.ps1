# Registers a scheduled task which launches a powershell script or command.

# Run a script file daily at 10am
$Action = New-ScheduledTaskAction -Execute 'Powershell.exe' -Argument '-ExecutionPolicy Bypass -Windowstyle Hidden -File "C:\Users\Daft\Documents\threcon.ps1"'
$Trigger = New-ScheduledTaskTrigger -Daily -At 10am
Register-ScheduledTask -Action $Action -Trigger $Trigger -TaskName "Powershell Script" -Description "Why did I do this?"

# Run a command directly, every hour starting now, with highest rights
$Action2 = New-ScheduledTaskAction -Execute 'Powershell.exe' -Argument '-ExecutionPolicy Bypass -Windowstyle Hidden -Command "mkdir c:\test"'
$Trigger2 = New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionDuration (New-TimeSpan -Days (365 * 20)) -RepetitionInterval  (New-TimeSpan -Minutes 60)
$Principal = New-ScheduledTaskPrincipal -UserID "NT AUTHORITY\SYSTEM" -RunLevel Highest
Register-ScheduledTask -Action $Action2 -Trigger $Trigger2 -Principal $Principal -TaskName "Powershell Command" -Description "Elevated!"

