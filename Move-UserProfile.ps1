# Create a new admin profile, then log out and into the new account
# Run code below from the new admin account

$date = Get-Date -UFormat "%Y-%m-%d";
$source = "C:\Users\Tony"
$destination = "F:\Users\Tony"
# $incremenetalDestination = "g:\Backup\Tony_incremental_$date\";
$logFile = "F:\BackupLog_$date.txt";
$backupReport = "F:\BackupReport_$date.txt";
 

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
regedit
# HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList

# Log out and back in to the original account. Some apps may need to be reinstalled due to how Windows is dumb.
# start-process powershell_ise.exe -verb runas
# Get-AppXPackage -AllUsers | Foreach {Add-AppxPackage -DisableDevelopmentMode -Register “$($_.InstallLocation)\AppXManifest.xml”}
