$setslist = Get-Content -Path "D:\GoogleDrive\Tony\Projects\Magic\art\sets_mtgpics.txt"
$url_start = "https://www.mtgpics.com/pics/art/"
$url_end = ".jpg"
$output = "D:\GoogleDrive\Tony\Projects\Magic\art"

$downloaded = 0

foreach($set in $setslist) {
    $set = $set.ToLower()

    write-host "Checking for first card of set $set"
            
    $testurl = "https://www.mtgpics.com/card?ref=" + $set + "001"

    if ((Invoke-WebRequest $testurl -UseBasicParsing).Content -notmatch "(Wrong ref or number.)|(No card found.)") {
        Write-Host "Set $set found."
        if (-not(Test-Path -Path "$output\$set")){
            New-Item -Path "$output\$set" -ItemType Directory
        }
    }
    else {
        write-host "Set $set not found (based on $testurl)."
        $set >> set_errors.txt
        continue
    }

    for ($i = 1 ; $i -le 1000 ; $i++){
        $percentage=($i/1000)*100
        Write-Progress -Activity "Download in Progress" -Status "($percentage % Complete)" -PercentComplete $percentage

        $card = '{0:d3}' -f $i
        $url = $url_start + $set + "/" + $card + $url_end
        $file = ($output + "\" + $set + "\" + $card + $url_end)

        $regex = $file -match "(.+\d+)"
        $testpath = $Matches.1 + "*"

        if (-not(Test-Path -Path $testpath -PathType Leaf)) {

            try { 
                Invoke-WebRequest $url -OutFile $file
                ++$downloaded

                write-host "$url downloaded!"
            }
            catch { Write-Verbose "$set - $card not found." }
        }
    }
}

write-host "Downloaded $downloaded new cards!"