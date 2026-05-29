<#
.SYNOPSIS
    Downloads Magic: The Gathering card art from mtgpics.com with sanitized naming conventions.
.DESCRIPTION
    Scrapes mtgpics.com set pages for card artwork, translates unofficial set acronyms,
    cleanses invalid file system characters, converts spaces to underscores, prepends 
    the set code to the filename, and writes the structured image files to disk.
.PARAMETER OutputPath
    The base directory where downloaded card art folders will be created.
.PARAMETER StartSetId
    The integer representation of the first set index to parse. Defaults to -2.
.PARAMETER EndSetId
    The integer representation of the last set index to parse. Defaults to 600.
.EXAMPLE
    Get-MtgPicsArt -OutputPath "D:\MtgArt" -StartSetId 1 -EndSetId 150
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $true, Position = 0)]
    [ValidateNotNullOrEmpty()]
    [string]$OutputPath,

    [Parameter(Position = 1)]
    [int]$StartSetId = -2,

    [Parameter(Position = 2)]
    [int]$EndSetId = 600
)

begin {
    # Catch uninitialized variables and invalid properties early
    Set-StrictMode -Version Latest

    # Verify or safely initialize the root output folder path
    try {
        if (-not (Test-Path -Path $OutputPath -PathType Container)) {
            $null = New-Item -ItemType Directory -Path $OutputPath -Force -ErrorAction Stop
        }
    }
    catch {
        Write-Error -Message "Initialization failed for path '$OutputPath': $_" -Category InvalidOperation -ErrorAction Stop
    }
    [int]$downloadedCount = 0
    [int]$totalSets = $EndSetId - $StartSetId + 1
}

process {
    for ([int]$i = $StartSetId; $i -le $EndSetId; $i++) {
        [int]$setIndex = $i - $StartSetId
        [int]$percentage = [math]::Round(($setIndex / $totalSets) * 100)
        Write-Progress -Activity "Parsing remote MTG Sets" -Status "Set ID $i ($percentage% Complete)" -PercentComplete $percentage
        [string]$url = "https://www.mtgpics.com/art?set=$i"
        [string]$html = $null
        try { # Fetch raw set HTML string using terminating error configuration
            $response = Invoke-WebRequest -Uri $url -TimeoutSec 30 -ErrorAction Stop
            $html = $response.Content
        }
        catch [System.Net.WebException], [Microsoft.PowerShell.Commands.HttpResponseException] {
            Write-Verbose "Set ID $i was not found or is currently inaccessible."
            continue
        }
        catch {
            Write-Warning "Unexpected exception processing set index $($i): $_"
            continue
        }
        # Regular expression to extract target tokens from page data source
        [string]$imgRegex = '(?s)url\(pics\/[^\/]+\/(?<set>[^\/]+)\/(?<card>\d+).jpg.*?class=und.*?>\s*(?<name>[^\<]+)\s*<'
        $regexMatches = ($html | Select-String -Pattern $imgRegex -AllMatches).Matches
        if ($null -eq $regexMatches -or $regexMatches.Count -eq 0) {
            continue
        }
        [int]$cardCount = 0
        foreach ($regexMatch in $regexMatches) {
            $cardCount++
            [string]$set = $regexMatch.Groups['set'].Value
            [string]$card = $regexMatch.Groups['card'].Value
            [string]$name = $regexMatch.Groups['name'].Value
            [string]$setProper = $set
            switch ($set.ToLowerInvariant()) { # Normalize unofficial acronym mappings used by remote server
                "zve" { $setProper = "ddp" }
                "2pc" { $setProper = "pc2" }
                "2pd" { $setProper = "pc2" }
                "5th" { $setProper = "5ed" }
                "6th" { $setProper = "6ed" }
                "7th" { $setProper = "7ed" }
                "8th" { $setProper = "8ed" }
                "9th" { $setProper = "9ed" }
                "10m" { $setProper = "m10" }
                "11m" { $setProper = "m11" }
                "12m" { $setProper = "m12" }
                "13m" { $setProper = "m13" }
                "14m" { $setProper = "m14" }
                "15m" { $setProper = "m15" }
                "13c" { $setProper = "c13" }
                "14c" { $setProper = "c14" }
                "15c" { $setProper = "c15" }
                "16c" { $setProper = "c16" }
                "17c" { $setProper = "c17" }
                "aki" { $setProper = "akh" }
                "25m" { $setProper = "a25" }
                "a22" { $setProper = "ymid" }
                "alr" { $setProper = "arb" }
                "alp" { $setProper = "lea" }
                "ant" { $setProper = "atq" }
                "apo" { $setProper = "apc" }
                "ara" { $setProper = "arn" }
                "tbw" { $setProper = "bro" }
                "con" { $setProper = "con_" } # Circumvents Windows OS reserved device name constraint
            }
            [int]$cardPercentage = [math]::Round(($cardCount / $regexMatches.Count) * 100)
            Write-Progress -Activity "Processing Set Art: $setProper" -Status "Card $cardCount of $($regexMatches.Count) ($cardPercentage% Complete)" -PercentComplete $cardPercentage

            # Construct target filename and download
            $name = $name -replace "&#39;", "'"
            $name = $name -replace '[:!\?\"/]', ''
            $name = $name.Trim() -replace '\s+', '_'
            [string]$cleanSet = $setProper.ToUpperInvariant()
            [string]$filename = "{0}-{1}_{2}.jpg" -f $cleanSet, $card, $name
            [string]$targetSubDir = Join-Path -Path $OutputPath -ChildPath $setProper
            [string]$destinationFile = Join-Path -Path $targetSubDir -ChildPath $filename
            if (-not (Test-Path -Path $targetSubDir -PathType Container)) {
                try {
                    $null = New-Item -ItemType Directory -Path $targetSubDir -Force -ErrorAction Stop
                }
                catch {
                    Write-Error -Message "Unable to generate subdirectory '$targetSubDir': $_" -Category InvalidOperation
                    continue
                }
            }
            [string]$downloadUrl = "https://www.mtgpics.com/pics/art/$set/$card.jpg"
            if (-not (Test-Path -Path $destinationFile)) {
                try {
                    Invoke-WebRequest -Uri $downloadUrl -OutFile $destinationFile -ErrorAction Stop
                    $downloadedCount++
                    [PSCustomObject]@{
                        SetCode    = $cleanSet
                        CardNumber = $card
                        CardName   = $name
                        OutputFile = $filename
                        Status     = 'Downloaded'
                    }
                }
                catch {
                    Write-Error -Message "Failed downloading asset from $downloadUrl -> $destinationFile : $_" -Category WriteError
                }
            }
            else { # Avoid duplicated downloads, output structured skip telemetry object
                [PSCustomObject]@{
                    SetCode    = $cleanSet
                    CardNumber = $card
                    CardName   = $name
                    OutputFile = $filename
                    Status     = 'Skipped (File Exists)'
                }
            }
        }
    }
}

end {
    Write-Verbose "Operation finalized. Managed downloads: $downloadedCount items."
}
