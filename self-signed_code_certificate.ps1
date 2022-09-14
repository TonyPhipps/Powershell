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
Export-Certificate -Cert $CodeSigningCert -FilePath public_cert.cer

# Import public key to trusted root
Import-Certificate -CertStoreLocation Cert:\CurrentUser\Root -FilePath public_cert.cer
Get-ChildItem Cert:\CurrentUser\Root

# Export private key
$pwd = read-host -assecurestring
Export-PfxCertificate -cert $CodeSigningCert -FilePath private_cert.pfx -Password $pwd

# Apply cert to file
$file = 'C:\file.ps1'
Set-AuthenticodeSignature -Certificate (Get-PfxCertificate private_cert.pfx) -FilePath $file

# Remove from key store (cleanup)
Get-ChildItem Cert:\CurrentUser\Root |
Where-Object { $_.Subject -match 'Code Signing' } |
Remove-Item
