# Working with New Event Logs and saving Events to them
# https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.management/new-eventlog
# https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.management/write-eventlog
# https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.management/remove-eventlog

function Prepare-EventLog{
[CmdletBinding()]
	param(
        [Parameter()]
		[string]$logname,		

        [Parameter()]
		[string]$source,

        [Parameter()]
		[string]$file
	)

    if (Get-EventLog -list | Where-Object {$_.logdisplayname -eq $logname}) {
        Write-Verbose ("Log '{0}' already exists..." -f $source)
    } else { 
        Write-Verbose "The log does not already exist."
        New-EventLog -source $source -LogName $logname -MessageResourceFile $file
        Write-Verbose ("Log '{0}' created!" -f $source)
    }
}

Prepare-EventLog  -logname "TestLog" -source "TestApp" -file "C:\Test\TestApp.dll"

Write-EventLog -LogName "TestLog" -Source "TestApp" -EventID 1 -EntryType Information -Category 1 -Message "MyApp added a user-requested feature to the display." -RawData 10,20
Write-EventLog -LogName "TestLog" -Source "TestApp" -EventID 1 -EntryType Information -Category 1 -Message "Just a Message, no binary data needed!"

Remove-EventLog -LogName "TestLog"
