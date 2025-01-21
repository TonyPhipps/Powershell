function Join-Objects($source, $extend){
    if($source.GetType().Name -eq "PSCustomObject" -and $extend.GetType().Name -eq "PSCustomObject"){
        foreach($Property in $source | Get-Member -type NoteProperty, Property){
            if($null -eq $extend.$($Property.Name)){
              continue;
            }
            $source.$($Property.Name) = Join-Objects $source.$($Property.Name) $extend.$($Property.Name)
        }
    }else{
       $source = $extend;
    }
    return $source
}
function AddPropertyRecurse($source, $toExtend){
    if($source.GetType().Name -eq "PSCustomObject"){
        foreach($Property in $source | Get-Member -type NoteProperty, Property){
            if($null -eq $toExtend.$($Property.Id)){
              $toExtend | Add-Member -MemberType NoteProperty -Value $source.$($Property.Id) -Name $Property.Id `
            }
            else{
               $toExtend.$($Property.Id) = AddPropertyRecurse $source.$($Property.Id) $toExtend.$($Property.Id)
            }
        }
    }
    return $toExtend
}
function Merge-JSON($source, $extend){
    $merged = Join-Objects $source $extend
    $extended = AddPropertyRecurse $source $merged
    $extended
}

#read json files into PSCustomObjects like this:
#$1 = Get-Content 'C:\1.json' -Raw | ConvertFrom-Json
#$2 = Get-Content 'C:\2.json'-Raw | ConvertFrom-Json
#Merge properties of the first one and second one.
#$3 = Json-Merge $1 $2