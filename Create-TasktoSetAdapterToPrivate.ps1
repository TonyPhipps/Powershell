$PowerShellCommand = "Set-NetConnectionProfile -InterfaceAlias Connection1 -NetworkCategory Private"
$Action = New-ScheduledTaskAction -Execute "Powershell.exe" -Argument "-ExecutionPolicy Bypass -Windowstyle Hidden -Command `"$PowerShellCommand`""
$Trigger = New-ScheduledTaskTrigger -AtStartup
$Principal = New-ScheduledTaskPrincipal -RunLevel Highest -UserId "NT AUTHORITY\SYSTEM" -LogonType ServiceAccount
Register-ScheduledTask -Action $Action -Trigger $Trigger -Principal $Principal -TaskName "Set Connection1 to Private" -Description "Connection1 to Private"