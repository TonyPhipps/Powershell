# Connect to Exchange Online with MFA
# https://outlook.office365.com/ecp > Hybrid > "The Exchange Online PowerShell Module..." > Configure > Install
Uninstall-Module ExchangeOnlineManagement
Install-Module ExchangeOnlineManagement
Import-Module ExchangeOnlineManagement

# Connect to Exchange Online (Single Factor)
$UserCredential = Get-Credential
Connect-ExchangeOnline -Credential $UserCredential -ShowProgress $true

# Connect to Exchange Online (MFA)
Connect-EXOPSSession -UserPrincipalName user@email.com

# Get Litigation Hold Status
Get-Mailbox user@tdomain.com | Format-List *lit*

# Get inbox rules
Get-InboxRule -Mailbox "[email@address.com]" | Select Name, Description, Enabled, Priority, ForwardTo, ForwardAsAttachmentTo, RedirectTo, DeleteMessage 

# Update Recipient Limits on a single mailbox
Set-Mailbox kimakers@contoso.com -RecipientLimits 20
 
# Update  Recipient Limits on multiple mailboxes
(Get-Mailbox | where {$_.RecipientTypeDetails -ne "DiscoveryMailbox"}) | % {Set-Mailbox $_.Identity -RecipientLimits 10}
 
# Update the default  Recipient Limits for new mailboxes created in the future (all plans, tenant-level)
Get-MailboxPlan | Set-MailboxPlan -RecipientLimits 50
Set-TransportConfig -MaxRecipientEnvelopeLimit 50

# Get UnifiedAuditLog, last 365 days
$mailbox="tony@company.com"
$StartDate = (Get-Date).AddDays(-365)
$EndDate = get-date
$UnifiedAuditLog = Search-UnifiedAuditLog -UserIds $mailbox -StartDate $StartDate -EndDate $EndDate -SessionCommand ReturnLargeSet -ResultSize 5000
$UnifiedAuditLog | Select-Object CreationDate, UserIDs, Operations, AuditData | Export-Csv ($mailbox + "_UnifiedAuditLog.csv") -NoTypeInformation
