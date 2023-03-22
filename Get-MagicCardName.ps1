$set = "j22"
$card = 001

$url = ("https://scryfall.com/card/" + $set + "/" + $card+ "/")

$response = Invoke-WebRequest $url -UseBasicParsing

$response.content -match "<title>(.+?)\s\W"

$Matches.1