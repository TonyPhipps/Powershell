# Create the BitLocker FVE (Full Volume Encryption) key path if it doesn't exist
$RegPath = "HKLM:\SOFTWARE\Policies\Microsoft\FVE"
if (-not (Test-Path $RegPath)) {
    New-Item -Path $RegPath -Force | Out-Null
}

# Enable the requirement for additional authentication at startup
Set-ItemProperty -Path $RegPath -Name "UseAdvancedStartup" -Value 1 -Type DWord

# Configure the TPM startup PIN requirement (1 = Require startup PIN with TPM)
Set-ItemProperty -Path $RegPath -Name "UseTPMAndPIN" -Value 1 -Type DWord

# Ensure standard TPM, startup key, and TPM+Key options are compliant with the policy
Set-ItemProperty -Path $RegPath -Name "UseTPM" -Value 2 -Type DWord
Set-ItemProperty -Path $RegPath -Name "UseTPMAndKey" -Value 2 -Type DWord
Set-ItemProperty -Path $RegPath -Name "UseTPMAndKeyAndPIN" -Value 2 -Type DWord

# Securely prompt for the PIN in the console
$KeyProtector = Read-Host -AsSecureString "Enter your new BitLocker PIN"

# Apply the TPM and PIN protector to the operating system drive
Add-BitLockerKeyProtector -MountPoint "C:" -TpmAndPinProtector -Pin $KeyProtector

(Get-BitLockerVolume -MountPoint "C:").KeyProtector
