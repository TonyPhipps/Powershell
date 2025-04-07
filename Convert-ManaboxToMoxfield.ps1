# Script to convert ManaBox CSV export to Moxfield-compatible CSV
# Supports drag-and-drop or command-line parameters
# Supports auto converting a file named "ManaBox_Collection.csv" in the same directory as this script when ran without any parameters.
# Example
# C:\path\to\Convert-ManaboxToMoxfield.ps1 -InputFile "C:\path\to\ManaBox_Collection.csv" -OutputFile "C:\path\to\ManaBox_Collection_Moxfield.csv"

param (
    [Parameter(Mandatory=$false)][string]$InputFile = ".\ManaBox_Collection.csv",
    [Parameter(Mandatory=$false)][string]$OutputFile
)

# Function to determine file paths based on input method
function Get-FilePaths {
    if ($InputFile) {
        # Command-line parameters provided
        if (-not (Test-Path $InputFile) -or $InputFile -notmatch "\.csv$") {
            Write-Host "Error: '$InputFile' is not a valid CSV file." -ForegroundColor Red
            pause
            exit
        }
        $script:inputPath = $InputFile
        $script:outputPath = if ($OutputFile) { $OutputFile } else { 
            [System.IO.Path]::Combine(
                [System.IO.Path]::GetDirectoryName($InputFile),
                [System.IO.Path]::GetFileNameWithoutExtension($InputFile) + "_Moxfield.csv"
            )
        }
    } elseif ($args.Count -gt 0) {
        # Drag-and-drop method
        $script:inputPath = $args[0]
        if (-not (Test-Path $inputPath) -or $inputPath -notmatch "\.csv$") {
            Write-Host "Error: '$inputPath' is not a valid CSV file." -ForegroundColor Red
            pause
            exit
        }
        $script:outputPath = [System.IO.Path]::Combine(
            [System.IO.Path]::GetDirectoryName($inputPath),
            [System.IO.Path]::GetFileNameWithoutExtension($inputPath) + "_Moxfield.csv"
        )
    } else {
        Write-Host "Error: No file provided. Drag a ManaBox CSV onto the script or use -InputFile parameter." -ForegroundColor Red
        pause
        exit
    }
}

# Set file paths
Get-FilePaths

# Import the ManaBox CSV
try {
    $manaBoxData = Import-Csv -Path $inputPath
} catch {
    Write-Host "Error: Failed to read '$inputPath'. Ensure it's a valid CSV." -ForegroundColor Red
    pause
    exit
}

# Define Moxfield-compatible headers
$moxfieldHeaders = @("Count", "Name", "Edition", "Condition", "Language", "Foil", "Collector Number")

# Create an array to hold the converted data
$convertedData = @()

# Process each row from ManaBox CSV
foreach ($row in $manaBoxData) {
    # Map ManaBox fields to Moxfield fields
    $convertedRow = [PSCustomObject]@{
        #"Count"          = $row.Quantity          # ManaBox uses "Quantity" for card count
        "Count"          = "1"                     # ManaBox uses "Quantity" for card count
        "Name"           = $row.Name               # Card name, assumed to match
        "Edition"        = $row."Set Code"         # ManaBox "Set Code" maps to Moxfield "Edition"
        "Condition"      = $row.Condition          # Condition, may need normalization
        "Language"       = $row.Language           # Language, assumed to match
        "Foil"           = if ($row.Foil -eq "Foil") { "foil" } else { "" }  # Normalize foil status
        "Collector Number" = $row."Collector Number"  # Collector number, if present
    }

    # Normalize condition values to Moxfield's expected terms (adjust as needed)
    switch ($convertedRow.Condition) {
        "near_mint" { $convertedRow.Condition = "Near Mint" }
        "LightlyPlayed" { $convertedRow.Condition = "Lightly Played" }
        "HeavilyPlayed" { $convertedRow.Condition = "Heavily Played" }
        # Add more mappings if needed
    }

    # Add the converted row to the array
    $convertedData += $convertedRow
}

# Export the converted data to a new CSV file
try {
    $convertedData | Export-Csv -Path $outputPath -NoTypeInformation -Encoding UTF8
    Write-Host "Conversion complete! Moxfield-compatible CSV saved to '$outputPath'" -ForegroundColor Green
} catch {
    Write-Host "Error: Failed to save '$outputPath'. Check permissions or disk space." -ForegroundColor Red
}

# Pause to allow user to see the result (optional, remove if not needed)
pause