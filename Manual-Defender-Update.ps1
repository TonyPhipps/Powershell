Get-MpComputerStatus | Select-Object AMProductVersion, AMServiceVersion, AMEngineVersion, AntivirusSignatureVersion
Get-MpPreference | Select-Object SignatureDefinitionUpdateFileSharesSources, SignatureFallbackOrder
Get-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender" -Name "DisableAntiSpyware"
Get-ChildItem "C:\ProgramData\Microsoft\Windows Defender\Platform\"
Start-Process -FilePath "\\yourhost\DefenderUpdates\updateplatform.amd64fre_ef488e855b50b875137a5d335e4a6a76c186992a.exe" -ArgumentList "/quiet /norestart" -Wait
$sigFile = "\\ICS-SV22-Update\DefenderUpdates\x64\mpam-fe.exe"
(Get-Item $sigFile).VersionInfo | Select-Object FileVersion, ProductVersion
Update-MpSignature -UpdateSource FileShares
Start-Process "\\yourhost\DefenderUpdates\x64\mpam-fe.exe" -ArgumentList "-mpsigstub" -Wait
Get-MpComputerStatus | Select-Object AMProductVersion, AMServiceVersion, AMEngineVersion, AntivirusSignatureVersion
