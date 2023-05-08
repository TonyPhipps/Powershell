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
            "13m" {$set = "m13"}
            "14m" {$set = "m14"}
            "15m" {$set = "m15"}
            "13c" {$set = "c13"}
            "14c" {$set = "c14"}
            "15c" {$set = "c15"}
            "16c" {$set = "c16"}
            "17c" {$set = "c17"}
            "aki" {$set = "akh"}
            "25m" {$set = "a25"}
            # "a22" {$set = "ymid"} numbers mismatch
            "alr" {$set = "arb"}
            # "alp" {$set = "lea"} numbers mismatch
            "ant" {$set = "atq"}
            "apo" {$set = "apc"}
            "ara" {$set = "arn"}

        }

        if ($basename -match "^\d+([\s-]+)?$") {

            $card = $basename
            $card = $card -replace " - ", ""
           
            $url = ("https://scryfall.com/card/" + $set + "/" + $card + "/")
            
            $response = $null
            $response = try{ Invoke-WebRequest $url -UseBasicParsing} catch{ write-host $url }
    
            if ($response) {
    
                $regex = $response.Content -match "<title>(.+?)\s\W"
                $title = $Matches.1
                $title = $title -replace "&#39;", "'"
                $title = $title -replace ":", ""
    
                write-host "$set -- $card -- $title"
                Rename-Item -Path $file -NewName ($card + " - " + $title + $extension)
            } #else { $url }
        }    
}

