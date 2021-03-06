# Renames .jpg files to the date they were taken, according to EXIF metadata

Get-ChildItem *.jpg | ForEach-Object {

    $FileName = $_.FullName

	$null = [reflection.assembly]::LoadWithPartialName("System.Drawing")
    
    $pic = New-Object System.Drawing.Bitmap($FileName)

    try {
        $DateTakenRaw = $pic.GetPropertyItem(36867).Value
        $DateTakenString = [System.Text.Encoding]::ASCII.GetString($DateTakenRaw)
        $DateTakenParsed = [datetime]::ParseExact($DateTakenString, "yyyy:MM:dd HH:mm:ss`0", $Null)
        $pic.Dispose()
        Write-Verbose $DateTakenParsed
    }
    catch {}
    finally {
        if ($DateTakenRaw) {

            $NewName = ("{0:yyyy-MM-dd_HH-mm-ss}_{1}{2}" -f $DateTakenParsed, $_.Length, $_.Extension)
            rename-item $FileName $NewName.ToLower() -Force
        }
    }
}
