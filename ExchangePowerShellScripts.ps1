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
