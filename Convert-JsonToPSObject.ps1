$file = "file.json"
$json = Get-Content $file | ConvertFrom-Json
$json
# Note that some json nests the records deeper into the array. For example:
$records = $json._embedded.records
$records
