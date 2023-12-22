# Specify where to save files
$output = "E:\GoogleDrive\Tony\Projects\Magic\art"

# -----------------------------------------------

mkdir ("{0}" -f $output) -ErrorAction SilentlyContinue

$downloaded = 0

# For each potential set, iterate and provide progress
for ($i = -2 ; $i -le 500 ; $i++){
    $percentage=[math]::Round(($i/1000)*100)
    Write-Progress -Activity "Set $i, with $downloaded cards downloaded so far." -Status "($percentage % Complete)" -PercentComplete $percentage
    
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
        
        $percentage=[math]::Round(($count/$regexMatches.Count)*100)
        Write-Progress -Activity "Checking for Art in Set $i ($set)" -Status "($percentage % Complete)" -PercentComplete $percentage
        
        # Handle special characters
        $name = $name -replace "&#39;", "'"
        $name = $name -replace ":", ""
        $name = $name -replace "!", ""
        $name = $name -replace '"', ""

        $url = "https://www.mtgpics.com/pics/art/" + $set + "/" + $card + ".jpg"
        $filename = "{0} {1}.jpg" -f $card, $name

        # Output the value of the named group
        $outFile = ("{0}\{1}\{2}" -f $output, $set, $filename)

        # Check if directory exists, then create.
        if (Test-Path -Path ("{0}\{1}" -f $output, $set) -PathType Container) {
            
        } else {
            Write-Host ("Making dir {0}\{1}" -f $output, $set)
            New-Item -ItemType Directory -Path ("{0}\{1}" -f $output, $set) -Force
        }
        
        # Check if file exists, then download.
        if (-not(Test-Path -Path $outFile -PathType Leaf)) {

            try { 
                Invoke-WebRequest $url -OutFile $outFile
                ++$downloaded

                Write-Host ("Downloading: {0} - {1} - {2} `n`t from {3}" -f $set, $card, $name, $url)
            }
            catch { Write-Verbose "$set - $card not found." }
        }
        else{
            Write-Verbose ("Already downloaded: {0} - {1} - {2}" -f $set, $card, $name)
        }
    }
}

write-host "Downloaded $downloaded new cards!"