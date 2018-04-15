# Detecting Lateral Movement through Tracking Event Logs - JPCERT Coordination Center
# https://www.jpcert.or.jp/english/pub/sr/20170612ac-ir_research_en.pdf

# Appendix L: Events to Monitor
# https://docs.microsoft.com/en-us/windows-server/identity/ad-ds/plan/appendix-l--events-to-monitor

# Spotting the Adversary with Windows Event Log Monitoring 
# https://msdnshared.blob.core.windows.net/media/2017/10/Spotting_the_Adversary_with_Windows_Event_Log_Monitoring.pdf

# MicrosoftDocs/windowsserverdocs
# https://github.com/MicrosoftDocs/windowsserverdocs/blob/master/WindowsServerDocs/identity/ad-ds/plan/Appendix-L--Events-to-Monitor.md

# Use one of these arrays to filter a list of events:
# Where-Object ({ $SecurityEvents -match $_.EventID })

$ApplicationEvents = 
    1000, # Application Error
    1001, # Windows Error Reporting
    1002 # Application Hang

$SecurityEvents = 
    1100, # Event Log Service shutdown
    1102, # Audit log cleared
    4618, # Monitored security event pattern occurred
    4621, # Administrator recovered system from CrashOnAuditFail. Users who are not administrators will now be allowed to log on. Some auditable activity might not have been recorded.
    4624, # Account successfully logged on
    4625, # Failed Login
    4634, # Logoff
    4648, # Logon Attempted with Explicit Credentials
    4649, # Replay attack detected
    4657, # Registry value modified
    4672, # Special privileges assigned to new logon
    4673, # Privileged service called
    4688, # New process created
    4689, # Process terminated
    4692, # Backup of data protection master key attempted
    4693, # Recovery of data protection master key attempted
    4697, # Service installed
    4698, # Scheduled task creation
    4699, # Scheduled task deleted
    4700, # Scheduled task enabled
    4701, # Scheduled task disabled
    4702, # Scheduled task updated
    4706, # New trust was created to a domain
    4713, # Kerberos policy changed
    4714, # Encrypted data recovery policy changed
    4715, # Audit policy (SACL) on an object changed
    4716, # Trusted domain information modified
    4719, # System audit policy changed
    4720, # User account created
    4724, # Attempt to reset an account password
    4727, # Security-enabled global group was created
    4728, # Member was added to a security-enabled global group
    4732, # Member was added to a security-enabled local group
    4735, # Security-enabled local group was changed
    4737, # Security-enabled global group changed
    4738, # User account changed
    4739, # Domain Policy changed
    4740, # Account locked out
    4754, # Security-enabled universal group created
    4755, # Security-enabled universal group changed
    4764, # Group type changed
    4765, # SID History was added to an account
    4766, # Attempt to add SID History to an account failed
    4767, # Account Unlocked
    4776, # Successful /Failed Account Authentication
    4794, # Attempt  made to set the Directory Services Restore Mode
    4780, # ACL set on accounts which are members of administrators groups
    4816, # RPC detected an integrity violation while decrypting an incoming message
    4865, # Trusted forest information entry added
    4866, # Trusted forest information entry removed
    4867, # Trusted forest information entry modified
    4868, # Certificate manager denied a pending certificate request
    4976, # During Main Mode negotiation, IPsec received an invalid negotiation packet If this problem persists, it could indicate a network issue or an attempt to modify or replay this negotiation
    4977, # During Quick Mode negotiation, IPsec received an invalid negotiation packet If this problem persists, it could indicate a network issue or an attempt to modify or replay this negotiation
    4978, # During Extended Mode negotiation, IPsec received an invalid negotiation packet If this problem persists, it could indicate a network issue or an attempt to modify or replay this negotiation
    4882, # Security permissions for Certificate Services changed
    4983, # IPsec Extended Mode negotiation failed corresponding Main Mode security association has been deleted
    4984, # IPsec Extended Mode negotiation failed corresponding Main Mode security association has been deleted
    4885, # Audit filter for Certificate Services changed
    4890, # Certificate manager settings for Certificate Services changed

    4892, # Property of Certificate Services changed
    4896, # One or more rows have been deleted from the certificate database
    4897, # Role separation enabled
    4906, # CrashOnAuditFail value has changed
    4907, # Auditing settings on object changed
    4908, # Special Groups Logon table modified
    4912, # Per-User Audit Policy changed
    4946, # Windows Firewall exception list change
    4960, # IPsec dropped an inbound packet that failed an integrity check If this problem persists, it could indicate a network issue or that packets are being modified in transit to this computer Verify that the packets sent from the remote computer are the same as those received by this computer This error might also indicate interoperability problems with other IPsec implementations
    4961, # IPsec dropped an inbound packet that failed a replay check If this problem persists, it could indicate a replay attack against this computer
    4962, # IPsec dropped an inbound packet that failed a replay check inbound packet had too low a sequence number to ensure it not a replay
    4963, # IPsec dropped an inbound clear text packet that should have been secured This is usually due to the remote computer changing its IPsec policy without informing this computer This could also be a spoofing attack attempt
    4964, # Special groups assigned to a new logon
    4965, # IPsec received a packet from a remote computer with an incorrect Security Parameter Index (SPI) This is usually caused by malfunctioning hardware that is corrupting packets If these errors persist, verify that the packets sent from the remote computer are the same as those received by this computer This error may also indicate interoperability problems with other IPsec implementations In that case, if connectivity is not impeded, then these events can be ignored
    5027, # Windows Firewall Service unable to retrieve the security policy from the local storage service will continue enforcing the current policy
    5028, # Windows Firewall Service unable to parse the new security policy service will continue with currently enforced policy
    5029, # Windows Firewall Service failed to initialize the driver service will continue to enforce the current policy
    5030, # Windows Firewall Service failed to start
    5035, # Windows Firewall Driver failed to start
    5037, # Windows Firewall Driver detected critical runtime error Terminating
    5038, # Code integrity determined that the image hash of a file is not valid file could be corrupt due to unauthorized modification or the invalid hash could indicate a potential disk device error
    5120, # OCSP Responder Service Started
    5121, # OCSP Responder Service Stopped
    5122, # Configuration entry changed in OCSP Responder Service
    5123, # Configuration entry changed in OCSP Responder Service
    5124, # Security setting  updated on the OCSP Responder Service
    5140, # Network share object accessed
    5142, # Network share object added
    5143, # Network share object changed
    5144, # Network share object deleted
    5376, # Credential Manager credentials were backed up
    5377, # Credential Manager credentials were restored from a backup
    5447, # Windows Filtering Platform filter changed
    5453, # IPsec negotiation with a remote computer failed because the IKE and AuthIP IPsec Keying Modules (IKEEXT) service is not started
    5480, # IPsec Services failed to get the complete list of network interfaces on the computer This poses a potential security risk because some of the network interfaces may not get the protection provided by the applied IPsec filters Use the IP Security Monitor snap-in to diagnose the problem
    5483, # IPsec Services failed to initialize RPC server IPsec Services could not be started
    5484, # IPsec Services has experienced a critical failure and has been shut down shutdown of IPsec Services can put the computer at greater risk of network attack or expose the computer to potential security risks
    5485, # IPsec Services failed to process some IPsec filters on a plug-and-play event for network interfaces This poses a potential security risk because some of the network interfaces may not get the protection provided by the applied IPsec filters Use the IP Security Monitor snap-in to diagnose the problem
    6145, # One or more errors occurred while processing security policy in the Group Policy objects
    6273, # Network Policy Server denied access to a user
    6274, # Network Policy Server discarded the request for a user
    6275, # Network Policy Server discarded the accounting request for a user
    6276, # Network Policy Server quarantined a user
    6277, # Network Policy Server granted access to a user but put it on probation because the host did not meet the defined health policy
    6278, # Network Policy Server granted full access to a user because the host met the defined health policy
    6279, # Network Policy Server locked the user account due to repeated failed authentication attempts
    6280, # Network Policy Server unlocked the user account
    24586, # Error encountered converting volume
    24592, # Attempt to automatically restart conversion on volume %2 failed
    24593, # Metadata write: Volume %2 returning errors while trying to modify metadata If failures continue, decrypt volume
    24594 # Metadata rebuild: attempt to write a copy of metadata on volume %2 failed and may appear as disk corruption If failures continue, decrypt volume
    
$SystemEvents = 
    104, # Event Log was Cleared 
    7030, # Service Creation Errors
    7024, # Service terminated with service-specific error
    7031, # Service terminated unexpectedly, corrective action taken
    7034, # Service terminated unexpectedly
    7036, # [Service Name] service entered the [Status] state
    7040, # Service state changed
    7045 # Service installed

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
    106, # Task Scheduled
    141 # Task Removed
    200 # Task Executed

$Powershell = # Windows Powershell
    800, # Pipeline Execution Details
    
    24577 # Powershell script ran

$PowerShellOperational = # Microsoft-Windows-PowerShell/Operational
    4103, # Pipeline executed
    4104, # Scriptblock executed
    40962 # PowerShell Console Startup

$Forwarding = # Microsoft-Windows-Forwarding/Operational
    521 # Unable to forward