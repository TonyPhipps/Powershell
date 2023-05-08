Get-ChildItem "D:\GoogleDrive\Tony\Projects\Magic\art\*" -Recurse -Filter *.jpg | 
    ForEach-Object {
        $directory = $_.Directory.ToString()
        $basename = $_.BaseName.ToString()
        $extension = $_.Extension.ToString()
        $Matches = $null

        $file = $directory + "\" + $basename + $extension
        
        $regex = $directory -match "\\(\w+)$"
        $set = $Matches.1

        switch ($set){
            "zve" {$set = "ddp"}
            "2pc" {$set = "pc2"}
            "2pd" {$set = "pc2"}
            "5th" {$set = "5ed"}
            "6th" {$set = "6ed"}
            "7th" {$set = "7ed"}
            "8th" {$set = "8ed"}
            "9th" {$set = "9ed"}
            "10m" {$set = "m10"}
            "11m" {$set = "m11"}
            "12m" {$set = "m12"}
        }

        if ($basename -match "^\d+$") {

            $card = $basename
           
            $url = ("https://scryfall.com/card/" + $set + "/" + $card + "/")
            
            $response = $null
            $response = Invoke-WebRequest $url -UseBasicParsing
    
            if ($response) {
    
                $regex = $response.Content -match "<title>(.+?)\s\W"
                $title = $Matches.1
                $title = $title -replace "&#39;", "'"
                $title = $title -replace ":", ""
    
                write-host "$set -- $card -- $title"
                Rename-Item -Path $file -NewName ($card + " - " + $title + $extension)
            } else {
                $url
            }
        }    
}

