ForEach ($Volume in Get-BitLockerVolume) {
    $Volume | Add-Member -MemberType NoteProperty -Name Key -Value ((Get-BitLockerVolume).KeyProtector.RecoveryPassword[1])
    $Volume | Select-Object *
}
