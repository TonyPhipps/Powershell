# Registers a scheduled task which launches a powershell script.

$Action = New-ScheduledTaskAction -Execute 'Powershell.exe' -Argument 'C:\PowershellScript.ps1'

$Trigger = New-ScheduledTaskTrigger -Daily -At 10am

Register-ScheduledTask -Action $Action -Trigger $Trigger -TaskName "Powershell Script" -Description "Why did I do this?"

