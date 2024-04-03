Export recent Git Changes to CSV
```
$RootPath = (Get-Item (Split-Path -Path $MyInvocation.MyCommand.Path -Parent)).Parent.FullName
Get-MAC -hash -path $RootPath | export-csv -path $RootPath\hashes.csv -NoTypeInformation

$LastUpdate = "2024-02-16"
$GitLog = git --no-pager log --pretty=format:'\"%h\", \"%an\", \"%ci\", \"%s\", \"%b\"' --after $LastUpdate | ConvertFrom-CSV -header Hash, Author, Date, Message, Body, FilesChanged 
ForEach ($Commit in $GitLog){
    if ($Commit.Hash -match '[a-f0-9]{6}'){
        $FilesChanged = git show --pretty="format:" --name-only $Commit.Hash
        $Commit.FilesChanged = $FilesChanged -join ', '
    }
}
$GitLog | Export-CSV $RootPath\changelog.csv -NoTypeInformation
```