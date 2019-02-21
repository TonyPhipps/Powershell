# Force Get-Childitem to NOT pull Windows directory or Program Files directories.

Get-ChildItem c:\ -Depth 0 -Directory | Where-Object {$_.Name -notmatch "windows|Program Files|Program Files \(x86\)"} | Get-Childitem -Recurse
