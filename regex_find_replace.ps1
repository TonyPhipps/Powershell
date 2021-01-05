# Searches a directory for matching files then executes regex-based find and replace

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

        $matches = $content | Select-String -Pattern "<rawsyslogmsg>(.*?)</rawsyslogmsg>"
        $matches = $matches.Matches
        $values = foreach ($match in $matches){
            $value = $match.groups[1].value
            $value = $value.replace("&lt;","<")
            $value = $value.replace("&gt;",">")
            $value
        }

        $values | Out-File -FilePath ($path+'\processed\'+$_.BaseName + '.log')
    }



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
