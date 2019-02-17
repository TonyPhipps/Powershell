Get-Disk
Get-Partition -DiskNumber 1
Remove-Partition -DiskNumber 1 -PartitionNumber 1
New-Partition -DiskNumber 1 -UseMaximumSize -AssignDriveLetter
Format-Volume -DriveLetter F -FileSystem NTFS -NewFileSystemLabel "Label"
