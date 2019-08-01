$Path = ""
Get-ChildItem -Path $Path -Recurse -PipelineVariable FullName | 
        ForEach-Object { Get-Item $_.FullName -Stream Zone.Identifier } | 
            Remove-Item
