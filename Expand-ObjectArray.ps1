function Expand-ObjectArray {
    param(
        [Parameter(Mandatory)]
        [array]$InputArray
    )

    # Collect all unique property names
    $allProperties = $InputArray | ForEach-Object {
        $_.PSObject.Properties.Name
    } | Sort-Object -Unique

    # Create a new array with all properties
    $outputArray = @()
    foreach ($obj in $InputArray) {
        $newObj = @{}
        foreach ($prop in $allProperties) {
            $newObj.$prop = $obj.$prop
        }
        $outputArray += $newObj
    }

    return $outputArray
}