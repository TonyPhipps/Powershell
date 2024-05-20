Enable WinRM Option 1
```
winrm quickconfig -y
```

Enable WinRM Option 2
```
Enable-PSRemoting -SkipNetworkProfileCheck -Force
```

Enable WinRM Option 3
```
## Start the WinRM service. 
(get-service winrm).start()
## Set the WinRM service type to delayed auto start.
set-service winrm -startuptype "Automatic"
## Configure LocalAccountTokenFilterPolicy to grant administrative rights remotely to local users.
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name LocalAccountTokenFilterPolicy -Value 1
```

Enable WinRM Option 4
```
## Run winrm quickconfig on a remote system
PsExec.exe -s \\SomeComputer -accepteula powershell -ExecutionPolicy ByPass -nologo -command "& winrm quickconfig -y"
```

Dealing with the error:
*"WinRM firewall exception will not work since one of	the network connection types on this machine is set to Public. Change the network connection type to either Domain or Private and try again."*
```
# On both the CLIENT and SERVER system, run this
Set-NetConnectionProfile -InterfaceIndex ((Get-NetConnectionProfile).InterfaceIndex) -NetworkCategory Private
```

Dealing with the error:
*"The following error with errorcode 0x8009030e occurred while using Kerberos authentication: A specified logon session does not exist. It may already have been terminated."*
```
# On the CLIENT system, run this
set-item WSMan:\localhost\Client\TrustedHosts "*.contoso.com"
set-item WSMan:\localhost\Client\TrustedHosts "192.168.1.3"
```


# Allow WinRM wiht Least Privilege
**1. Remote Management Users**
```localgroup "Remote Management Users" /add someuser```

If  you need to provide such permissions on multiple computers, you can use Group Policy.
- Navigate to ```Computer Configuration > Windows Settings > Security Settings > Restricted Groups```
- Add the Remote Management Users group.
- Add the users or groups that need to be granted access to WinRM/WMI.

**2. Configuring WMI remote access on the target computer**
- Using an administrator account, logon the computer you want to monitor.
- Go to ```Start > Control Panel > Administrative Tools > Computer Management > Services and Applications```.
- Click WMI control, right-click, and then select Properties.
- Select the Security tab, expand Root, and then click CIMV2.
  - Repeat the steps, also, for StandardCimv2
- Click Security and then select the user account used to access this computer. Ensure you grant the following permissions: Enable Account and Remote Account.
- Click Advanced, and then select the user account used to access this computer.
- Click Edit, select this namespace and subnamespaces in the Apply to
- field, and then click OK.
- Click OK to close the Advanced Security Settings for CIMV2 window.
- Click OK to close the Security for Root\CIMV2 window.
- In the left navigation pane of Computer Management, click Services.
- In the Services result pane, select Windows Management Instrumentation, and then click Restart.


**3. Using a non-admin local or domain account (this must be configured on each system from which you want to monitor WMI counters)**

A non-admin domain or local account requires additional permissions to access Win32.service.name.instance. Without the following update to the Microsoft service control manager settings, NTservice monitors do not work with an account using reduced privileges.

- Click Start > Run.
- Type cmd, and then click OK.
- At the command prompt, type the following. This has to be applied to any devices you are monitoring.
```
sc sdset SCMANAGER D:(A;;CCLCRPRC;;;AU)(A;;CCLCRPWPRC;;;SY)(A;;KA;;;BA)S:(AU;FA;KA;;;WD)(AU;OIIOFA;GA;;;WD)
```

**4. Deny Local Logon**
- Navigate to ```Computer Configuration-> Windows Settings->Security Settings->Local Policies->User Rights Assignment```.
- Double click “Deny Log on locally”.
