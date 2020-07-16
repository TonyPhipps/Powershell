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