FUNCTION Get-Processes {
    <#
    .Synopsis 
        Gets the processes applied to a given system.

    .Description 
        Gets the processes applied to a given system, including usernames.

    .Parameter Computer  
        Computer can be a single hostname, FQDN, or IP address.

    .Parameter Services  
        Includes Services associated with each Process ID. Slows processing per system by a small amount while service are pulled.

    .Parameter DLLs  
        Includes DLLs associated with each Process ID. Note that DLLs cannot be pulled on remote systems due to lack of support in Get-Process.

    .Parameter Fails  
        Provide a path to save failed systems to.

    .Example 
        Get-Processes 
        Get-Processes SomeHostName.domain.com
        Get-Content C:\hosts.csv | Get-Processes
        Get-Processes $env:computername
        Get-ADComputer -filter * | Select -ExpandProperty Name | Get-Processes

    .Notes 
        Updated: 2017-08-01
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
            [switch]$Services,
            [Parameter()]
            [switch]$DLLs,
            [Parameter()]
            $Fails

        );

	    BEGIN{

            $datetime = Get-Date -Format "yyyy-MM-dd_hh.mm.ss.ff";
            Write-Information -MessageData "Started at $datetime" -InformationAction Continue;

            $stopwatch = New-Object System.Diagnostics.Stopwatch;
            $stopwatch.Start();

            $total = 0;
	    }

        PROCESS{

            $Computer = $Computer.Replace('"', '');  # get rid of quotes, if present

            $Processes = $null;
            $Mode = $null;
            
             #Try with -IncludeUserName, then fallback to older version, then fallback to not using Invoke-Command
            
			$Processes = Invoke-Command -ComputerName $Computer -ScriptBlock {Get-Process -IncludeUserName} -ErrorAction SilentlyContinue;
            
            If ($Processes -eq $null){
            
                $Processes = Invoke-Command -ComputerName $Computer -ScriptBlock {Get-Process} -ErrorAction SilentlyContinue;
				
				If ($Processes -eq $null){

					$Processes = Get-Process -ComputerName $Computer -ErrorAction SilentlyContinue;
					$Mode = "3";
				}
				else{
					$Mode = "2";
				};
            }
			else{
				$Mode = "1";
			};

            
            
        
            if ($Processes){ # The system was reachable, and Get-Process worked
        
                if ($Services){ # The -services switch was selected, so pull service info
                    $CIM_Services = $null;
                    $CIM_Services = Get-CIMinstance -class Win32_Service -Filter "Caption LIKE '%'" -ComputerName $Computer -ErrorAction SilentlyContinue;
                    # Odd filter explanation: http://itknowledgeexchange.techtarget.com/powershell/cim-session-oddity/
                };
            
                $CIM_Processes = $null;
                $CIM_Processes = Get-CIMinstance -class Win32_Process -Filter "Caption LIKE '%'" -ComputerName $Computer -ErrorAction SilentlyContinue;

                $Processes | ForEach-Object { # Work on each process provided in $Processes array

                    $ProcessID = $null;
                    $ProcessID = $_.Id;

                
                    if ($Services -AND $CIM_Services){ # The -services switch was selected, so pull service info on this process
                    
                        $ThisServices = $null;
                        $ThisServices = $CIM_Services | Where-Object ProcessID -eq $ProcessID;
                    };
                
                    if ($CIM_Processes){ # If CIM process collection worked, pull commandline and owner information

                        $CommandLine = $null;
                        $CommandLine = $CIM_Processes | Where-Object ProcessID -eq $ProcessID | Select-Object -ExpandProperty CommandLine;

                        if ($_.UserName -eq $null){
                            $ProcessOwner = $null;
                            $ProcessOwner = $CIM_Processes | Where-Object ProcessID -eq $ProcessID | Invoke-CimMethod -MethodName GetOwner -ErrorAction SilentlyContinue | Select-Object Domain, User;
                        };
                    };

                    $output = $null;
                    $output = [PSCustomObject]@{

                        Computer = $Computer;
						Mode = $Mode;
                        BasePriority = $_.BasePriority;
                        CPU = $_.CPU;
                        CommandLine = $CommandLine;
                        Company = $_.Company;
                        Description = $_.Description;
                        EnableRaisingEvents = $_.EnableRaisingEvents;
                        FileVersion = $_.FileVersion;
                        Handle = $_.Handle;
                        HandleCount = $_.HandleCount;
                        Id = $_.Id;
                        MainModule = if ($_.MainModule){ if ($_.MainModule.GetType().Name -eq "String") {$_.MainModule.Replace('System.Diagnostics.ProcessModule (', '').Replace(')', '');}else {($_.MainModule)};};
                        MainWindowHandle = $_.MainWindowHandle;
                        MainWindowTitle = $_.MainWindowTitle;
                        ModuleCount = @($_.Modules).Count;
                        DisplayName = $_.Name;
                        Path = $_.Path;
                        PriorityBoostEnabled = $_.PriorityBoostEnabled;
                        PriorityClass = $_.PriorityClass;
                        PrivilegedProcessorTime = $_.PrivilegedProcessorTime;
                        ProcessName = $_.ProcessName;
                        ProcessorAffinity = $_.ProcessorAffinity;
                        Product = $_.Product;
                        ProductVersion = $_.ProductVersion;
                        Responding = $_.Responding;
                        SessionId = $_.SessionId;
                        StartTime = $_.StartTime;
                        Threads = @($_.Threads).Count;
                        TotalProcessorTime = $_.TotalProcessorTime;
                        UserName = if ($_.UserName) {$_.UserName} elseif ($ProcessOwner.User) {$ProcessOwner.Domain+"\"+$ProcessOwner.User;};
                        Services = if ($ThisServices) {$ThisServices.PathName -Join "; ";};
                        DLLs = if ($DLLs -AND $_.Modules) {$_.Modules.Replace('System.Diagnostics.ProcessModule (', '').Replace(')', '') -join "; ";};
						
						<#
                        UserName = if ($ProcessOwner.User) {$ProcessOwner.Domain+"\"+$ProcessOwner.User;};
                        MachineName = $_.MachineName;
                        NonpagedSystemMemorySize = $_.NonpagedSystemMemorySize;
                        NonpagedSystemMemorySize64 = $_.NonpagedSystemMemorySize64;
                        MaxWorkingSet = $_.MaxWorkingSet;
                        MinWorkingSet = $_.MinWorkingSet;
                        PagedMemorySize = $_.PagedMemorySize;
                        PagedMemorySize64 = $_.PagedMemorySize64;
                        PeakPagedMemorySize = $_.PeakPagedMemorySize;
                        PeakPagedMemorySize64 = $_.PeakPagedMemorySize64;
                        PeakVirtualMemorySize = $_.PeakVirtualMemorySize;
                        PeakVirtualMemorySize64 = $_.PeakVirtualMemorySize64;
                        PeakWorkingSet = $_.PeakWorkingSet;
                        PeakWorkingSet64 = $_.PeakWorkingSet64;
                        PrivateMemorySize = $_.PrivateMemorySize;
                        PrivateMemorySize64 = $_.PrivateMemorySize64;
                        UserProcessorTime = $_.UserProcessorTime;
                        VirtualMemorySize = $_.VirtualMemorySize;
                        VirtualMemorySize64 = $_.VirtualMemorySize64;
                        WorkingSet = $_.WorkingSet;
                        WorkingSet64 = $_.WorkingSet64;
                        #>
                    };
                
                    return $output; 
                };#end of each object processed for this system
        
            }
            else { # System was not reachable

                if ($Fails) { # -Fails switch was used
                    Add-Content -Path $Fails -Value ("$Computer");
                }
                else{ # -Fails switch not used
                            
                    $output = $null;
                    $output = [PSCustomObject]@{
                        Computer = $Computer;
						Mode = "";
						BasePriority = "";
                        CPU = "";
                        CommandLine = "";
                        Company = "";
                        Description = "";
                        EnableRaisingEvents = "";
                        FileVersion = "";
                        Handle = "";
                        HandleCount = "";
                        Id = "";
                        MainModule = "";
                        MainWindowHandle = "";
                        MainWindowTitle = "";
                        ModuleCount = "";
                        DisplayName = "";
                        Path = "";
                        PriorityBoostEnabled = "";
                        PriorityClass = "";
                        PrivilegedProcessorTime = "";
                        ProcessName = "";
                        ProcessorAffinity = "";
                        Product = "";
                        ProductVersion = "";
                        Responding = "";
                        SessionId = "";
                        StartTime = "";
                        Threads = "";
                        TotalProcessorTime = "";
                        UserName = "";
                        Services = "";
                        DLLs = "";
                    };

                    return $output;
                };
            };
         
            $elapsed = $stopwatch.Elapsed;
            $total = $total+1;
            
            Write-Information -MessageData "System $total `t $ThisComputer `t Time Elapsed: $elapsed" -InformationAction Continue;

        };

        END{
            $elapsed = $stopwatch.Elapsed;

            Write-Information -MessageData "Total Systems: $total `t Total time elapsed: $elapsed" -InformationAction Continue;
	    };
    };




