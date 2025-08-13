
Install Remote Server Administration Tools (RSAT)
```ps
**Get-WindowsCapability -Name RSAT* -Online | Add-WindowsCapability -Online**
```

Get Windows 7, 10 Product Key from current system
```ps
(Get-WmiObject -Query 'select * from SoftwareLicensingService').OA3xOriginalProductKey
```

Resolve Shortened URL
```ps
$URL = "http://tinyurl.com/KindleWireless"
(Invoke-WebRequest -Uri $URL -MaximumRedirection 0 -ErrorAction Ignore).Headers.Location
```

List mapped drives
```ps
get-wmiobject -class 'Win32_LogicalDisk' -Filter 'drivetype=4'
```

Drives Reference
```ps
Get-Disk
clear-disk -number 1 -removedata -RemoveOEM
Initialize-Disk -Number 1 -PartitionStyle GPT
Get-Partition -DiskNumber 1
Remove-Partition -DiskNumber 1 -PartitionNumber 1
New-Partition -DiskNumber 1 -UseMaximumSize -AssignDriveLetter
Format-Volume -DriveLetter F -FileSystem NTFS -NewFileSystemLabel "Label"
```



Get BitLocker Keys
```ps
ForEach ($Volume in Get-BitLockerVolume) {
    $Volume | Add-Member -MemberType NoteProperty -Name Key -Value (($Volume).KeyProtector.RecoveryPassword[1])
    $Volume | Select-Object *
}
```


Change the Network Profile Associated with a Network Connection (e.g. Public, Private, etc.)
```ps
Get-NetConnectionProfile
Set-NetConnectionProfile -Name "Unidentified network" -NetworkCategory Private

```

Filter a string to produce a valid filename
```ps
function Get-ValidFileName {
    param (
        [string]$fileName,
        [string]$replacement = "_"
    )

    $invalidChars = [System.IO.Path]::GetInvalidFileNameChars()

    foreach ($char in $invalidChars) {
        $fileName = $fileName -replace [RegEx]::Escape($char), $replacement
    }

    return $fileName
}
```


Set a timeout on a powershell scriptblock
```ps
$Timeout = 60
$job = Start-Job -ScriptBlock {
    # Here's where you put the stuff that might hang or take too long.
}

$JobTimer = 0

# Wait for the number of seconds in the $Timeout variable before giving up On the Job.
while ($job.State -eq "Running" -and $JobTimer -le $Timeout) {
    $JobTimer = $JobTimer + 1
    sleep -Seconds 1
}

if ($job.State -eq "Completed" -and $job.HasMoreData -eq $true) {
    $job | Receive-Job
}
```