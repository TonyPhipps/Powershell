#Start the WinRM service. 
(get-service winrm).start()
#Set the WinRM service type to delayed auto start.
set-service winrm -startuptype "Automatic"
#Configure LocalAccountTokenFilterPolicy to grant administrative rights remotely to local users.
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name LocalAccountTokenFilterPolicy -Value 1