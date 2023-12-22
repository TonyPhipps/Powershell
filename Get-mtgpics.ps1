﻿# Specify where to save files
$output = "E:\GoogleDrive\Tony\Projects\Magic\art"

# -----------------------------------------------

mkdir ("{0}" -f $output) -ErrorAction SilentlyContinue

$downloaded = 0

# For each potential set, iterate and provide progress
for ($i = -2 ; $i -le 1000 ; $i++){
    $percentage=[math]::Round(($i/1000)*100)
    Write-Progress -Activity "Set $i, with $downloaded cards downloaded so far." -Status "($percentage % Complete)" -PercentComplete $percentage
    
    # Specify the URL of the web page you want to request
    $url = "https://www.mtgpics.com/art?set=$i"

    # Get set page
    $response = Invoke-WebRequest -Uri $url -ErrorAction SilentlyContinue
    $html = $response.Content

    # Pull regex matches of card details and art link
    $imgRegex = '(?s)url\(pics\/[^\/]+\/(?<set>[^\/]+)\/(?<card>\d+).jpg.*?class=und.*?\>(?<name>[^\<]+)\<'
    #$regexMatches = ($html | Select-String -Pattern $imgRegex -AllMatches).Matches.Value
    $regexMatches = ($html | Select-String -Pattern $imgRegex -AllMatches).Matches

    # Iterate through each match and output the 'src' attribute
    $count = 0
    foreach ($regexMatch in $regexMatches) {
        $percentage=[math]::Round(($count/$regexMatches.Count)*100)
        Write-Progress -Activity "Downloading Art from Set" -Status "($percentage % Complete)" -PercentComplete $percentage
        ++$count

        # Define a regular expression with a named group
        #$regex = [regex]::new('(?s)url\(pics\/[^\/]+\/(?<set>[^\/]+)\/(?<card>\d+).jpg.*?class=und.*?\>(?<name>[^\<]+)\<')
        #$set = ($regex.Match($value)).Groups['set'].Value
        #$card = ($regex.Match($value)).Groups['card'].Value
        #$name = ($regex.Match($value)).Groups['name'].Value

        $set = $regexMatch.Groups['set'].Value
        $card = $regexMatch.Groups['card'].Value
        $name = $regexMatch.Groups['name'].Value
           
        # Handle special characters
        $name = $name -replace "&#39;", "'"
        $name = $name -replace ":", ""
        $name = $name -replace "!", ""

        $url = "https://www.mtgpics.com/pics/art/" + $set + "/" + $card + ".jpg"
        $filename = "{0} {1}.jpg" -f $card, $name

        # Output the value of the named group
        $outFile = ("{0}\{1}\{2}" -f $output, $set, $filename)

        # Check if directory exists, then create.
        if (Test-Path -Path ("{0}\{1}" -f $output, $set) -PathType Container) {
            
        } else {
            mkdir ("{0}\{1}" -f $output, $set)
        }
        
        # Check if file exists, then download.
        if (-not(Test-Path -Path $outFile -PathType Leaf)) {

            try { 
                Invoke-WebRequest $url -OutFile $outFile
                ++$downloaded

                Write-host ("Downloading: {0} - {1} - {2} `n`t from {3}" -f $set, $card, $name, $url)
            }
            catch { Write-Verbose "$set - $card not found." }
        }
        else{
            Write-host ("Already downloaded: {0} - {1} - {2}" -f $set, $card, $name)
        }
    }
}

write-host "Downloaded $downloaded new cards!"