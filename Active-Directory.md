Find AD User by Name
```
Get-ADUser -filter {Name -like "Phipps*"} 
```

Find AD User by EDIPI
```
Get-ADUser -filter {UserPrincipalName -like "1265990947*"} 
```

Get All PCs in Active Directory
```
Get-ADComputer -filter * | Select DNSHostName
```

Get AD Properties of a single system
```
Get-ADComputer -Filter {Name -like "coll64447gv"} -Properties *
Get-ADComputer -LDAPFilter '(Name=coll64447gv)' -Properties *

```

Get list of Active PCs in Active Directory
```
$LastActiveDate = (Get-Date).Adddays(-(30)) 

$ActiveComputers = Get-ADComputer -Filter {LastLogonTimeStamp -gt $LastActiveDate -and Enabled -eq $True -and OperatingSystem -like "*Windows*"} -Properties DNSHostName, IPv4Address, Enabled, OperatingSystem, OperatingSystemVersion, LastLogonDate
```

Get All Users of a Group, Recursively
```
$Members = Get-AdGroupMember 'J614 Cyber Emergency Response Team - (ALL)' -Recursive
$Members | 
  Get-ADUser -Property Name, EmailAddress, UserPrincipalName | 
  Select Name, EmailAddress, UserPrincipalName | 
  Export-csv C:\Users\c014736\Desktop\CERT.csv -NoTypeInformation
```

Get Exchange Servers
```
Get-ADComputer -Filter * -Properties * | Where-Object {$_.ServicePrincipalName -like '*exchange*'} | Select-Object name
```
