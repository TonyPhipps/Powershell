@(Get-ChildItem *.*).Count
Get-ChildItem *.* | get-filehash | Group-Object -property hash | Where-Object { $_.count -gt 1 } | ForEach-Object { $_.group | Select-Object -skip 1 } | Remove-Item
@(Get-ChildItem *.*).Count