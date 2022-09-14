# Demonstrates how to create a self-signed code signing cert, add it to the trusted root certs, and sign a file with it.

$Params = @{    
Subject           = "CN=Test Code Signing"
Type              = "CodeSigningCert"    
KeySpec           = "Signature"     
KeyUsage          = "DigitalSignature"    
FriendlyName      = "Test code signing"    
NotAfter          = [datetime]::now.AddYears(5)    
CertStoreLocation = 'Cert:\CurrentUser\My' }

$TestCodeSigningCert = New-SelfSignedCertificate @Params

Export-Certificate -FilePath exported_cert.cer -Cert $TestCodeSigningCert
Import-Certificate -FilePath exported_cert.cer -CertStoreLocation Cert:\CurrentUser\Root


$file = 'c:\path\to\file.ps1'
Set-AuthenticodeSignature -Certificate $TestCodeSigningCert -FilePath $file



