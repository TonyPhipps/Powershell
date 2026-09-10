[CmdletBinding()]
param (
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$SetCode
)

# 'is:default' isolates traditional card frames (filtering out borderless, showcase, extended art)
# 'unique:cards' ensures we pull exactly one unique gameplay card name from that pool
$rawQuery = "set:$SetCode is:default unique:cards"
$encodedQuery = [Uri]::EscapeDataString($rawQuery)
$url = "https://api.scryfall.com/cards/search?q=$encodedQuery"

$totalPrice = 0.0
$cardCount = 0
$missingPricesCount = 0

Write-Host "Querying Scryfall API for set '$($SetCode.ToUpper())' (Regular prints only)..." -ForegroundColor Cyan

while ($url) {
    try {
        # A custom User-Agent is recommended by Scryfall's API guidelines to prevent automated blocking
        $headers = @{
            "User-Agent" = "PowerShellSetCalculator/1.0"
            "Accept"     = "application/json"
        }
        $response = Invoke-RestMethod -Uri $url -Method Get -Headers $headers
    }
    catch {
        Write-Error "Error contacting Scryfall API: $_"
        break
    }

    foreach ($card in $response.data) {
        # Prioritize standard non-foil USD price; fallback to foil if it's a foil-only base print
        if ($card.prices.usd) {
            $totalPrice += [double]$card.prices.usd
            $cardCount++
        }
        elseif ($card.prices.usd_foil) {
            $totalPrice += [double]$card.prices.usd_foil
            $cardCount++
        }
        else {
            $missingPricesCount++
        }
    }

    # Scryfall paginates results at 175 cards per page; check if more pages exist
    if ($response.has_more -and $response.next_page) {
        $url = $response.next_page
        # Respect Scryfall's rate-limiting policy (50-100ms sleep minimum between requests)
        Start-Sleep -Milliseconds 100
    }
    else {
        $url = $null
    }
}

# Output formatting
Write-Host "`n========================================" -ForegroundColor Green
Write-Host "Set Code: $($SetCode.ToUpper())" -ForegroundColor Green
Write-Host "Total Unique Regular Cards Priced: $cardCount" -ForegroundColor White
if ($missingPricesCount -gt 0) {
    Write-Host "Cards Missing Price Data (e.g., basic lands/tokens): $missingPricesCount" -ForegroundColor Yellow
}
Write-Host "Total Regular Set Value (USD): `$$($totalPrice.ToString('F2'))" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green