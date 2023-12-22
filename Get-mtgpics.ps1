# Specify where to save files
$output = "E:\GoogleDrive\Tony\Projects\Magic\art"

mkdir ("{0}" -f $output) -ErrorAction SilentlyContinue

$downloaded = 0

for ($i = -2 ; $i -le 1000 ; $i++){
    
    # Specify the URL of the web page you want to request
    $url = "https://www.mtgpics.com/art?set=$i"

    # Use Invoke-WebRequest to get the web page content
    $response = Invoke-WebRequest -Uri $url -ErrorAction SilentlyContinue

    # Parse the HTML content using regular expressions to find <img> tags
    $html = $response.Content

    # Define a regular expression to match <img> tags and extract the 'src' attribute
    $imgRegex = '(?s)url\(pics\/[^\/]+\/(?<set>[^\/]+)\/(?<card>\d+).jpg.*?class=und.*?\>(?<alt>[^\<]+)\<'

        # Use Select-String to find matches in the HTML content
    $regexMatches = ($html | Select-String -Pattern $imgRegex -AllMatches).Matches.Value

        # Iterate through each match and output the 'src' attribute
    foreach ($value in $regexMatches) {
        
        # Define a regular expression with a named group
        $regex = [regex]::new('(?s)url\(pics\/[^\/]+\/(?<set>[^\/]+)\/(?<card>\d+).jpg.*?class=und.*?\>(?<alt>[^\<]+)\<')

        # Extract matches to a value
        $set = ($regex.Match($value)).Groups['set'].Value
        $card = ($regex.Match($value)).Groups['card'].Value
        $name = ($regex.Match($value)).Groups['alt'].Value
           
        # Handle special characters
        $name = $name -replace "&#39;", "'"
        $name = $name -replace ":", ""

        $url = "https://www.mtgpics.com/pics/art/" + $set + "/" + $card + ".jpg"
        $filename = "{0} {1}.jpg" -f $card, $name

        # Output the value of the named group
        
        $outFile = ("{0}\{1}\{2}" -f $output, $set, $filename)

        
        # Test if the directory exists
        if (Test-Path -Path ("{0}\{1}" -f $output, $set) -PathType Container) {
            
        } else {
            mkdir ("{0}\{1}" -f $output, $set)
        }
        
        if (-not(Test-Path -Path $outFile -PathType Leaf)) {

            try { 
                Invoke-WebRequest $url -OutFile $outFile
                ++$downloaded

                write-host ("Pulling`n`t{0}`n`t`tFrom`n`t`t`t{1}" -f $filename, $url)
            }
            catch { Write-Verbose "$set - $card not found." }
        }
        else{
            Write-host ("Already downloaded: {0} - {1} - {2}" -f $set, $card, $name)
        }
    }
}

write-host "Downloaded $downloaded new cards!"