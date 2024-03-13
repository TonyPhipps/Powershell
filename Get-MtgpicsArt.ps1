﻿# Specify where to save files
$output = "F:\GoogleDrive\Tony\Projects\Magic\art"

# -----------------------------------------------

# $VerbosePreference = "Continue"

mkdir ("{0}" -f $output) -ErrorAction SilentlyContinue

$downloaded = 0

# For each potential set, iterate and provide progress
for ($i = -2 ; $i -le 500 ; $i++){
    $percentage=[math]::Round(($i/500)*100)
    Write-Progress -Activity "Set $i ($setProper), with $downloaded cards downloaded so far." -Status "($percentage % Complete)" -PercentComplete $percentage
    
    # Specify the URL of the web page you want to request
    $url = "https://www.mtgpics.com/art?set=$i"

    # Get set page
    $response = Invoke-WebRequest -Uri $url -ErrorAction SilentlyContinue
    $html = $response.Content

    # Pull regex matches of card details and art link
    $imgRegex = '(?s)url\(pics\/[^\/]+\/(?<set>[^\/]+)\/(?<card>\d+).jpg.*?class=und.*?\>(?<name>[^\<]+)\<'
    $regexMatches = ($html | Select-String -Pattern $imgRegex -AllMatches).Matches

    # Iterate through each match and output the 'src' attribute
    $count = 0
    foreach ($regexMatch in $regexMatches) {
        ++$count

        $set = $regexMatch.Groups['set'].Value
        $card = $regexMatch.Groups['card'].Value
        $name = $regexMatch.Groups['name'].Value

        # MTGPics.com uses unofficial set names often. Handle that here.
        switch ($set){
            "zve" {$setProper = "ddp"}
            "2pc" {$setProper = "pc2"}
            "2pd" {$setProper = "pc2"}
            "5th" {$setProper = "5ed"}
            "6th" {$setProper = "6ed"}
            "7th" {$setProper = "7ed"}
            "8th" {$setProper = "8ed"}
            "9th" {$setProper = "9ed"}
            "10m" {$setProper = "m10"}
            "11m" {$setProper = "m11"}
            "12m" {$setProper = "m12"}
            "13m" {$setProper = "m13"}
            "14m" {$setProper = "m14"}
            "15m" {$setProper = "m15"}
            "13c" {$setProper = "c13"}
            "14c" {$setProper = "c14"}
            "15c" {$setProper = "c15"}
            "16c" {$setProper = "c16"}
            "17c" {$setProper = "c17"}
            "aki" {$setProper = "akh"}
            "25m" {$setProper = "a25"}
            "a22" {$setProper = "ymid"}
            "alr" {$setProper = "arb"}
            "alp" {$setProper = "lea"}
            "ant" {$setProper = "atq"}
            "apo" {$setProper = "apc"}
            "ara" {$setProper = "arn"}
            "tbw" {$setProper = "bro"}
        }

        $percentage=[math]::Round(($count/$regexMatches.Count)*100)
        Write-Progress -Activity "Checking for Art in Set $i ($setProper)" -Status "($percentage % Complete)" -PercentComplete $percentage
        
        # Handle special characters
        $name = $name -replace "&#39;", "'"
        $name = $name -replace ":", ""
        $name = $name -replace "!", ""
        $name = $name -replace '"', ""

        $url = "https://www.mtgpics.com/pics/art/" + $set + "/" + $card + ".jpg"
        $filename = "{0} {1}.jpg" -f $card, $name

        # Output the value of the named group
        $outFile = ("{0}\{1}\{2}" -f $output, $setProper, $filename)

        # Check if directory exists, then create.
        if (Test-Path -Path ("{0}\{1}" -f $output, $setProper) -PathType Container) {
            
        } else {
            Write-Host ("Making dir {0}\{1}" -f $output, $setProper)
            New-Item -ItemType Directory -Path ("{0}\{1}" -f $output, $setProper) -Force
        }
        
        # Check if file exists, then download.
        if (-not(Test-Path -Path $outFile -PathType Leaf)) {

            try { 
                Invoke-WebRequest $url -OutFile $outFile
                ++$downloaded

                Write-Host ("Downloading: {0} - {1} - {2} `n`t from {3} to {4}" -f $setProper, $card, $name, $url, $outFile)
            }
            catch { Write-Verbose "$set - $card not found." }
        }
        else{
            Write-Verbose ("Already downloaded: {0} - {1} - {2}" -f $setProper, $card, $name)
        }
    }
}

write-host "Downloaded $downloaded new cards!"