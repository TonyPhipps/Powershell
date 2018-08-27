ForEach ($Volume in Get-BitLockerVolume) {
    $Volume | Add-Member -MemberType NoteProperty -Name Key -Value (($Volume).KeyProtector.RecoveryPassword[1])
    $Volume | Select-Object *
}
