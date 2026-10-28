$Computers = "Server01", "Server02", "Server03"

Invoke-Command -ComputerName $Computers -ScriptBlock {
    $Pattern = '^(waterfall|a-node|apache)'
    
    Get-Service | Where-Name -Match $Pattern | ForEach-Object {
        # Capture original state
        $OriginalStatus    = $_.Status
        $OriginalStartType = $_.StartType

        # Disable the service startup type
        Set-Service -Name $_.Name -StartupType Disabled
        
        # Stop the service if currently running
        if ($_.Status -eq 'Running') {
            Stop-Service -Name $_.Name -Force -NoWait
        }

        # Refresh object to obtain updated state
        $_.Refresh()

        # Output detailed status report
        [PSCustomObject]@{
            ComputerName   = $env:COMPUTERNAME
            ServiceName    = $_.Name
            DisplayName    = $_.DisplayName
            PreviousStatus = $OriginalStatus
            PreviousStart  = $OriginalStartType
            CurrentStatus  = $_.Status
            CurrentStart   = $_.StartType
        }
    }
}