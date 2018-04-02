# Detecting Lateral Movement through Tracking Event Logs - JPCERT Coordination Center
# https://www.jpcert.or.jp/english/pub/sr/20170612ac-ir_research_en.pdf

$SecurityEvents = 
    1102, # Event Log was cleared
    4624, # An account was successfully logged on
    4625, # Failed Login
    4648, # Logon was Attempted with Explicit Credentials
    4688, # A new process has been created
    4672, # Special privileges assigned to new logon
    4673, # A privileged service was called
    4697, # A service was installed in the system
    4698, # scheduled task creation
    4720, # A user account was created
    4728, # A member was added to a security-enabled global group
    4732, # A member was added to a security-enabled local group
    4776, # Successful /Failed Account Authentication
    4946, # A change has been made to Windows Firewall exception list. A rule was added)
    5140, # A network share object was accessed
    5142, # A network share object was added
    5447 # A Windows Filtering Platform filter has been changed
    
$SystemEvents = 
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