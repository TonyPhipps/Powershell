$log = "C:\test.txt"

$matches = Select-String -path $log -Pattern "<junk>(.*)</junk>" -Encoding unicode

$matches = $matches.matches

$values = foreach ($match in $matches){
    $value = $match.groups[1].value
    $value = $value.replace("&lt;","<")
    $value = $value.replace("&gt;",">")
    $value
}

$values | Out-File -FilePath processed.txt
