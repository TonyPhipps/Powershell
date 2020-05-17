# Convert plain text to base64
$Text = 'This is a secret and should be hidden'
$Bytes = [System.Text.Encoding]::Unicode.GetBytes($Text)
$EncodedText = [Convert]::ToBase64String($Bytes)
$EncodedText

# Convert base64 to plain text
$base64_string = "VABoAGkAcwAgAGkAcwAgAGEAIABzAGUAYwByAGUAdAAgAGEAbgBkACAAcwBoAG8AdQBsAGQAIABiAGUAIABoAGkAZABkAGUAbgA="
[System.Text.Encoding]::Default.GetString([System.Convert]::FromBase64String($base64_string))

# Resolve Shortened URL
$URL = "http://tinyurl.com/KindleWireless"
(Invoke-WebRequest -Uri $URL -MaximumRedirection 0 -ErrorAction Ignore).Headers.Location

