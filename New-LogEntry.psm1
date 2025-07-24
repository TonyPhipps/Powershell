function New-LogEntry {
    <#
    .SYNOPSIS 
        Creates Write-Host message, outputs to a file, and creates an event log entry all at once.
    
    .DESCRIPTION 
        Creates Write-Host message, outputs to a file, and creates an event log entry all at once.
        Only creates a log entry if -Source is specified.
        Only outputs to a log file if -LogFile is specified. 
    
    .PARAMETER LogName  
        The name of the Event Log that will be created/added to under Event Viewer > Applications and Service Logs
    
    .PARAMETER Source
        This value will be used to set the Source field in the Event Log entry.
    
    .PARAMETER EventID
        This value will be used to set the Event ID field in the Event Log entry.
    
    .PARAMETER EntryType
        This value will be used to set the Level field in the Event Log entry.
    
    .PARAMETER Category
        This value will be used to set the Task Category field in the Event Log entry.
    
    .PARAMETER LogFile
        The Full Path to the file that will contain a copy of the logs.
    
    .PARAMETER LogFileHeader
        The header line of the log file, intended for use with .csv output.
    
    .PARAMETER Message
        The primary Message to share in console/event log/log file.

    .PARAMETER ForegroundColor
        Sets the ForegroundColor when using Write-Host to post the message to console.

    .EXAMPLE
        New-LogEntry -logname "MyLog" -source "MyScript" -Message "This is the message"
    
        Will only output to Event Log and console.
    
    .EXAMPLE
        New-LogEntry -Logname "MyLog" -Source "MyScript" -LogFile "MyScript_log" + ".csv") -LogFileHeader "`"Date`",`"Message`"" -Message "This is the message"
        
        WIll output to Event Log, console, and a MyScript_.log.csv with headers.
    
    .NOTES 
        Updated: 2025-07-23
        
        Contributing Authors:
            Anthony Phipps
        
        LEGAL: Copyright (C) 2025
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
        https://github.com/TonyPhipps
    #>
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]$LogName,		
        
        [Parameter()]
        [string]$Source,
        
        [Parameter()]
        [string]$EventID = 0,
        
        [Parameter()]
        [string]$EntryType = "Information",
        
        [Parameter()]
        [string]$Category,
        
        [Parameter()]
        [string]$LogFile,

        [Parameter()]
        [string]$LogFileHeader,
        
        [Parameter()]
        [string]$MessagePrefix,

        [Parameter()]
        [string]$Message,

        [Parameter()]
        [string]$MessageSuffix,

        [Parameter()]
        [string]$ForegroundColor = "White"
    )
    if ($Source -and -not (Get-EventLog -list | Where-Object { $_.logdisplayname -eq $LogName })) { # Event Log doesnt exist
        New-EventLog -LogName $LogName -Source @($Source)
        Limit-EventLog -LogName $LogName -MaximumSize 50MB -OverflowAction OverwriteAsNeeded
    }
    if ($Source -and -not (Get-EventLog $LogName -Source $Source -Newest 1 -ErrorAction SilentlyContinue)) { # Event Log exists, but not Source
        New-EventLog -LogName $LogName -Source $Source
        Limit-EventLog -LogName $LogName -MaximumSize 50MB -OverflowAction OverwriteAsNeeded
    }
    if ($Source -and (Get-EventLog -list | Where-Object { $_.logdisplayname -eq $LogName })) { # Event Log and Source exist
        $Message = ($Message[0..32000] -join "")
        if ($Message -match "Error" -or $Message -match "Exception") { $EntryType = "Error" }
        Write-EventLog -LogName $LogName -Source $Source -EventID $EventID -EntryType $EntryType -Category $Category -Message $Message
    }
    if ($Source -and -not (Get-EventLog -list | Where-Object { $_.logdisplayname -eq $LogName })) { # Event Log failed to create
        Write-Information "The log does not already exist and could not be created."
    }
    if ($LogFile) {
        $FileExists = Test-Path $LogFile
        if (-not $FileExists){
            $LogDir = Split-Path -Path $LogFile -Parent
        if (-not (Test-Path -Path $LogDir)) {
            New-Item -Path $LogDir -ItemType Directory -Force
        }
            $LogFileHeader | Out-File -FilePath $LogFile -Force
            $FileExists = $True
        }
        if ($FileExists){
            Add-Content -Path $LogFile -Value ($MessagePrefix + $Message + $MessageSuffix)
        }
    }
    Write-Host "$($Message)" -ForegroundColor $ForegroundColor
}