Get-ChildItem "D:\GoogleDrive\Tony\Projects\Magic\art\dom\*.jpg" | ForEach-Object {
    $directory = $_.Directory.ToString()
    $basename = $_.BaseName.ToString()
    $extension = $_.Extension.ToString()

    $file = $directory + "\" + $basename + $extension
    
    $regex = $directory -match "\\(\w+)$"
    $set = $Matches.1

    if ($basename -match "^\d+$") {

        $card = $basename

        $card
        
        $url = ("https://scryfall.com/card/" + $set + "/" + $card + "/")
        $response = $null
        $response = Invoke-WebRequest $url -UseBasicParsing

        if ($response) {

            $regex = $response.Content -match "<title>(.+?)\s\W"
            $title = $Matches.1
            $title = $title -replace "&#39;", "'"

            write-host "$card -- $title"
            Rename-Item -Path $file -NewName ($card + " - " + $title + $extension)
        }
    }
}

