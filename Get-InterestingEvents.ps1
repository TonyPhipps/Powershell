$ApplicationEvents = 
    1000, # Application Error
    1001, # Windows Error Reporting
    1002 # Application Hang

$SysmonEvents = 
    1, # Process Create
    2, # File creation time changed
    5, # Process terminated
    8 # CreateRemoteThread detected

$PrintServiceOperational = # Microsoft-Windows-PrintService/Operational
    307 # Printing Document

$KernelPnP  = # Microsoft-Windows-Kernel-PnP/Device Configuration
    400, # New Mass Storage Installation
    410 # New Mass Storage Installation

$Powershell = # Windows Powershell
    800 # Pipeline Execution Details

$Forwarding = # Microsoft-Windows-Forwarding/Operational
    521 # Unable to forward