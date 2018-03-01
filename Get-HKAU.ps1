# Load every user registry hive on a system and perform actions therein
# https://www.pdq.com/blog/modifying-the-registry-users-powershell/

# Regex pattern for SIDs
$PatternSID = 'S-1-5-21-\d+-\d+\-\d+\-\d+$'
 
# Get all users' Username, SID, and location of ntuser.dat
$UserArray = Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList\*' | 
Where-Object {$_.PSChildName -match $PatternSID} | 
Select-Object  @{name="SID";expression={$_.PSChildName}}, 
		@{name="UserHive";expression={"$($_.ProfileImagePath)\ntuser.dat"}}, 
		@{name="Username";expression={$_.ProfileImagePath -replace '^(.*[\\\/])', ''}}
 
 $LoadedHives = Get-ChildItem Registry::HKEY_USERS | 
 Where-Object {$_.PSChildname -match $PatternSID} | 
 Select-Object @{name="SID";expression={$_.PSChildName}}
 
 $UnloadedHives = Compare-Object $UserArray.SID $LoadedHives.SID | 
 Select-Object @{name="SID";expression={$_.InputObject}}, UserHive, Username
 
 Foreach ($User in $UserArray) {
    
    If ($User.SID -in $UnloadedHives.SID) {

        reg load HKU\$($User.SID) $($User.UserHive) | Out-Null
    }

    Get-ItemProperty registry::HKEY_USERS\$($User.SID)\Software\Microsoft\Windows\CurrentVersion\Uninstall\* | 
        ForEach-Object {"{0} {1}" -f "   Program:", $($_.DisplayName) | Write-Output}

    Get-ItemProperty registry::HKEY_USERS\$($Item.SID)\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* | 
        ForEach-Object {"{0} {1}" -f "   Program:", $($_.DisplayName) | Write-Output}
    
     
    
    If ($User.SID -in $UnloadedHives.SID) {
    
        ### Garbage collection and closing of ntuser.dat ###
        [gc]::Collect()
        reg unload HKU\$($User.SID) | Out-Null
    }
}