# https://gist.github.com/jasonadsit/2ed555868a995ba4b429dafb18ecf6e4

function Get-DecodedMRU {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,Position=0,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]
        [string] $MRU
    )
    process {
        $ErrorActionPreferenceBak = $ErrorActionPreference
        $ErrorActionPreference = [System.Management.Automation.ActionPreference]::Stop
        try {
            $items = Get-Item -Path $MRU | Select-Object -ExpandProperty Property
            $data = @()
            foreach ($item in $items) {
                    $name = $item
                    $valuekind = $($(Get-Item $MRU).GetValueKind("$name"))
                    $bin = (Get-ItemProperty -Path $MRU -Name $name -ErrorAction SilentlyContinue)."$name"
                    if ($valuekind -eq "BINARY") {
                        $decoded = @()
                        $asciirange = 32..126
                        foreach ($dec in $bin) {
                            if ($asciirange -like $dec) {
                                $decoded += [char]$dec
                            } #if ($asciirange -like $dec)
                        } #foreach
                    } #if ($valuekind -eq "BINARY")
                    $data += New-Object -TypeName psobject -Property @{ 
                        Name = [string] "$name"
                        BinaryValue = [byte[]] $bin
                        DecodedValue = [string] $($decoded -join "")
                        Type = [string] $valuekind
                    }
            } #foreach ($item in $items)
        } catch {
            # Nothing to see here. Move along.
        } #trycatch
        $ErrorActionPreference = $ErrorActionPreferenceBak
    Write-Output -InputObject $data
    Clear-Variable -Name name
    Clear-Variable -Name bin
    Clear-Variable -Name decoded
    Clear-Variable -Name valuekind
    Clear-Variable -Name data
    } #process
} #function Get-DecodedMRU