function Get-FlatYAML {
    param (
        [Parameter(Mandatory)]
        $InputObject
    )

    # Sample $InputObject:
    # Find-Module -Repository psgallery *yaml*
    # Install-Module powershell-yaml -Scope CurrentUser
    # Get-Help ConvertFrom-YAML
    # $SampleInput = ConvertFrom-Yaml (Get-Content ($File.FullName) -raw)

    $Output = New-Object -TypeName PSObject

    if ($inputObject -is [Hashtable]){
        foreach ($Key in $InputObject.Keys) { # review each member
            $Member = $InputObject.$Key
            if ($member -is [Hashtable]){
                #-----------------Level 2-----------------
                foreach ($Key2 in $Member.Keys) { # review each member
                    $Member2 = $Member.$Key2
                    if ($Member2 -is [Hashtable]){
                        #-----------------Level 3-----------------
                        foreach ($Key3 in $Member2.Keys) { # review each member
                            $Member3 = $Member2.$Key3
                            if ($Member3 -is [Hashtable]){
                                Write-Host "is hashtable: $Key.$Key2.$Key3. Add another level."
                            }
                            elseif ($Member2.$Key3 -is [System.Collections.ICollection]) {
                                #Write-Host "is ICollection: $Key.$Key2.$Key3"
                                $ICollection3 = $Member2.$Key3 -join ", "
                                $Output | Add-Member -MemberType NoteProperty -Name ($Key + "." + $Key2 + "." + $Key3) -Value $ICollection3 -ErrorAction SilentlyContinue | Out-Null
                            }
                            elseif ($Member3.GetType().Name -is [String]) {
                                #Write-Host "is string: $Key.$Key2.$Key3"
                                $Output | Add-Member -MemberType NoteProperty -Name ($Key + "." + $Key2 + "." + $Key3) -Value $Member3 -ErrorAction SilentlyContinue | Out-Null
                            }
                            else {
                                Write-Host "is ($Member3.GetType().Name): $Key.$Key2.$Key3" 
                            }            
                        }
                        #-----------------Level 3 END-----------------
                    }
                    elseif ($Member.$Key2 -is [System.Collections.ICollection]) {
                        #Write-Host "is ICollection: $Key.$Key2"
                        $ICollection2 = $Member2.$Key2 -join ", "
                        $Output | Add-Member -MemberType NoteProperty -Name ($Key + "." + $Key2) -Value $ICollection2 -ErrorAction SilentlyContinue | Out-Null
                    }
                    elseif ($Member2.GetType().Name -is [String]) {
                        #Write-Host "is string: $Key.$Key2"
                        $Output | Add-Member -MemberType NoteProperty -Name ($Key + "." + $Key2) -Value $Member2 -ErrorAction SilentlyContinue | Out-Null
                    }
                    else {
                        #Write-Host "is ($Member2.GetType().Name): $Key.$Key2" 
                    }               
                #-----------------Level 2 END-----------------
                }
            }
            elseif ($InputObject.$Key -is [System.Collections.ICollection]) {
                #Write-Host "is ICollection: $Key"
                $ICollection = $InputObject.$key -join ", "
                $Output | Add-Member -MemberType NoteProperty -Name $Key -Value $ICollection -ErrorAction SilentlyContinue | Out-Null
            }
            elseif ($Member.GetType().Name -is [String]) {
                #Write-Host "is string: $Key"
                $Output | Add-Member -MemberType NoteProperty -Name $Key -Value $Member -ErrorAction SilentlyContinue | Out-Null
            }            
            else {
                Write-Host "is ($Member.GetType().Name): $Key" 
            }               
        }
    }
    return $Output
}

Flatten-Object($YamlObjects[5])
