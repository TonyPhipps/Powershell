# Detecting Lateral Movement through Tracking Event Logs - JPCERT Coordination Center
# https://www.jpcert.or.jp/english/pub/sr/20170612ac-ir_research_en.pdf

# Appendix L: Events to Monitor
# https://docs.microsoft.com/en-us/windows-server/identity/ad-ds/plan/appendix-l--events-to-monitor

# Spotting the Adversary with Windows Event Log Monitoring 
# https://msdnshared.blob.core.windows.net/media/2017/10/Spotting_the_Adversary_with_Windows_Event_Log_Monitoring.pdf


$SecurityEvents = 
    1102, # The audit log was cleared
    4618, # A monitored security event pattern has occurred.
    4624, # An account was successfully logged on
    4625, # Failed Login
    4648, # Logon was Attempted with Explicit Credentials
    4649, # A replay attack was detected.
    4672, # Special privileges assigned to new logon
    4673, # A privileged service was called
    4688, # A new process has been created
    4697, # A service was installed in the system
    4698, # scheduled task creation
    4714, # Encrypted data recovery policy was changed.
    4715, # The audit policy (SACL) on an object was changed.
    4719, # System audit policy was changed.
    4720, # A user account was created
    4724, # An attempt was made to reset an account's password.
    4727, # A security-enabled global group was created.
    4728, # A member was added to a security-enabled global group
    4732, # A member was added to a security-enabled local group
    4735, # A security-enabled local group was changed.
    4737, # A security-enabled global group was changed.
    4738, # A user account was changed
    4740, # Account locked out
    4754, # A security-enabled universal group was created.
    4755, # A security-enabled universal group was changed.
    4776, # Successful /Failed Account Authentication
    4907, # Auditing settings on object were changed.
    4908, # Special Groups Logon table modified.
    4912, # Per User Audit Policy was changed.
    4946, # A change has been made to Windows Firewall exception list. A rule was added)
    4964, # Special groups have been assigned to a new logon.
    5142, # A network share object was added
    5447 # A Windows Filtering Platform filter has been changed
    
$SystemEvents = 
    104, # Event Log was Cleared 
    7030, # System, Service Creation Errors
    7034, # System, service terminated unexpectedly
    7036, # The [Service Name] service entered the [Status] state
    7040, # The service state has changed
    7045 # System, A service was installed in the system

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

$TaskSchedulerOperational =  # Microsoft-Windows-TaskScheduler/Operational
    106 # Task Scheduled