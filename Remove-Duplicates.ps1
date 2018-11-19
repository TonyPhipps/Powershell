# Determines duplicate files via hashing and removes all but one copy of each file

Get-ChildItem *.* -recurse | 
Get-Filehash | 
Group-Object -Property hash | 
Where-Object { $_.count -gt 1 } | 
ForEach-Object { $_.group | Select-Object -Skip 1 } | 
Remove-Item