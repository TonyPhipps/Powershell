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

# Define preset audit settings and event log sizes
$AuditSettings = @(
    # PowerShell
    @{
        #GPO        = Computer Configuration > Policies > Administrative Templates > Windows Components > Windows PowerShell > Turn on Module Logging
        Name        = "Enable Module Logging"
        Subcategory = "ModuleLogging"
        RegistryKey = "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\PowerShell\ModuleLogging"
        ValueName   = "EnableModuleLogging"
        Type        = "DWord"
        Value       = 1 # Enabled
    },
    @{
        #GPO        = Computer Configuration > Policies > Administrative Templates > Windows Components > Windows PowerShell > Turn on Module Logging
        Name        = "Enable Module Logging for All Modules"
        Subcategory = "ModuleLogging"
        RegistryKey = "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\PowerShell\ModuleLogging\ModuleNames"
        ValueName   = "*"
        Type        = "String"
        Value       = "*" # Log all modules
    },
    # Enable Advanced Audit Policy
    @{
        Name        = "Enable Advanced Audit Policy"
        Subcategory = "Advanced Audit Policy"
        RegistryKey = "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Lsa"
        ValueName   = "SCENoApplyLegacyAuditPolicy"
        Type        = "DWord"
        Value       = 1 # Enable advanced audit policies
    },
    # Event Log Sizes
    @{
        Name        = "Security Log Maximum Size"
        Subcategory = "Security Log"
        RegistryKey = "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Services\Eventlog\Security"
        ValueName   = "MaxSize"
        Type        = "DWord"
        Value       = 524288000  # 500 MB in bytes
    },
    @{
        Name        = "System Log Maximum Size"
        Subcategory = "System Log"
        RegistryKey = "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Services\Eventlog\System"
        ValueName   = "MaxSize"
        Type        = "DWord"
        Value       = 524288000  # 500 MB in bytes
    },
    @{
        Name        = "Application Log Maximum Size"
        Subcategory = "Application Log"
        RegistryKey = "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Services\Eventlog\Application"
        ValueName   = "MaxSize"
        Type        = "DWord"
        Value       = 524288000  # 500 MB in bytes
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

# Apply registry-based settings with Set-GPRegistryValue
Write-Host "Configuring registry settings in GPO: $GpoName"
foreach ($Setting in $AuditSettings) {
    try {
        Set-GPRegistryValue -Name $GpoName `
                            -Domain $Domain `
                            -Key $Setting.RegistryKey `
                            -ValueName $Setting.ValueName `
                            -Type $Setting.Type `
                            -Value $Setting.Value `
                            -ErrorAction Stop
        Write-Host "Successfully configured $($Setting.Subcategory) in GPO: $GpoName"
    }
    catch {
        Write-Host "Error configuring $($Setting.Subcategory) in GPO: $_" -ForegroundColor Red
    }
}

# Configure Audit Process Creation using audit.csv
Write-Host "Configuring Audit Process Creation in GPO: $GpoName"
try {
    # Create a temporary audit policy file
    $tempCsv = [System.IO.Path]::GetTempFileName() + ".csv"
    $auditPolicy = @"
Machine Name,Policy Target,Subcategory,Subcategory GUID,Inclusion Setting,Exclusion Setting,Setting Value
,System,Process Creation,{0cce922b-69ae-11d9-bed3-505054503030},,Success and Failure,3
"@
    Set-Content -Path $tempCsv -Value $auditPolicy -ErrorAction Stop

    # Import the audit policy into the GPO
    $gpoPath = "\\$Domain\SysVol\$Domain\Policies\{$(Get-GPO -Name $GpoName -Domain $Domain).Id}\Machine\Microsoft\Windows NT\Audit"
    if (-not (Test-Path $gpoPath)) {
        New-Item -Path $gpoPath -ItemType Directory -Force | Out-Null
    }
    Copy-Item -Path $tempCsv -Destination "$gpoPath\audit.csv" -Force -ErrorAction Stop
    Write-Host "Successfully configured Audit Process Creation in GPO: $GpoName"
}
catch {
    Write-Host "Error configuring Audit Process Creation: $_" -ForegroundColor Red
}
finally {
    if (Test-Path $tempCsv) {
        Remove-Item -Path $tempCsv -Force
    }
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

# Verify Audit Process Creation
try {
    $gpo = Get-GPO -Name $GpoName -Domain $Domain
    $auditCsvPath = "\\$Domain\SysVol\$Domain\Policies\{$($gpo.Id)}\Machine\Microsoft\Windows NT\Audit\audit.csv"
    if (Test-Path $auditCsvPath) {
        $auditSettings = Import-Csv -Path $auditCsvPath
        $processCreation = $auditSettings | Where-Object { $_.Subcategory -eq "Process Creation" }
        if ($processCreation -and $processCreation.'Setting Value' -eq "3") {
            Write-Host "GPO: $GpoName, Audit Process Creation = Success and Failure"
        }
        else {
            Write-Host "Audit Process Creation not set correctly in GPO: $GpoName" -ForegroundColor Red
        }
    }
    else {
        Write-Host "Audit policy file not found in GPO: $GpoName" -ForegroundColor Red
    }
}
catch {
    Write-Host "Error verifying Audit Process Creation: $_" -ForegroundColor Red
}

Write-Host "GPO configuration completed. Link the GPO to an OU and apply using 'gpupdate /force' on target machines."