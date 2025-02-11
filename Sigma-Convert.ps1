# To demonstrate bulk conversion using powershell to loop through each rule, creating an independent output file per rule

# cd $HOME
# python -m venv sigma

Set-Location $HOME\python\sigma
$venv = "C:\Users\username\python\sigma"
$inputDir = "./sigma-master/rules/windows/"
$outputDir = "./output"

# Ensure output directory exists
New-Item -ItemType Directory -Path $outputDir -Force

& "$venv\Scripts\Activate.ps1"

# Loop through each YAML rule file
Get-ChildItem -Path $inputDir -Recurse -Filter "*.yml" | ForEach-Object {
    $ruleName = $_.BaseName  # Extracts the filename without extension
    $outputFile = "$outputDir/$ruleName.txt"
    
    Write-Host "Converting: $($_.FullName) -> $outputFile"
    
    sigma convert --target splunk --pipeline splunk_windows --output $outputFile $_.FullName
    # -f savedsearches
}
deactivate