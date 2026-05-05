# Configuration Parameters
$url = "https://store.steampowered.com/hardware/steamcontroller/?cc=US&l=english"
$presenceText = "btn_addtocart" # The text/class that must be present (e.g., buy button)
$absenceText = "Reservation Servers are busy" # The out-of-stock or error text that must be absent
$checkIntervalSeconds = 60 # 1 Minute check interval

Write-Host "Monitoring URL: $url" -ForegroundColor Cyan
Write-Host "Requires: '$presenceText' | Excludes: '$absenceText' | Interval: $checkIntervalSeconds sec`n"

# Define the music logic as a scriptblock so it can run asynchronously
$musicBlock = {
    function Play-TheFinalCountdown {
        # Notes: B=988, A=880, G=784, F#=740, E=659, D=587, C#=554
        # Format: Frequency, Duration (ms)
        $melody = @(
            (740, 150), (659, 150), (740, 600), (494, 600), # F# E F# B
            (0, 150), # Rest
            (784, 150), (740, 150), (784, 150), (740, 150), (659, 600), # G F# G F# E
            (0, 150),
            (784, 150), (740, 150), (659, 600), (440, 600), # G F# E A
            (0, 150),
            (659, 150), (587, 150), (659, 150), (587, 150), (554, 600), (659, 600)  # E D E D C# E
        )
        
        foreach ($note in $melody) {
            if ($note[0] -eq 0) { Start-Sleep -Milliseconds $note[1] }
            else { [console]::Beep($note[0], $note[1]) }
        }
    }
    
    while ($true) {
        Play-TheFinalCountdown
        Start-Sleep -Seconds 1
    }
}

$musicJob = $null

while ($true) {
    try {
        $timestamp = Get-Date -Format "HH:mm:ss"
        $params = @{
            Uri             = $url
            UseBasicParsing = $true
            UserAgent       = "Mozilla/5.0 (Windows NT 10.0; Win64; x64)"
            TimeoutSec      = 15
        }
        
        $response = Invoke-WebRequest @params
        $html = $response.Content

        # Generalized match logic for any page
        $hasRequiredText = $html -match $presenceText
        $hasExcludedText = $html -match $absenceText

        if ($hasRequiredText -and -not $hasExcludedText) {
            Write-Host "`n[$timestamp] >>> TARGET CONDITION MET! <<<" -ForegroundColor Black -BackgroundColor Green
            Write-Host "LINK: $url" -ForegroundColor Cyan
            
            # Start the background music job if it isn't already running
            if (-not $musicJob -or $musicJob.State -ne 'Running') {
                Start-Process $url
                $musicJob = Start-Job -ScriptBlock $musicBlock
                Write-Host "[$timestamp] Audio alert started in the background." -ForegroundColor Green
            } else {
                Write-Host "[$timestamp] Condition still met. Audio alert continuing..." -ForegroundColor Green
            }
        } 
        else {
            # If the condition fails, stop the background job
            if ($musicJob -and $musicJob.State -eq 'Running') {
                Write-Host "[$timestamp] Condition lost! Stopping audio alert..." -ForegroundColor Red
                Stop-Job -Job $musicJob
                Remove-Job -Job $musicJob
                $musicJob = $null
            }
            Write-Host "[$timestamp] Not available yet. Sleeping..." -ForegroundColor Gray
        }
    }
    catch {
        Write-Host "[$timestamp] Server error/timeout. Will retry..." -ForegroundColor Yellow
    }

    Start-Sleep -Seconds $checkIntervalSeconds
}
