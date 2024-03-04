Monitor Logs
```
Set-NetFirewallProfile -LogAllowed True
Set-NetFirewallProfile -LogBlocked True
Set-NetFirewallProfile -LogIgnored True
Get-Content c:\windows\system32\LogFiles\Firewall\pfirewall.log -tail 1 -wait
```


Set all firewall rules applied to Public profile with Inbound to Private only
```
Get-NetFirewallRule | 
Where-Object { $_.Profile -like 'Public' -and $_.Direction -like 'Inbound'} | 
Set-NetFirewallRule -Profile "Private"
```