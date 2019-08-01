function Invoke-PortScan {
    <#
    .SYNOPSIS 
        Utilizes Test-NetConnection to perform rudimentary port scanning.

    .DESCRIPTION 
        Utilizes Test-NetConnection to perform rudimentary port scanning. 
        Note that this is much slower due than things like nmap due to lack 
        of multithreading. However tools like PoshRSJob will certainly 
        speed things up.

    .PARAMETER Computer  
        Computer can be a single hostname, FQDN, or IP address.

    .EXAMPLE 
        Invoke-PortScan SomeHostName.domain.com
        Get-Content C:\hosts.txt | Invoke-PortScan
        Get-ADComputer -filter * | Select -ExpandProperty Name | Invoke-PortScan

    .NOTES
        Updated: 2018-08-14

        Contributing Authors:
            Anthony Phipps
            
        LEGAL: Copyright (C) 2018
        This program is free software: you can redistribute it and/or modify
        it under the terms of the GNU General Public License as published by
        the Free Software Foundation, either version 3 of the License, or
        (at your option) any later version.
    
        This program is distributed in the hope that it will be useful,
        but WITHOUT ANY WARRANTY; without even the implied warranty of
        MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
        GNU General Public License for more details.

        You should have received a copy of the GNU General Public License
        along with this program.  If not, see <http://www.gnu.org/licenses/>.

    .LINK
       https://github.com/TonyPhipps/THRecon
    #>

    [CmdletBinding()]
    param(
    	    [Parameter(ValueFromPipeline=$True, ValueFromPipelineByPropertyName=$True)]
            $Computer = $env:COMPUTERNAME,

            [Parameter()]
            [alias("Port","Ports")]
            [array]
            $PortsArray = (80, 443, 593, 135, 139, 445, 3389, 5988, 5989)
        )

	begin{

        $DateScanned = Get-Date -Format u
        Write-Information -InformationAction Continue -MessageData ("Started {0} at {1}" -f $MyInvocation.MyCommand.Name, $DateScanned)

        $stopwatch = New-Object System.Diagnostics.Stopwatch
        $stopwatch.Start()
    }

    process{

        class Port {
            [String] $Computer
            [string] $DateScanned

            [String] $RemoteAddress
            [String] $RemotePort
            [String] $TCPTestSucceeded
        }

        $OutputArray = foreach ($Port in $PortsArray) {

            $Scan = Test-NetConnection -ComputerName $Computer -Port $Port | Select-Object ComputerName, RemoteAddress, RemotePort, TCPTestSucceeded

            $output = $null
            $output = [Port]::new()

            $output.Computer = $Computer
            $output.DateScanned = Get-Date -Format o

            $output.RemoteAddress = $Scan.RemoteAddress
            $output.RemotePort = $Scan.RemotePort
            $output.TcpTestSucceeded = $Scan.TcpTestSucceeded
            
            $output
        }

        return $OutputArray
    }
}