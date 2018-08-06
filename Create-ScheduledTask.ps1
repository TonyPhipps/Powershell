# Registers a scheduled task which launches a powershell script.

$Action = New-ScheduledTaskAction -Execute 'Powershell.exe' -Argument 'C:\PowershellScript.ps1'

# Repeat Daily
$Trigger = New-ScheduledTaskTrigger -Daily -At 10am

# Repeat Every Hour
$Trigger2 = New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionDuration (New-TimeSpan -Days (365 * 20)) -RepetitionInterval  (New-TimeSpan -Minutes 60)

Register-ScheduledTask -Action $Action -Trigger $Trigger -TaskName "Powershell Script" -Description "Why did I do this?"

