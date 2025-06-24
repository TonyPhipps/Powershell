# EXAMPLE:
# .\Remove-IndentedSelection.ps1 -parentDir "C:\path\to\files"

param (
    [string]$parentDir
)

# Function to process a single file
function Remove-IndentedSection {
    param (
        [string]$FilePath
    )
    
    try {
        # Read the file content
        $content = Get-Content -Path $FilePath -Raw
        
        # Check if file contains 'fields:'
        if ($content -match 'fields:') {
            # Split content into lines
            $lines = $content -split '\r?\n'
            $newLines = @()
            $skip = $false
            $indentLevel = 0

            foreach ($line in $lines) {
                # Check if line starts with 'fields:'
                if ($line -match '^\s*fields:') {
                    $skip = $true
                    # Get indentation level of fields
                    $indentLevel = ($line | Select-String '^(\s*)').Matches.Groups[1].Value.Length
                    continue
                }
                
                # Skip indented lines after fields
                if ($skip -and ($line -match '^\s*-\s' -and ($line | Select-String '^(\s*)').Matches.Groups[1].Value.Length -gt $indentLevel)) {
                    continue
                }
                
                # Stop skipping when we reach a line with same or less indentation as fields
                if ($skip -and -not ($line -match '^\s*-\s') -and ($line.Trim() -ne '')) {
                    $skip = $false
                }
                
                if (-not $skip) {
                    $newLines += $line
                }
            }
            
            # Write modified content back to file
            $newContent = $newLines -join "`n"
            Set-Content -Path $FilePath -Value $newContent -Force
            Write-Host "Processed: $FilePath"
        }
    }
    catch {
        Write-Error "Error processing $FilePath : $_"
    }
}

# Find all .txt files in parent directory and subdirectories
$Files = Get-ChildItem -Path $parentDir -Recurse -Include *.txt

# Process each file
foreach ($file in $Files) {
    Remove-IndentedSection -FilePath $file.FullName
}

Write-Host "Processing complete."