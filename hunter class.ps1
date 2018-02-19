class Hunter {
    [String] $Target
    [DateTime] $StartTime
    [Boolean] $Success = $False
    [DateTime] $EndTime
    [System.Object[]] $Results


    Hunter([String] $Target){
        $this.Target = $Target
        $this.StartTime = Get-Date;
    }

    Hunter(){
        $this.Target = 'localhost'
        $this.StartTime = Get-Date;
    }

    [System.Object] CIMInstance([String] $ClassName){
        
        $this.Results = Get-CimInstance -ClassName $ClassName -ComputerName $this.Target | 
            Select-Object * -ExcludeProperty Cim*;
        
        $this.Results | ForEach-Object {
            $_ | Add-Member -MemberType NoteProperty -Name "Target" -Value $this.Target;
            $_ | Add-Member -MemberType NoteProperty -Name "Time" -Value $(Get-Date);
        }
        
        if ($this.Results -ne $null) { 

            $this.Success = $True;
        }
        else {

            $this.Success = $False;
            $this.Results.Target | Add-Member -MemberType NoteProperty -Name "Target" -Value $this.Target;
        };

        $this.EndTime = $(Get-Date);
        return $this;
    }

    [System.Object] WmiObject([String] $ClassName){
        
        $this.Results = Get-WmiObject -ClassName $ClassName -ComputerName $this.Target | 
            Select-Object * -ExcludeProperty __*, Scope, Options, ClassPath, Properties, SystemProperties, Qualifiers, Site, Container;
        
        $this.Results | ForEach-Object {
            $_ | Add-Member -MemberType NoteProperty -Name "Target" -Value $this.Target;
            $_ | Add-Member -MemberType NoteProperty -Name "Time" -Value $(Get-Date);
        };
        
        if ($this.Results -ne $null) {

            $this.Success = $True;
        }
        else {

            $this.Success = $False;
            $this.Results.Target | Add-Member -MemberType NoteProperty -Name "Target" -Value $this.Target;
        };

        $this.EndTime = $(Get-Date);
        return $this;
    }
};

## Test Area
#$a = @("localxhost", "127.0.0.1")

#$a | ForEach-Object {
#    $test = New-Object Hunter($_);
#    $test.CIMInstance("Win32_StartupCommand");}
#    ($test.CIMInstance("Win32_StartupCommand")).Results | Select-Object *;};
#$test.CIMInstance('localhost', "Win32_StartupCommand") | Select-Object *;
