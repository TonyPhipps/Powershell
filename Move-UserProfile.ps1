# Create a new admin profile, then log out and into the new account
# Run code below from the new admin account

$date = Get-Date -UFormat "%Y-%m-%d";
$source = "C:\Users\Cooler"
$destination = "D:\Users\Cooler"
# $incremenetalDestination = "g:\Backup\Tony_incremental_$date\";
$logFile = "D:\BackupLog_$date.txt";
$backupReport = "D:\BackupReport_$date.txt";
 

## Check if Destination exists, if no create folder
if (!(Test-Path -path $Destination)) {
    New-Item $Destination -type directory;
};
 
robocopy $source $destination /XJ *.* /COPY:DAT /DCOPY:DAT /MIR /ZB /R:3 /W:10 /MT:4 /log:$logFile /NP /TEE;


## Compare Source and Destination, write deviations to backup report 
$check_Source = Dir $source;
$check_Destination = Dir $destination;
Compare-Object $check_Source $check_Destination | Out-File $backupReport;

# Go to this registry key, find the user SID, and modify the ProfileImagePath to match your $destination
# HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList

# Log out and back in to the original account. Some apps may need to be reinstalled due to how Windows is dumb.
# Get-AppXPackage -AllUsers | Foreach {Add-AppxPackage -DisableDevelopmentMode -Register “$($_.InstallLocation)\AppXManifest.xml”}
