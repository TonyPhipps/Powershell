$UpdateSession = New-Object -ComObject Microsoft.Update.Session
$UpdateSearcher = $UpdateSession.CreateUpdateSearcher()
$SearchResult = $UpdateSearcher.Search("IsInstalled=0")
$PendingUpdates = $SearchResult.Updates | Where-Object { $_.IsDownloaded -eq $false }
if ($PendingUpdates.Count -gt 0) {
    $PendingUpdates | Select-Object Title, 
        @{Name="Size(MB)"; Expression={"{0:N2}" -f ($_.MaxDownloadSize / 1MB)}} | 
        Format-Table -AutoSize
    $TotalBytes = ($PendingUpdates | Measure-Object -Property MaxDownloadSize -Sum).Sum
    Write-Host ("`nTotal Pending Download Size: {0:N2} MB" -f ($TotalBytes / 1MB)) -ForegroundColor Cyan
}
else {
    Write-Host "No pending updates found for download." -ForegroundColor Yellow
}