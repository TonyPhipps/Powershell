$Certificates = $null
$Certificates = Import-Csv C:\Temp\10863.csv

$iCerts = 1
foreach ($Certificate in $Certificates){
    
    $iCerts
    $iCerts++
    
    $Certificate.'Plugin Text' = $Certificate.'Plugin Text' -replace "Plugin Output: ", "" # Remove header
    $Certificate.'Plugin Text' = $Certificate.'Plugin Text' -replace "\n+", "`n" # Remove double newlines
    $Certificate.'Plugin Text' = $Certificate.'Plugin Text' -replace "(?m)\n^\s+", "" # Remove newlines that have multiple spaces
    $Certificate.'Plugin Text' = $Certificate.'Plugin Text' -replace " :", ":" # Fix some delimeters
    
    $Lines = $null
    $Lines += $Certificate.'Plugin Text'.Split("`n").Trim()

    $iLines = 0
    foreach ($Line in $Lines){
        
        if ($Line -ne "") {

            $iLines++
            $Name, $Value = $Line.Split(':',2) # Split by first delimeter only. Fixes parsing dates as objects
        
            if ($Certificate.($Name)){ # Checks if a column already exists, and creates a solution
            
                $Name = $Name+$iLines

            }

            $Certificate | Add-Member -MemberType NoteProperty -Name $Name -Value $Value -Force
        }
    }

}

$Certificates | export-csv 10863_Parsed.csv -NoTypeInformation
