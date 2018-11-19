Get-ChildItem C:\temp\test\*.jpg | ForEach-Object {

    $FileName = $_.FullName

	$null = [reflection.assembly]::LoadWithPartialName("System.Drawing")
    
    $pic = New-Object System.Drawing.Bitmap($FileName)

    try {$DateTakenRaw = $pic.GetPropertyItem(36867).Value} catch {}

	if ($DateTakenRaw) {

        $DateTakenString = [System.Text.Encoding]::ASCII.GetString($DateTakenRaw)
        $DateTakenParsed = [datetime]::ParseExact($DateTakenString, "yyyy:MM:dd HH:mm:ss`0", $Null)
        $pic.Dispose()

    }
    else {
        
        # Fall back to LastWriteTime
		$DateTakenParsed = $_.LastWriteTime
	}

	$NewName = ("{0:yyyy-MM-dd_HH-mm-ss}_{1}{2}" -f $DateTakenParsed, $_.Length, $_.Extension)

	rename-item $FileName $NewName.ToLower() -Force
}