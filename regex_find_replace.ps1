# Searches a directory for matching files then executes regex-based find and replace

$path="c:\logs"

Get-ChildItem $path -Filter *.log -Recurse | 
    ForEach-Object {
        $matches = Select-String -Path $_.FullName -Pattern "<stuff>(.*)</stuff>" -Encoding unicode
        $matches = $matches.Matches
            $values = foreach ($match in $matches){
                $value = $match.groups[1].value
                $value = $value.replace("&lt;","<")
                $value = $value.replace("&gt;",">")
                $value  
            }
        
        $values | Out-File -FilePath ($path+'\processed\'+$_.BaseName + '.log')}


# Opens a file and executes regex-based find and replace
$log = "C:\test.txt"

$matches = Select-String -path $log -Pattern "<stuff>(.*)</stuff>" -Encoding unicode

$matches = $matches.matches

$values = foreach ($match in $matches){
    $value = $match.groups[1].value
    $value = $value.replace("&lt;","<")
    $value = $value.replace("&gt;",">")
    $value
}

$values | Out-File -FilePath processed.txt
