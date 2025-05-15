if ( ($psISE) -and (Test-Path -Path $psISE.CurrentFile.FullPath)) {
    $ScriptRoot = Split-Path -Path $psISE.CurrentFile.FullPath -Parent
} else {
    $ScriptRoot = $PSScriptRoot
}
$ScriptParent = Split-Path -Path $ScriptRoot -Parent

$inputDir = (Join-Path -Path $ScriptParent -ChildPath 'rules')

Install-Module powershell-yaml -Scope CurrentUser
$Files = Get-Childitem -Path $inputDir -Recurse -Include '*.yml'
[array]$CSV = ForEach ($File in $Files){
            if ($File.GetType().Name -eq "FileInfo"){
                $FullName = $File.FullName
                $YAML = ConvertFrom-Yaml (Get-Content ($File.FullName) -raw)
                Get-FlatYAML $YAML $FullName
            }
        }

        $CSV | 
            Select-Object title, name, id, status, description, references, author, date, modified, tags, logsource.category, logsource.definition, logsource.product, logsource.service, falsepositives, level, license, original | 
                Export-csv -NoTypeInformation sigma.csv