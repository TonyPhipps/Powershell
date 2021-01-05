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
