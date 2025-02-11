function Get-FlatYAML {
    param (
        [Parameter(Mandatory)]
        $InputObject,

        [String]$InputFileName
    )

    # Sample $InputObject
    # Find-Module -Repository psgallery *yaml*
    # Install-Module powershell-yaml -Scope CurrentUser
    # Get-Help ConvertFrom-YAML
    # $SampleInput = ConvertFrom-Yaml (Get-Content ($File.FullName) -raw)

    # Sample Mass Use
    # $Files = Get-ChildItem -Path "C:\Users\username\Downloads\sigma-master\sigma-master\rules*" -Recurse -Include *.yml

    # [array]$CSV = ForEach ($File in $Files){
    #     if ($File.GetType().Name -eq "FileInfo"){
    #         $FullName = $File.FullName
    #         $YAML = ConvertFrom-Yaml (Get-Content ($File.FullName) -raw)
    #         Get-FlatYAML $YAML $FullName
    #     }
    # }

    # $CSV | 
    #     Select-Object title, name, id, status, description, references, author, date, modified, tags, logsource.category, logsource.definition, logsource.product, logsource.service, falsepositives, level, license, original | 
    #     Export-csv -NoTypeInformation sigma.csv

    $Output = New-Object -TypeName PSObject

    if ($inputObject -is [Hashtable]){
        foreach ($Key in $InputObject.Keys) { # review each member
            $Member = $InputObject.$Key
            if ($Member -is [Hashtable]){
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
                            elseif ($Member3 -is [System.Collections.ICollection]) {
                                $ICollection3 = $Member2.$Key3 -join ", "
                                $Output | Add-Member -MemberType NoteProperty -Name ($Key + "." + $Key2 + "." + $Key3) -Value $ICollection3 -ErrorAction SilentlyContinue | Out-Null
                            }
                            elseif ($NULL -eq $Member3) {
                            }
                            elseif ($Member3.GetType().Name -in ("String","Int32","long","bool")) {
                                $Output | Add-Member -MemberType NoteProperty -Name ($Key + "." + $Key2 + "." + $Key3) -Value $Member3 -ErrorAction SilentlyContinue | Out-Null
                            }
                            else {
                                Write-Host "Level 3 - $Key.$Key2.$Key3 is a $($Member3.GetType())" 
                            }            
                        }
                        #-----------------Level 3 END-----------------
                    }
                    elseif ($Member.$Key2 -is [System.Collections.ICollection]) {
                        $ICollection2 = $Member2.$Key2 -join ", "
                        $Output | Add-Member -MemberType NoteProperty -Name ($Key + "." + $Key2) -Value $ICollection2 -ErrorAction SilentlyContinue | Out-Null
                    }
                    elseif ($Member2.GetType().Name -in ("String","Int32","long","bool")) {
                        $Output | Add-Member -MemberType NoteProperty -Name ($Key + "." + $Key2) -Value $Member2 -ErrorAction SilentlyContinue | Out-Null
                    }
                    else {
                        Write-Host "Level 2 - $Key.$Key2 is a $($Member2.GetType())" 
                    }               
                #-----------------Level 2 END-----------------
                }
            }
            elseif ($InputObject.$Key -is [System.Collections.ICollection]) {
                $ICollection = $InputObject.$key -join ", "
                $Output | Add-Member -MemberType NoteProperty -Name $Key -Value $ICollection -ErrorAction SilentlyContinue | Out-Null
            }
            elseif ($Member.GetType().Name -in ("String","Int32","long","bool")) {
                $Output | Add-Member -MemberType NoteProperty -Name $Key -Value $Member -ErrorAction SilentlyContinue | Out-Null
            }            
            else {
                $Member3.GetType()
                Write-Host "Level 1 - $Key is a $($Member.GetType())" 
            }               
        }
    }

    if ($InputFileName){
        $Original = Get-Content ($InputFileName) -raw
        $Output | Add-Member -MemberType NoteProperty -Name "Original" -Value $Original -ErrorAction SilentlyContinue | Out-Null
    }

    return $Output
}