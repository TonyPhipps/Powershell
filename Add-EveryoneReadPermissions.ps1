# A hacky solution to get access to files from a privileged user profile without accepting a significant amount of risk.

$path = "C:\Users\Administrator\Desktop"
$path = "C:\Users\Administrator\Downloads"
$path = "C:\Users\Administrator\Documents"

$ACL = Get-ACL -Path $path
$AccessRule = New-Object System.Security.AccessControl.FileSystemAccessRule("Everyone","Read","Allow")
$ACL.SetAccessRule($AccessRule)
$ACL | Set-Acl -Path $path
(Get-ACL -Path $path).Access | Format-Table IdentityReference,FileSystemRights,AccessControlType,IsInherited,InheritanceFlags -AutoSize
