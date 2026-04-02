<#
    .TODO
    Separate user from admin

    .References
    - https://www.elevenforum.com/t/disable-show-more-options-context-menu-in-windows-11.1589/
#>


# --- SETUP ---

function Set-RegProperty($FullPath, $PropertyType, $Value){
    $Path = Split-Path -Path $FullPath
    $Name = Split-Path -Path $FullPath -Leaf

    if (!(Test-Path $Path)) {
        
        New-Item -ItemType Directory -Path $Path -Force -ErrorAction SilentlyContinue | Out-Null
    }

    New-ItemProperty -Path $Path -Name $Name -Value $Value -PropertyType $PropertyType -Force -ErrorAction SilentlyContinue | Out-Null
    
}


# Disable "Show more options" context menu in Windows 11
Set-RegProperty "HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32" "DWORD" 1
reg add "HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32" /f /ve​


# Install RSAT: Active Directory Tools
Get-WindowsCapability -Online -Name "Rsat.ActiveDirectory.DS-LDS.Tools*" | Add-WindowsCapability -Online


# Install GPO Tools:
Get-WindowsCapability -Online -Name "Rsat.GroupPolicy.Management.Tools*" | Add-WindowsCapability -Online


# Install DNS Server Tools:
Get-WindowsCapability -Online -Name "Rsat.Dns.Tools*" | Add-WindowsCapability -Online


# Set Maximum Performance, Minimum Power Savings
powercfg /duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61 # Unlock Ultimate Performance plan
$ultimatePlan = powercfg /list | Select-String "Ultimate Performance" # Set it as active (the GUID may vary, so we'll grab it dynamically)
$guid = $ultimatePlan.ToString().Split()[3]
powercfg /setactive $guid
powercfg /x -standby-timeout-ac 0 # Disable Monitor Timeout
powercfg /x -standby-timeout-dc 0 # Disable Monitor Timeout
powercfg /h off # Turn Off Hibernation
powercfg /setacvalueindex SCHEME_CURRENT SUB_PROCESSOR PROCTHROTTLEMIN 100 # Set Minimum Processor State to 100% (Plugged In)
powercfg /setacvalueindex SCHEME_CURRENT SUB_PROCESSOR PROCTHROTTLEMAX 100 # Set Maximum Processor State to 100% (Plugged In)
powercfg /setactive SCHEME_CURRENT # Apply the changes
powercfg /list # Show plans
powercfg /query SCHEME_CURRENT # Show settings