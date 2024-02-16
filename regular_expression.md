Given a string, find a substring and assign it to a variable
```
$string = "This is a test string 123"
$pattern = "(\d+)"

if ($string -match $pattern) {
  $matchedChars = $matches[1]
}
```





Find and Replace in a File
```
$log = "C:\test.txt"

$matchlist = Select-String -path $log -Pattern "<stuff>(.*)</stuff>" -Encoding unicode

$matchlist = $matchlist.matches

$values = foreach ($match in $matchlist){
    $value = $match.groups[1].value
    $value = $value.replace("&lt;","<")
    $value = $value.replace("&gt;",">")
    $value
}

$values | Out-File -FilePath processed.txt
```




Search a directory for matching files, then find and replace
```
$path="C:\logs\"
mkdir "$path\processed"

Get-ChildItem $path -Filter *.bak -Recurse | 
    ForEach-Object {
        $content = Get-Content $_.FullName -Encoding Unicode
        $content = $content -replace("\x00","`n")
        $content = $content.Split([Environment]::NewLine)
        $content = $content -replace("&lt;","<")
        $content = $content -replace("&gt;",">")
        $content = $content -replace("&quot;",'"')

        $matchlist = $content | Select-String -Pattern "<rawsyslogmsg>(.*?)</rawsyslogmsg>"
        $matchlist = $matchlist.Matches
        $values = foreach ($match in $matchlist){
            $value = $match.groups[1].value
            $value = $value.replace("&lt;","<")
            $value = $value.replace("&gt;",">")
            $value
        }

        $values | Out-File -FilePath ($path+'\processed\'+$_.BaseName + '.log')
    }
```
