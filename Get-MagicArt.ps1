$file_in = Get-Content -Path "D:\GoogleDrive\Tony\Projects\Magic\sets.txt"
$url_start = "https://www.mtgpics.com/pics/art/"
$url_end = ".jpg"
$output = "D:\GoogleDrive\Tony\Projects\Magic\proxies\art"

foreach($set in $file_in) {
    $set = $set.ToLower()

    write-host "Testing set $set"
            
    $testurl = "https://www.mtgpics.com/card?ref=" + $set + "001"
    
     if ((Invoke-WebRequest $testurl -UseBasicParsing).Content -notmatch "(Wrong ref or number.)|(No card found.)") {
        Write-Host "Set $set found."
        if (-not(Test-Path -Path "$output\$set")){
            New-Item -Path "$output\$set" -ItemType Directory
        }
     }
     else {
        write-host "Set $set found ($testurl)."
        $set >> set_errors.txt
        continue
     }

    for ($i = 1 ; $i -le 1000 ; $i++){
        $card = '{0:d3}' -f $i
        $url = $url_start + $set + "/" + $card + $url_end
        $file = ($output + "\" + $set + "\" + $card + $url_end)

        if (-not(Test-Path -Path $file -PathType Leaf)) {

            try { Invoke-WebRequest $url -OutFile $file }
            catch { Write-Verbose "$set - $card not found." }
        }
    }
}
