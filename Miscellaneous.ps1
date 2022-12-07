# Force Get-Childitem to NOT pull Windows directory or Program Files directories.
Get-ChildItem c:\ -Depth 0 -Directory | Where-Object {$_.Name -notmatch "windows|Program Files|Program Files \(x86\)"} | Get-Childitem -Recurse


# Get Windows 7, 10 Product Key from current system
(Get-WmiObject -Query 'select * from SoftwareLicensingService').OA3xOriginalProductKey


# Clear all event logs
wevtutil el | Foreach-Object {wevtutil cl "$_"}


# List mapped drives
get-wmiobject -class 'Win32_LogicalDisk' -Filter 'drivetype=4'


# Query a for a registry value's data at the given key
$key = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\EventLog\EventForwarding\SubscriptionManager"
$value = "1"
$data = (Get-ItemProperty -path $key).$value
$data


# Run an encoded command
$Command = 'Get-Service BITS' 
$Encoded = [convert]::ToBase64String([System.Text.encoding]::Unicode.GetBytes($command)) 
powershell.exe -encoded $Encoded


# Drives Reference
Get-Disk
Get-Partition -DiskNumber 1
Remove-Partition -DiskNumber 1 -PartitionNumber 1
New-Partition -DiskNumber 1 -UseMaximumSize -AssignDriveLetter
Format-Volume -DriveLetter F -FileSystem NTFS -NewFileSystemLabel "Label"


# Enable WinRM Option 1
winrm quickconfig -y

# Enable WinRM Option 2
Enable-PSRemoting –Force

# Enable WinRM Option 3
## Start the WinRM service. 
(get-service winrm).start()
## Set the WinRM service type to delayed auto start.
set-service winrm -startuptype "Automatic"
## Configure LocalAccountTokenFilterPolicy to grant administrative rights remotely to local users.
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name LocalAccountTokenFilterPolicy -Value 1

# Enable WinRM Option 4
## Run winrm quickconfig on a remote system
PsExec.exe -s \\SomeComputer -accepteula powershell -ExecutionPolicy ByPass -nologo -command "& winrm quickconfig -y"


# Convert .json file to PowerShell objects
$file = "file.json"
$json = Get-Content $file | ConvertFrom-Json
$json
## Note that some json nests the records deeper into the array. For example:
$records = $json._embedded.records
$records


# Enable event logs
$LogNamesArray = @(
    "Microsoft-Windows-DriverFrameworks-UserMode/Operational"
)
foreach ($LogName in $LogNamesArray){
    $Log = New-Object System.Diagnostics.Eventing.Reader.EventLogConfiguration $LogName
    $Log.IsEnabled = $true
    $Log.SaveChanges()
}


# Registers a scheduled task which runs a PowerShell script file daily at 10am
$Action = New-ScheduledTaskAction -Execute 'Powershell.exe' -Argument '-ExecutionPolicy Bypass -Windowstyle Hidden -File "C:\Users\Daft\Documents\threcon.ps1"'
$Trigger = New-ScheduledTaskTrigger -Daily -At 10am
Register-ScheduledTask -Action $Action -Trigger $Trigger -TaskName "Powershell Script" -Description "Why did I do this?"


# Registers a scheduled task which runs a command directly, every hour starting now, with highest rights
$Action2 = New-ScheduledTaskAction -Execute 'Powershell.exe' -Argument '-ExecutionPolicy Bypass -Windowstyle Hidden -Command "mkdir c:\test"'
$Trigger2 = New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionDuration (New-TimeSpan -Days (365 * 20)) -RepetitionInterval  (New-TimeSpan -Minutes 60)
$Principal = New-ScheduledTaskPrincipal -UserID "NT AUTHORITY\SYSTEM" -RunLevel Highest
Register-ScheduledTask -Action $Action2 -Trigger $Trigger2 -Principal $Principal -TaskName "Powershell Command" -Description "Elevated!"


# Get BitLocker Keys
ForEach ($Volume in Get-BitLockerVolume) {
    $Volume | Add-Member -MemberType NoteProperty -Name Key -Value (($Volume).KeyProtector.RecoveryPassword[1])
    $Volume | Select-Object *
}


# Convert plain text to base64
$Text = 'This is a secret and should be hidden'
$Bytes = [System.Text.Encoding]::Unicode.GetBytes($Text)
$EncodedText = [Convert]::ToBase64String($Bytes)
$EncodedText


# Convert base64 to plain text
$base64_string = "VABoAGkAcwAgAGkAcwAgAGEAIABzAGUAYwByAGUAdAAgAGEAbgBkACAAcwBoAG8AdQBsAGQAIABiAGUAIABoAGkAZABkAGUAbgA="
[System.Text.Encoding]::Default.GetString([System.Convert]::FromBase64String($base64_string))


# Resolve Shortened URL
$URL = "http://tinyurl.com/KindleWireless"
(Invoke-WebRequest -Uri $URL -MaximumRedirection 0 -ErrorAction Ignore).Headers.Location


# Merge CSV files
Get-ChildItem *.csv | select name -ExpandProperty name | Import-Csv | export-csv -NoTypeInformation merged.csv


# Change the Network Profile Associated with a Network Connection (e.g. Public, Private, etc.)
Get-NetConnectionProfile
Set-NetConnectionProfile -Name "Unidentified network" -NetworkCategory Private
