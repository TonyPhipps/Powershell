# Renames .jpg files to the date they were taken, according to EXIF metadata

Get-ChildItem *.jpg | ForEach-Object {
    
    $pic = New-Object System.Drawing.Bitmap($_.FullName)
    try {
        $DateTakenRaw = $pic.GetPropertyItem(36867).Value
    }
    catch{Write-Verbose("{0} no saved date taken time" -f $_.FullName)}
    finally{}

    $DateTakenString = [System.Text.Encoding]::ASCII.GetString($DateTakenRaw)
    $DateTakenParsed = [datetime]::ParseExact($DateTakenString, "yyyy:MM:dd HH:mm:ss`0", $Null)
    $DateTakenParsed

    $pic.Dispose()

    if ($DateTakenParsed) {
        $NewName = ("{0:yyyy-MM-dd_HH-mm-ss}_{1}{2}" -f $DateTakenParsed, $_.Length, $_.Extension)
        rename-item $_.FullName $NewName.ToLower() -Force
    }
}
