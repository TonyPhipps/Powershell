Query a for a registry value's data at the given key
```
$key = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\EventLog\EventForwarding\SubscriptionManager"
$value = "1"
$data = (Get-ItemProperty -path $key).$value
$data
```
