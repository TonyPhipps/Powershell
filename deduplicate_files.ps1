@(ls *.*).Count
ls *.* | get-filehash | group -property hash | where { $_.count -gt 1 } | % { $_.group | select -skip 1 } | del
@(ls *.*).Count