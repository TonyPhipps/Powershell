# Enable WinRM Option 1
winrm quickconfig -y

# Enable WinRM Option 2
Enable-PSRemoting -SkipNetworkProfileCheck -Force

# Enable WinRM Option 3
## Start the WinRM service. 
(get-service winrm).start()
## Set the WinRM service type to delayed auto start.
set-service winrm -startuptype "Automatic"
## Configure LocalAccountTokenFilterPolicy to grant administrative rights remotely to local users.
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name LocalAccountTokenFilterPolicy -Value 1

# Enable WinRM Option 4
## Run winrm quickconfig on a remote system
PsExec.exe -s \\SomeComputer -accepteula powershell -ExecutionPolicy ByPass -nologo -command "& winrm quickconfig -y"

# Dealing with the error
#     "WinRM firewall exception will not work since one of	the network connection types on this machine is set to Public. Change the network connection type to either Domain or Private and try again."
Set-NetConnectionProfile -InterfaceIndex ((Get-NetConnectionProfile).InterfaceIndex) -NetworkCategory Private

# Dealing with the error
#     "The following error with errorcode 0x8009030e occurred while using Kerberos authentication: A specified logon session does not exist. It may already have been terminated."
set-item WSMan:\localhost\Client\TrustedHosts "*.contoso.com"
set-item WSMan:\localhost\Client\TrustedHosts "192.168.1.3"
