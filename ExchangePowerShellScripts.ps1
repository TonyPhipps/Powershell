# Get Litigation Hold Status
Get-Mailbox user@tdomain.com | Format-List *lit*

# Get inbox rules
Get-InboxRule -Mailbox "[email@address.com]" | Select Name, Description, Enabled, Priority, ForwardTo, ForwardAsAttachmentTo, RedirectTo, DeleteMessage 
