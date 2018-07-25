# Opens Powershell ISE as administrator under alternate credentials. Window will show Administrator:,
# but with alternate administrative credentials. Often necessary where least privilege is desired,
# like logging in as user, then elevating to an administrator with Runas.

$Account = "domain\service_account"
$Credential = Get-Credential $Account
Start-Process $PsHome\powershell.exe -Credential $Credential -ArgumentList "-Command Start-Process $PSHOME\powershell_ise.exe -Verb Runas" -Wait