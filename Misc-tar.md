Create a .tgz using a source folder
```
$Folder = "C:\full\path"
$ParentFolder = Split-Path $Folder -Parent
$FolderName = Split-Path $Folder -Leaf
tar -czf "$ParentFolder\thisFilename.tgz" -C $ParentFolder $FolderName
```