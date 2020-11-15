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
