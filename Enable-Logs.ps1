$LogNamesArray = @(
    "Microsoft-Windows-DriverFrameworks-UserMode/Operational"
)

foreach ($LogName in $LogNamesArray){
    
    $Log = New-Object System.Diagnostics.Eventing.Reader.EventLogConfiguration $LogName
    $Log.IsEnabled = $true
    
    $Log.SaveChanges()
}

