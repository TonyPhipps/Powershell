function Get-Something {
    param(
        [Parameter(Mandatory)]
        [string]$ComputerName,
 
        [Parameter(Mandatory)]
        [string]$Param1,
 
        [Parameter(Mandatory)]
        [string]$Param2
    )
 
    $scriptBlock = {
        $args[0].GetEnumerator() | ForEach-Object { New-Variable -Name $_.Key -Value $_.Value }
        Write-Host "Doing something here to reference $Param1"
        Write-Host "Doing something here to reference $Param2"
    }
 
    ## Find all of the parameters with default values for the currently executing function
    $params = Get-FunctionDefaultParameter -FunctionName $MyInvocation.MyCommand.Name
 
    ## Ensure no bound parameters are $null that are actually default
    ## add all bound parameters to the $params hashtable
    $PSBoundParameters.GetEnumerator() | Where-Object { $_.Key -notin $params.Keys } | ForEach-Object { $params[$_.Key] = $params[$_.Value]}
 
    ## Pass all bound and default parameters to the remote scriptblock
    Invoke-Command -ComputerName $ComputerName -ScriptBlock $scriptBlock -ArgumentList $params
}