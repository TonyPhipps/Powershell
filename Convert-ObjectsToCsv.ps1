Function Convert-ObjectsToCsv {
    <#
    .SYNOPSIS
        Combine objects into a single csv without losing fields absent from the first object parsed.
    
    .DESCRIPTION
        Combine objects into a single csv without losing fields absent from the first object parsed. 
        Due to the requirement to parse all objects in the array to build the columns list, this is not designed 
        to work with the pipeline. Originally written to merge event log objects after having their deper XML 
        added as properties with Add-WinEventXMLData.
    
    .PARAMETER ObjectArray
        An array of objects to be merged into a single object output.       
    
    .INPUTS
        Array
    
    .OUTPUTS
        .\ObjectsToCsv.csv
    
    .EXAMPLE
        Convert-ObjectsToCsv -ObjectArray $someobjects

    .EXAMPLE
        $EventsFromFile = Get-WinEvent -Path .\eventsfile.evtx | Add-WinEventXMLData
        Convert-ObjectsToCsv -ObjectArray $EventsFromFile

        #>

    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            ValueFromRemainingArguments = $false,
            Position = 0 )]
        [array]$objectArray
    )

    Process {

        # Parse out all property names
        $Names  = $objectArray | ForEach-Object {
            $_ | Get-Member -MemberType Property, NoteProperty | Select-Object name
        }

        # Eliminate duplicate property names
        $UniqueNames = $Names | Select-Object name -Unique | Sort-Object -Property Name

        # Prepare first export to force header
        $headerObject = New-Object PSObject

        For ( $i = 0; $i -lt $UniqueNames.count; $i++ ) {
            $headerObject | Add-Member -MemberType NoteProperty -Name $UniqueNames[$i].Name -Value '' -Force
        }

        # Stage csv file with all columns in header
        $headerObject | export-csv .\ObjectsToCsv.csv -NoTypeInformation

        # eliminate blank line from staged csv
        $lines = Get-Content .\ObjectsToCsv.csv
        $lines | Select-Object -First 1 | out-file .\ObjectsToCsv.csv

        # Append events into staged csv file
        $objectArray | export-csv .\ObjectsToCsv.csv -NoTypeInformation -Append -Force
    }
}