FUNCTION Get-Processes {
<#
.Synopsis 
    Gets the processes applied to a given system.

.Description 
    Gets the processes applied to a given system, including usernames.

.Parameter Computer  
    Computer can be a single hostname, FQDN, or IP address.

.Parameter Services  
    Includes Services associated with each Process ID. Slows processing per item.

.Example 
    Get-Processes 
    Get-Processes SomeHostName.domain.com
    Get-Content C:\hosts.csv | Get-Processes
    Get-Processes $env:computername
    Get-ADComputer -filter * | Select -ExpandProperty Name | Get-Processes

.Notes 
    Updated: 2017-07-26
    LEGAL: Copyright (C) 2017  Anthony Phipps
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
#>

    PARAM(
    	[Parameter(ValueFromPipeline=$True, ValueFromPipelineByPropertyName=$True)]
        $Computer,
        [Parameter()]
        [switch]$Services
    );

	BEGIN{

        $datetime = Get-Date -Format "yyyy-MM-dd_hh.mm.ss.ff";
        Write-Verbose "Started at $datetime"

        $stopwatch = New-Object System.Diagnostics.Stopwatch;
        $stopwatch.Start();

        $total = 0;
	}

    PROCESS{

        $output = [PSCustomObject]@{
            Name = $Computer
            BasePriority = ""
            CPU = ""
            CommandLine = ""
            Company = ""
            Description = ""
            EnableRaisingEvents = ""
            FileVersion = ""
            Handle = ""
            HandleCount = ""
            Id = ""
            MachineName = ""
            MainModule = ""
            MainWindowHandle = ""
            MainWindowTitle = ""
            MaxWorkingSet = ""
            MinWorkingSet = ""
            Modules = ""
            DisplayName = ""
            NonpagedSystemMemorySize = ""
            NonpagedSystemMemorySize64 = ""
            PagedMemorySize = ""
            PagedMemorySize64 = ""
            PagedSystemMemorySize = ""
            PagedSystemMemorySize64 = ""
            Path = ""
            PeakPagedMemorySize = ""
            PeakPagedMemorySize64 = ""
            PeakVirtualMemorySize = ""
            PeakVirtualMemorySize64 = ""
            PeakWorkingSet = ""
            PeakWorkingSet64 = ""
            PriorityBoostEnabled = ""
            PriorityClass = ""
            PrivateMemorySize = ""
            PrivateMemorySize64 = ""
            PrivilegedProcessorTime = ""
            ProcessName = ""
            ProcessorAffinity = ""
            Product = ""
            ProductVersion = ""
            Responding = ""
            Services = ""
            SessionId = ""
            StartTime = ""
            Threads = ""
            TotalProcessorTime = ""
            UserName = ""
            UserProcessorTime = ""
            VirtualMemorySize = ""
            VirtualMemorySize64 = ""
            WorkingSet = ""
            WorkingSet64 = ""
            
        };

        $Processes = Get-Process -ComputerName $Computer
        
        if ($Processes){
            
            $Processes | ForEach-Object {
                $ProcessID = $_.Id;

                $Win32_Process = Get-CIMinstance -class Win32_Process -ComputerName $Computer -Filter "ProcessID = $ProcessID";
                if ($Services){
                    $Win32_Service = Get-CIMinstance -class Win32_Service -ComputerName $Computer -Filter "ProcessID = $ProcessID";
                };
                $CommandLine = $Win32_Process.CommandLine;
                $ProcessOwner = Invoke-CimMethod -InputObject $Win32_Process -MethodName GetOwner | select Domain, User;

                $output.BasePriority = $_.BasePriority;
                $output.CPU = $_.CPU;
                $output.CommandLine = $CommandLine;
                $output.Company = $_.Company;
                $output.Description = $_.Description;
                $output.EnableRaisingEvents = $_.EnableRaisingEvents;
                $output.FileVersion = $_.FileVersion;
                $output.Handle = $_.Handle;
                $output.HandleCount = $_.HandleCount;
                $output.Id = $_.Id;
                $output.MachineName = $_.MachineName;
                $output.MainModule = $_.MainModule;
                $output.MainWindowHandle = $_.MainWindowHandle;
                $output.MainWindowTitle = $_.MainWindowTitle;
                $output.MaxWorkingSet = $_.MaxWorkingSet;
                $output.MinWorkingSet = $_.MinWorkingSet;
                $output.Modules = @($_.Modules).Count;
                $output.DisplayName = $_.Name;
                $output.NonpagedSystemMemorySize = $_.NonpagedSystemMemorySize;
                $output.NonpagedSystemMemorySize64 = $_.NonpagedSystemMemorySize64;
                $output.PagedMemorySize = $_.PagedMemorySize;
                $output.PagedMemorySize64 = $_.PagedMemorySize64;
                $output.Path = $_.Path;
                $output.PeakPagedMemorySize = $_.PeakPagedMemorySize;
                $output.PeakPagedMemorySize64 = $_.PeakPagedMemorySize64;
                $output.PeakVirtualMemorySize = $_.PeakVirtualMemorySize;
                $output.PeakVirtualMemorySize64 = $_.PeakVirtualMemorySize64;
                $output.PeakWorkingSet = $_.PeakWorkingSet;
                $output.PeakWorkingSet64 = $_.PeakWorkingSet64;
                $output.PriorityBoostEnabled = $_.PriorityBoostEnabled;
                $output.PriorityClass = $_.PriorityClass;
                $output.PrivateMemorySize = $_.PrivateMemorySize;
                $output.PrivateMemorySize64 = $_.PrivateMemorySize64;
                $output.PrivilegedProcessorTime = $_.PrivilegedProcessorTime;
                $output.ProcessName = $_.ProcessName;
                $output.ProcessorAffinity = $_.ProcessorAffinity;
                $output.Product = $_.Product;
                $output.ProductVersion = $_.ProductVersion;
                $output.Responding = $_.Responding;
                $output.SessionId = $_.SessionId;
                $output.StartTime = $_.StartTime;
                $output.Threads = @($_.Threads).Count;
                $output.TotalProcessorTime = $_.TotalProcessorTime;
                $output.UserName = $ProcessOwner.Domain+"\"+$ProcessOwner.User;
                $output.UserProcessorTime = $_.UserProcessorTime;
                $output.VirtualMemorySize = $_.VirtualMemorySize;
                $output.VirtualMemorySize64 = $_.VirtualMemorySize64;
                $output.WorkingSet = $_.WorkingSet;
                $output.WorkingSet64 = $_.WorkingSet64;
                if ($Win32_Service){
                    $output.Services = $Win32_Service.Name -Join "; "; 
                };

                return $output;
                $output.PsObject.Members | ForEach-Object {$output.PsObject.Members.Remove($_.Name)}; 
                $ProcessOwner.PsObject.Members | ForEach-Object {$ProcessOwner.PsObject.Members.Remove($_.Name)}; 
            };
        }
        else {

            return $output;
            $output.PsObject.Members | ForEach-Object {$output.PsObject.Members.Remove($_.Name)}; 
        };

        $elapsed = $stopwatch.Elapsed;
        $total = $total++;
            
        Write-Verbose -Message "System $total `t $ThisComputer `t Time Elapsed: $elapsed";

    };

    END{
        $elapsed = $stopwatch.Elapsed;
        Write-Verbose "Total Systems: $total `t Total time elapsed: $elapsed";
	};
};




