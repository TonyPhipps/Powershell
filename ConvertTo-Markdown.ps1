# Download and install Pandoc
# Export each of your note pages to a .docx (Word) format using OneNote export from the File menu
# Gather all of these .docx files into a directory
# Open directory in File Explorer
# Open Powershell from the File Explorer using File -> Open Windows Powersell
# Run the following command:

ForEach ($result in Get-ChildItem | 
    Select-Object Name, BaseName) { 
        pandoc.exe -f docx -t markdown_strict -i $result.Name -o "$($result.BaseName).md" --wrap=none --atx-headers 
}

# markdown-strict is the type of Markdown. Other variants exist in the Pandoc documentation
# --wrap=none ensures that text in the new .md files doesn't get wrapped to new lines after 80 characters
# --atx-headers makes headers in the new .md files appear as # h1, ## h2 and so on
