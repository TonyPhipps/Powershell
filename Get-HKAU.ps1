$UserKeys =
            # Need a loop to parse HKU to gather below keys for each user on the system
            "\Software\Microsoft\Windows\CurrentVersion\RunServicesOnce",
            "\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\RunServicesOnce",
            "\Software\Microsoft\Windows\CurrentVersion\RunServices",
            "\Software\Microsoft\Windows NT\CurrentVersion\Winlogon\Shell",
            "\Software\Microsoft\Windows\CurrentVersion\Run",
            "\Software\Microsoft\Windows\CurrentVersion\RunOnce",
            "\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer\Run",
            "\Software\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run",
            "\Software\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run32",            
            "\Software\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\StartupFolder",
            "\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders",
            "\Software\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders",
            "\Software\Microsoft\Windows NT\CurrentVersion\Windows\load"


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
 
 $OutputArray = @()

 Foreach ($User in $UserArray) {
    
    If ($User.SID -in $UnloadedHives.SID) {

        reg load HKU\$($User.SID) $($User.UserHive) | Out-Null
    }

    foreach ($Key in $UserKeys){

        $Key = "Registry::HKEY_USERS\$($User.SID)" + $Key

        if (Test-Path $Key){

            $KeyObject = Get-Item $Key
                    
            $Properties = $KeyObject.Property
                    
            if ($Properties) { 
                    
                foreach ($Property in $Properties){
                    
                    $OutputArray += [pscustomobject] @{
                        Key = $Key.Split(":")[2]
                        Value = $Property 
                        Data = $KeyObject.GetValue($Property)
                    }
                }  
            }
        }
    }
    
    If ($User.SID -in $UnloadedHives.SID) {
        ### Garbage collection and closing of ntuser.dat ###

        [gc]::Collect()
        reg unload HKU\$($User.SID) | Out-Null
    }

    $OutputArray
}