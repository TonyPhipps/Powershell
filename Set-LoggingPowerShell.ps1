# Enable Audit Process Creation
New-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa\AuditPolicy" -Name "AuditProcessCreation" -Value "1" -PropertyType DWord

# Enable Command Line Auditing
New-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" -Name "IncludeCommandLineInProcessCreationEvents" -Value "1" -PropertyType DWord


