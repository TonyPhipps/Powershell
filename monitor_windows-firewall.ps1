Set-NetFirewallProfile -LogAllowed True
Set-NetFirewallProfile -LogBlocked True
Set-NetFirewallProfile -LogIgnored True
Get-Content c:\windows\system32\LogFiles\Firewall\pfirewall.log -tail 1 -wait