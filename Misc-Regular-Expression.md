Given a string, find a substring and assign it to a variable
```
$string = "This is a test string 123"
$pattern = "(\d+)"

if ($string -match $pattern) {
  $matchedChars = $matches[1]
}
```


Find a String From a File
Given a file with this somewhere in it, and you want just the value of Something, which is "Captured".

```Something='Captured'```

```
$File = ""
$Pattern = "Something=\s'([^\'])'"
$Matches = Select-String -path $File -Pattern $Pattern
$Matches.Groups[1].Value
```


Find and Replace in One or More Files
```
$Files = Get-ChildItem -Path $ViewsFolder -Filter *.xml

foreach ($File in $Files){
    if ($File.Name -match "file1.xml"){
        (Get-Content $File.PSPath) |
        Foreach-Object { $_ -replace "regex1", "replacement1" } |
        Set-Content $File.PSPath
    }elseif ($File.Name -match "file2.xml"){
        (Get-Content $File.PSPath) |
        Foreach-Object { $_ -replace "regex2", "replacement2" } |
        Set-Content $File.PSPath
    }
}
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
