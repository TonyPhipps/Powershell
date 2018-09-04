$properties=@(
    @{Name="Process Name"; Expression = {$_.name}},
    @{Name="CPU"; Expression = {$_.PercentProcessorTime}},    
    @{Name="Memory"; Expression = {[Math]::Round(($_.workingSetPrivate / 1mb),2)}})
    
Get-WmiObject -class Win32_PerfFormattedData_PerfProc_Process | select $properties | sort CPU -Descending
