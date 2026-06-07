$filter = "CardName"
$filter = $filter.Trim() -replace '\s+', '_'
$path = "F:\GoogleDrive\Tony\Projects\Magic\art"

$shell = New-Object -ComObject Shell.Application
Get-ChildItem -Path $path -Filter "*$filter*" -Recurse -File | ForEach-Object {
    $folder = $shell.Namespace($_.DirectoryName)
    $fileItem = $folder.ParseName($_.Name)
    $dimensions = $folder.GetDetailsOf($fileItem, 31) # Detail rule 31 is standard for "Dimensions" in modern Windows environments
    [PSCustomObject]@{
        "Full Path"  = $_.FullName
        "Dimensions" = if ($dimensions) { $dimensions } else { "N/A (Not an image or property missing)" }
    }
} | Format-Table -AutoSize