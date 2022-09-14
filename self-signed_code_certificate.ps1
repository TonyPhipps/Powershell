# Demonstrates how to create a self-signed code signing cert, add it to the trusted root certs, and sign a file with it.

$Params = @{    
Subject           = "CN=Code Signing"
Type              = "CodeSigningCert"    
KeySpec           = "Signature"     
KeyUsage          = "DigitalSignature"    
FriendlyName      = "Test code signing"    
NotAfter          = [datetime]::now.AddYears(5)    
CertStoreLocation = 'Cert:\CurrentUser\My' }

$CodeSigningCert = New-SelfSignedCertificate @Params

# Export public key
Export-Certificate -FilePath public_cert.cer -Cert $CodeSigningCert

# Import public key to trusted root
Import-Certificate -FilePath public_cert.cer -CertStoreLocation Cert:\CurrentUser\My
Get-ChildItem Cert:\CurrentUser\My

# Export private key
$pwd = read-host -assecurestring
Export-PfxCertificate -cert $CodeSigningCert -FilePath private_cert.pfx -Password $pwd

# Apply cert to file
$file = 'C:\file.ps1'
Set-AuthenticodeSignature -Certificate (Get-PfxCertificate private_cert.pfx) -FilePath $file

# Remove from key store (cleanup)
Get-ChildItem Cert:\CurrentUser\My |
Where-Object { $_.Subject -match 'Code Signing' } |
Remove-Item
