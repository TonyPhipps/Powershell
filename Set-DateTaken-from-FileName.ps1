# Define the target directory
$directory = "E:\temp\pics\test"

# Define the pattern to extract the date from filenames
#$dateTimePattern = "(\d{4})(\d{2})(\d{2})_(\d{2})(\d{2})(\d{2})" # Example: 20210720_200601_1177536
$dateTimePattern = "(\d{4})-(\d{2})-(\d{2})_(\d{2})-(\d{2})-(\d{2})" # Example: 2021-07-20_20-06-01_1177536
#$dateTimePattern = "x" # Example: 79576746_590191381795832_5037634142968217600_n.jpg

# Loop through all JPG files in the directory
Get-ChildItem -Path $directory -Filter "*.jpg" -Recurse | ForEach-Object {
    $file = $_.FullName

    # Extract DateTimeOriginal field using ExifTool
    $exifData = & .\exiftool.exe -DateTimeOriginal -s3 $file

    # Check if DateTimeOriginal is missing or empty
    if ([string]::IsNullOrWhiteSpace($exifData)) {
        Write-Host "No DateTaken found for: $file"

        # Extract date and time from the filename using the pattern
        if ($file -match $dateTimePattern) {
            $year = $Matches[1]
            $month = $Matches[2]
            $day = $Matches[3]
            $hour = $Matches[4]
            $minute = $Matches[5]
            $second = $Matches[6]

            # Format the extracted date and time for EXIF
            $formattedDate = "${year}:${month}:${day} ${hour}:${minute}:${second}"
            Write-Host "Filename match: Using formatted date $formattedDate"

        } else {
            # Fall back to file's last modified time
            $lastModified = (Get-Item $file).LastWriteTime
            $formattedDate = $lastModified.ToString("yyyy:MM:dd HH:mm:ss")
            Write-Host "No filename match: Using last modified time $formattedDate"
        }

        # Set the DateTaken EXIF data
        & .\exiftool.exe -overwrite_original `
            "-DateTimeOriginal=$formattedDate" `
            "-CreateDate=$formattedDate" `
            "-ModifyDate=$formattedDate" $file
        Write-Host "Updated DateTaken for: $file to $formattedDate"
    } else {
        Write-Host "DateTaken already exists for: $file"
    }
}
