$Ref = "baseline.csv"
$Diff = "something.csv"
$Compare = @("ProcessName")
$Output = "c:\users\aphipps\temp"

mkdir $Output -ErrorAction SilentlyContinue
$OutputFull = "{0}\{1}_vs_{2}_difference.csv" -f $Output, (Split-Path $Ref -Leaf), (Split-Path $Diff -Leaf)
$RefObjs = Import-Csv $Ref
$DiffObjs = Import-Csv $Diff

$UniqueObjects = Compare-Object -ReferenceObject $RefObjs -DifferenceObject $DiffObjs -Property $Compare -PassThru | 
    Where-Object { $_.SideIndicator -eq '<=' -or $_.SideIndicator -eq '=>' }

foreach ($UniqueObject in $UniqueObjects) {
        
    if ($UniqueObject.SideIndicator -eq "<="){
        $UniqueObject | Add-Member -MemberType NoteProperty -Name "File" -Value $Ref
    }
    
    if ($UniqueObject.SideIndicator -eq "=>"){
        $UniqueObject | Add-Member -MemberType NoteProperty -Name "File" -Value $Diff
    }

    $UniqueObject | Add-Member -MemberType NoteProperty -Name "ComparedProperties" -Value ($Compare -join ", ")
}  

Write-Information -InformationAction Continue -MessageData ("Found {0} unique objects. Saving output to {1}" -f $UniqueObjects.count, $OutputFull)

$UniqueObjects | Export-Csv $OutputFull -NoTypeInformation
