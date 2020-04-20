# Does NOT cover nested JSON objects

$file = ""
$file_json = Get-Content $file
$file_objects = @()

foreach ($line in $file_json){
    $file_objects += $line | ConvertFrom-Json
}

$file_objects