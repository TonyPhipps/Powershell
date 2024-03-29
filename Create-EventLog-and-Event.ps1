# Working with New Event Logs and saving Events to them
# https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.management/new-eventlog
# https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.management/write-eventlog
# https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.management/remove-eventlog

function Deploy-EventLog{
[CmdletBinding()]
	param(
        [Parameter()]
		[string]$LogName,		

        [Parameter()]
		[string]$Source,

        [Parameter()]
		[string]$EventID,

        [Parameter()]
		[string]$EntryType,

        [Parameter()]
		[string]$Category,

        [Parameter()]
		[string]$Message,

        [Parameter()]
		[string]$RawData
	)

    if ($RawData){
        [byte[]]$RawData = $RawData.split(",")
    }

    if (Get-EventLog -list | Where-Object {$_.logdisplayname -eq $LogName}) {
        
        Write-Verbose ("Log '{0}' already exists..." -f $source)

    } else { 
        
        Write-Verbose "The log does not already exist."
        New-EventLog -LogName $LogName -Source $Source
        Write-Verbose ("Log '{0}' created!" -f $LogName)
    }

    if (Get-EventLog -list | Where-Object {$_.logdisplayname -eq $LogName}) {
        
        Write-Verbose ("Log '{0}' already exists..." -f $Source)
        Write-EventLog -LogName $LogName -Source $Source -EventID $EventID -EntryType $EntryType -Category $Category -Message ($Message[00.32000] -join "") -RawData $RawData

    } else { 
        
        Write-Verbose "The log does not already exist, and could not be created."
    }
}

Deploy-EventLog -logname "TestLog" -source "TestApp" -EventID 1 -EntryType "Information" -Category 1 -Message "MyApp added a user-requested feature to the display." -RawData "10,20"
Deploy-EventLog -logname "TestLog" -source "TestApp" -EventID 2 -EntryType "Information" -Category 4 -Message "An event without RawData!"
Deploy-EventLog -logname "TestLog" -source "TestApp" -EntryType "Information" -Message "An event with the bare basics."

Remove-EventLog -LogName "TestLog"
