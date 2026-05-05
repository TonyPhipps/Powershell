# Configuration
$url = "https://store.steampowered.com/sale/steamcontroller"
$checkIntervalSeconds = 60 # 1 Minute check interval

Write-Host "Monitoring Steam Controller Launch (May 4, 2026)..." -ForegroundColor Cyan
Write-Host "Pattern: *_buy_btn | Interval: 1 min | Audio: On Loop`n"

function Play-TheFinalCountdown {
    # Notes: B=988, A=880, G=784, F#=740, E=659, D=587, C#=554
    # Format: Frequency, Duration (ms)
    $melody = @(
        (740, 150), (659, 150), (740, 600), (494, 600), # F# E F# B
        (0, 150),                                       # Rest
        (784, 150), (740, 150), (784, 150), (740, 150), (659, 600), # G F# G F# E
        (0, 150),
        (784, 150), (740, 150), (659, 600), (440, 600), # G F# E A
        (0, 150),
        (659, 150), (587, 150), (659, 150), (587, 150), (554, 600), (659, 600) # E D E D C# E
    )

    foreach ($note in $melody) {
        if ($note[0] -eq 0) { Start-Sleep -Milliseconds $note[1] }
        else { [console]::Beep($note[0], $note[1]) }
    }
}

while ($true) {
    try {
        $timestamp = Get-Date -Format "HH:mm:ss"
        $params = @{
            Uri = $url
            UseBasicParsing = $true
            UserAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64)"
            TimeoutSec = 15
        }
        
        $response = Invoke-WebRequest @params
        $html = $response.Content

        # Match logic: Generic buy button suffix or standard cart class
        $buyButtonDetected = $html -match "_buy_btn" -or $html -match "btn_addtocart"
        $isUnavailable = $html -match "Out of Stock" -or $html -match "Coming Soon"

        if ($buyButtonDetected -and -not $isUnavailable) {
            Write-Host "`n[$timestamp] >>> STOCK DETECTED! <<<" -ForegroundColor Black -BackgroundColor Green
            Write-Host "LINK: $url" -ForegroundColor Cyan
            
            # Open browser immediately
            Start-Process $url
            
            # Continuous Loop until Ctrl+C is pressed
            while ($true) {
                Play-TheFinalCountdown
                Start-Sleep -Seconds 1
            }
        } 
        else {
            Write-Host "[$timestamp] Not available yet. Sleeping..." -ForegroundColor Gray
        }
    }
    catch {
        Write-Host "[$timestamp] Server error/timeout. Will retry..." -ForegroundColor Yellow
    }

    Start-Sleep -Seconds $checkIntervalSeconds
}
