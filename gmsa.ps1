# Check which endpoints can access the gMSA password
```
(Get-ADServiceAccount gMSA_Name -Properties PrincipalsAllowedToRetrieveManagedPassword).PrincipalsAllowedToRetrieveManagedPassword
```

# Add to gMSA's PrincipalsAllowedToRetrieveManagedPassword
```
$strGMSA = ""
$NewUser = ""
$NewComputer = ""
[array]$arrGetMgdPasswd = (Get-ADServiceAccount $strGMSA -Properties PrincipalsAllowedToRetrieveManagedPassword).PrincipalsAllowedToRetrieveManagedPassword
$arrGetMgdPasswd += (Get-ADUser $NewUser).DistinguishedName
$arrGetMgdPasswd += (Get-ADComputer $NewComputer).DistinguishedName
Set-ADServiceAccount $strGMSA -PrincipalsAllowedToRetrieveManagedPassword $arrGetMgdPasswd
```
