# Option 1
# Shortest route
winrm quickconfig -y
# or
Enable-PSRemoting –Force

# Option 2
# Same as above, but more "manual"
# Start the WinRM service. 
(get-service winrm).start()
# Set the WinRM service type to delayed auto start.
set-service winrm -startuptype "Automatic"
# Configure LocalAccountTokenFilterPolicy to grant administrative rights remotely to local users.
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name LocalAccountTokenFilterPolicy -Value 1

# Option 3
# Run winrm quickconfig on a remote system
PsExec.exe -s \\SomeComputer -accepteula powershell -ExecutionPolicy ByPass -nologo -command "& winrm quickconfig -y"