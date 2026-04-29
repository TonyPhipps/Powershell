Monitor Logs
```
Set-NetFirewallProfile -All -LogFileName "C:\Windows\System32\LogFiles\Firewall\pfirewall.log" -LogAllowed True -LogBlocked True
Get-Content c:\windows\system32\LogFiles\Firewall\pfirewall.log -tail 1 -wait
```
When done:
```
Set-NetFirewallProfile -All -LogAllowed False -LogBlocked False
```


Set all firewall rules applied to Public profile with Inbound to Private only
```
Get-NetFirewallRule | 
Where-Object { ($_.Profile -like 'Any' -or $_.Profile -like 'Public') -and $_.Direction -like 'Inbound' -and $_.Action -like 'Allow'} | 
Set-NetFirewallRule -Profile "Private"

```