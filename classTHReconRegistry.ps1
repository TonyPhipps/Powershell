class THReconRegistry{
    [String]$Target
    [String]$DateScanned
    [array]$Results
    static [scriptblock]$Scriptblock = {
        # Parse each user hive
        # Make property for each user (or system)
        
        $keys = 
        #"Registry::HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run",
        #"Registry::HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run32",
        #"Registry::HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\StartupFolder",
        "Registry::HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer\Run",
        "Registry::HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Run",
        "Registry::HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\RunOnce",
        #"Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run",
        #"Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run32",
        #"Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\StartupFolder",
        "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer\Run",
        "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Run",
        "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce",
        "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Run",
        "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\RunOnce";
    
        $OutputArray = @();
    
        foreach ($key in $keys){
    
            if (Test-Path $key){
        
                if (Get-ItemProperty -Path $key){
        
                    $Properties = Get-ItemProperty -Path $key | 
                        Get-Member -MemberType NoteProperty | 
                        Where-Object {$_.Name -notmatch "PSParentPath|PSPath|PSChildName|PSProvider"} | 
                        Select-Object -ExpandProperty Name;
        
                    if ($Properties) {
        
                        foreach ($Property in $Properties){
        
                            $OutputArray += [pscustomobject] @{
                                Key = $key.Split(":")[2];
                                Value = $Property; 
                                Data = (Get-ItemProperty -Path $key -Name $Property).$Property;
                            };
                        };
                    };
                };
            };
        };
        
        return $OutputArray;
    }

    THReconRegistry(){
        $this.Target = $env:COMPUTERNAME
        $this.DateScanned = Get-Date -Format u
    }

    THReconRegistry([String]$Target){
        $this.Target = $Target
        $this.DateScanned = Get-Date -Format u
    }
    
    Hunt() {
        $this.Results = Invoke-Command -ComputerName $this.Target -ScriptBlock ([scriptblock]::Create([THReconRegistry]::Scriptblock)) | Select-Object -Property * -ExcludeProperty PSComputerName,RunSpaceId
    }
}






#Get-ChildItem -Path "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Startup"