function Set-EnhancedLogging {
    <#
    .SYNOPSIS
        Configures multiple audit policies, override setting, and event log sizes in a specified GPO, creating the GPO if it doesn't exist.

    .PARAMETER GpoName
        The name of the GPO to configure. Defaults to "Enhanced Logging" if not specified.

    .PARAMETER Domain
        The Active Directory domain to use. If not specified, the current computer's domain is used.

    .EXAMPLE
        Set-EnhancedLogging -GpoName "MyAuditPolicy" -Domain "contoso.local"
        Configures audit policies, override setting, and event log sizes in the "MyAuditPolicy" GPO in the contoso.local domain.

    .EXAMPLE
        Set-EnhancedLogging
        Configures audit policies, override setting, and event log sizes in the default GPO "Enhanced Logging" in the current computer's domain.
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$GpoName = "Enhanced Logging",

        [Parameter(Mandatory = $false)]
        [string]$Domain = (Get-WmiObject Win32_ComputerSystem).Domain
    )

    # Import the GroupPolicy module
    try {
        Import-Module GroupPolicy -ErrorAction Stop
    }
    catch {
        Write-Error "Failed to import GroupPolicy module: $_"
        return
    }

    # Define preset audit settings, override setting, and event log sizes
    $AuditSettings = @(
        #PowerShell
        @{
            Name        = "Enable Module Logging"
            Subcategory = "ModuleLogging"
            RegistryKey = "SOFTWARE\Policies\Microsoft\Windows\PowerShell\ModuleLogging"
            ValueName   = "EnableModuleLogging"
            Type        = "DWord"
            Value       = 1 # Enabled
        },
        @{
            Name        = "Enable Module Logging for All Modules"
            Subcategory = "ModuleLogging"
            RegistryKey = "SOFTWARE\Policies\Microsoft\Windows\PowerShell\ModuleLogging\ModuleNames"
            ValueName   = "*"
            Type        = "String"
            Value       = "*" # Log all modules
        },
        # Audit Policies
        @{
            Name = "Audit Process Creation"
            Subcategory = "Process Creation"
            RegistryKey = "MACHINE\System\CurrentControlSet\Control\Lsa\Audit\PerUserAuditing\System\Process Creation"
            ValueName = "AuditSetting"
            Type = "DWord"
            Value = 3  # 3 = Success + Failure
        },
        # Event Log Sizes
        @{
            Name = "Security Log Maximum Size"
            Subcategory = "Security Log"
            RegistryKey = "MACHINE\System\CurrentControlSet\Services\Eventlog\Security"
            ValueName = "MaxSize"
            Type = "DWord"
            Value = 524288000  # 500 MB in bytes
        },
        @{
            Name = "System Log Maximum Size"
            Subcategory = "System Log"
            RegistryKey = "MACHINE\System\CurrentControlSet\Services\Eventlog\System"
            ValueName = "MaxSize"
            Type = "DWord"
            Value = 524288000  # 500 MB in bytes
        },
        @{
            Name = "Application Log Maximum Size"
            Subcategory = "Application Log"
            RegistryKey = "MACHINE\System\CurrentControlSet\Services\Eventlog\Application"
            ValueName = "MaxSize"
            Type = "DWord"
            Value = 524288000  # 500 MB in bytes
        }
    )
    # Check if the GPO exists, create it if it doesn't
    try {
        GroupPolicy\Get-GPO -Name $GpoName -Domain $Domain -ErrorAction Stop
        Write-Host "GPO '$GpoName' found in domain '$Domain'."
    }
    catch {
        Write-Host "GPO '$GpoName' does not exist. Creating new GPO..."
        try {
            New-GPO -Name $GpoName -Domain $Domain -ErrorAction Stop
            Write-Host "Successfully created GPO '$GpoName'."
        }
        catch {
            Write-Error "Failed to create GPO '$GpoName': $_"
            return
        }
    }
    # Function to configure a single setting
    function Set-SingleGpoSetting {
        param (
            [string]$GpoName,
            [string]$Domain,
            [string]$RegistryKey,
            [string]$ValueName,
            [string]$Subcategory,
            [string]$Type,
            [int]$Value
        )
        try {
            Set-GPRegistryValue -Name $GpoName -Domain $Domain -Key $RegistryKey -ValueName $ValueName -Type $Type -Value $Value -ErrorAction Stop
            Write-Host "Successfully configured $Subcategory in GPO: $GpoName"
        }
        catch {
            Write-Host "Error configuring $Subcategory in GPO: $_" -ForegroundColor Red
        }
    }
    # Apply each setting
    Write-Host "Configuring settings in GPO: $GpoName"
    foreach ($Setting in $AuditSettings) {
        Set-SingleGpoSetting -GpoName $GpoName -Domain $Domain -RegistryKey $Setting.RegistryKey -ValueName $Setting.ValueName -Subcategory $Setting.Subcategory -Type $Setting.Type -Value $Setting.Value
    }
    # Verify the GPO settings
    Write-Host "Verifying GPO settings..."
    foreach ($Setting in $AuditSettings) {
        try {
            $Result = Get-GPRegistryValue -Name $GpoName -Domain $Domain -Key $Setting.RegistryKey -ValueName $Setting.ValueName -ErrorAction Stop
            Write-Host "GPO: $GpoName, $($Setting.Subcategory) = $($Result.Value)"
        }
        catch {
            Write-Host "Error verifying $($Setting.Subcategory): $_" -ForegroundColor Red
        }
    }
    Write-Host "GPO configuration completed. Link the GPO to an OU and apply using 'gpupdate /force' on target machines."
}