<#
.SYNOPSIS
    Generates a clean, hardware-only system inventory text report.
.DESCRIPTION
    Queries local CIM objects to gather physical hardware specifications
    (System, Motherboard, CPU, RAM sticks, GPUs, Disks, Network, Audio)
    excluding drivers, software, background services, and diagnostic logs.
.PARAMETER OutputPath
    Destination file path for the text report. Defaults to 'Hardware_Inventory_<ComputerName>.txt'.
.EXAMPLE
    .\Get-HardwareInventory.ps1
.EXAMPLE
    .\Get-HardwareInventory.ps1 -OutputPath "C:\Reports\MyPC_Specs.txt"
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$OutputPath = ".\Hardware_Inventory_$($env:COMPUTERNAME).txt"
)

$inventory = [System.Collections.Generic.List[PSCustomObject]]::new()

function Add-HardwareItem {
    param(
        [string]$Category,
        [string]$Name,
        [string]$Manufacturer,
        [string]$Details,
        [string]$Identifier
    )
    $inventory.Add([PSCustomObject]@{
        Category     = $Category
        Name         = $Name
        Manufacturer = $Manufacturer
        Details      = $Details
        Identifier   = $Identifier
    })
}

# --- System Summary ---
$cs   = Get-CimInstance -ClassName Win32_ComputerSystem
$bios = Get-CimInstance -ClassName Win32_BIOS
Add-HardwareItem -Category "System Summary" -Name $cs.Model -Manufacturer $cs.Manufacturer -Details "Type: $($cs.SystemType) | BIOS: $($bios.SMBIOSBIOSVersion) ($($bios.ReleaseDate.ToString('yyyy-MM-dd')))" -Identifier "Serial: $($bios.SerialNumber) | Host: $env:COMPUTERNAME"

# --- Motherboard ---
$mobo = Get-CimInstance -ClassName Win32_BaseBoard
Add-HardwareItem -Category "Motherboard" -Name $mobo.Product -Manufacturer $mobo.Manufacturer -Details "Version: $($mobo.Version)" -Identifier $mobo.SerialNumber

# --- Processor (CPU) ---
$cpus = Get-CimInstance -ClassName Win32_Processor
foreach ($cpu in $cpus) {
    Add-HardwareItem -Category "Processor (CPU)" -Name $cpu.Name.Trim() -Manufacturer $cpu.Manufacturer -Details "$($cpu.NumberOfCores) Cores / $($cpu.NumberOfLogicalProcessors) Threads @ $($cpu.MaxClockSpeed) MHz" -Identifier $cpu.SocketDesignation
}

# --- Memory (RAM) ---
$ramModules = Get-CimInstance -ClassName Win32_PhysicalMemory
$stickNum = 1
foreach ($ram in $ramModules) {
    $capGB = [math]::Round($ram.Capacity / 1GB, 2)
    $speed = if ($ram.ConfiguredClockSpeed) { $ram.ConfiguredClockSpeed } else { $ram.Speed }
    $mfg   = if ($ram.Manufacturer) { $ram.Manufacturer.Trim() } else { "Unknown" }
    $part  = if ($ram.PartNumber) { $ram.PartNumber.Trim() } else { "N/A" }
    Add-HardwareItem -Category "Memory (RAM)" -Name "Slot $stickNum ($($ram.DeviceLocator))" -Manufacturer $mfg -Details "$capGB GB @ $speed MHz (Part: $part)" -Identifier $ram.SerialNumber
    $stickNum++
}

# --- Graphics (GPU) ---
$gpus = Get-CimInstance -ClassName Win32_VideoController
foreach ($gpu in $gpus) {
    $vramGB = if ($gpu.AdapterRAM) { [math]::Round($gpu.AdapterRAM / 1GB, 2) } else { "N/A" }
    $mfg    = if ($gpu.AdapterCompatibility) { $gpu.AdapterCompatibility } else { $gpu.Caption }
    Add-HardwareItem -Category "Graphics (GPU)" -Name $gpu.Name -Manufacturer $mfg -Details "VRAM: $vramGB GB | Res: $($gpu.CurrentHorizontalResolution)x$($gpu.CurrentVerticalResolution)@$($gpu.CurrentRefreshRate)Hz | Driver: $($gpu.DriverVersion)" -Identifier $gpu.PNPDeviceID
}

# --- Storage Drives & Volumes ---
$disks = Get-CimInstance -ClassName Win32_DiskDrive
foreach ($disk in $disks) {
    $sizeGB = [math]::Round($disk.Size / 1GB, 2)
    $partitions = Get-CimAssociatedInstance -InputObject $disk -ResultClassName Win32_DiskPartition -ErrorAction SilentlyContinue
    $volumes = foreach ($part in $partitions) {
        Get-CimAssociatedInstance -InputObject $part -ResultClassName Win32_LogicalDisk -ErrorAction SilentlyContinue
    }
    $driveList = if ($volumes) { ($volumes | ForEach-Object { "$($_.DeviceID) ($([math]::Round($_.Size / 1GB, 1)) GB)" }) -join ", " } else { "None" }
    $serial    = if ($disk.SerialNumber) { $disk.SerialNumber.Trim() } else { "N/A" }
    Add-HardwareItem -Category "Storage Drives & Volumes" -Name $disk.Model -Manufacturer $disk.Manufacturer -Details "Capacity: $sizeGB GB | Interface: $($disk.InterfaceType) | Media: $($disk.MediaType) | Volumes: $driveList" -Identifier $serial
}

# --- Audio Devices & Sound Cards ---
$audioDevs = Get-CimInstance -ClassName Win32_SoundDevice
foreach ($audio in $audioDevs) {
    Add-HardwareItem -Category "Audio Devices & Sound Cards" -Name $audio.Name -Manufacturer $audio.Manufacturer -Details "Status: $($audio.Status)" -Identifier $audio.DeviceID
}

# --- Connected Bluetooth Devices ---
$btDevices = Get-CimInstance -ClassName Win32_PnPEntity | Where-Object {
    ($_.PNPClass -eq 'Bluetooth' -or $_.DeviceID -like 'BTHENUM*') -and
    $_.Name -and
    $_.Name -notmatch 'Bluetooth Device|Enumerator|Adapter|Radio|Protocol|Generic|Standard|Transport|Service|Access'
}
if ($btDevices) {
    foreach ($bt in $btDevices) {
        Add-HardwareItem -Category "Connected Bluetooth Devices" -Name $bt.Name -Manufacturer $bt.Manufacturer -Details "Status: $($bt.Status)" -Identifier $bt.DeviceID
    }
}

# --- Gaming Controllers ---
$controllers = Get-CimInstance -ClassName Win32_PnPEntity | Where-Object {
    $_.Name -and (
        $_.Name -match 'Controller|Gamepad|Joystick|Xbox|PlayStation|DualSense|XINPUT' -or
        $_.PNPClass -eq 'XINPUT'
    ) -and
    $_.Name -notmatch 'Virtual|Software|Root|eXtensible|Adapter|Standard|HID-compliant|Programmable|Loopback|Family'
}
if ($controllers) {
    foreach ($ctl in $controllers) {
        Add-HardwareItem -Category "Gaming Controllers" -Name $ctl.Name -Manufacturer $ctl.Manufacturer -Details "Status: $($ctl.Status)" -Identifier $ctl.DeviceID
    }
}

# --- USB & External Peripherals ---
$usbDevices = Get-CimInstance -ClassName Win32_PnPEntity | Where-Object {
    $_.DeviceID -like 'USB*' -and
    $_.Name -and
    $_.Name -notmatch 'Host Controller|Root Hub|Generic USB Hub|Composite Device|PCI to USB|USB Input Device|Generic|Adapter'
}
if ($usbDevices) {
    foreach ($usb in $usbDevices) {
        Add-HardwareItem -Category "Connected USB & External Peripherals" -Name $usb.Name -Manufacturer $usb.Manufacturer -Details "Status: $($usb.Status)" -Identifier $usb.DeviceID
    }
}

# --- Physical Network Adapters ---
$nics = Get-CimInstance -ClassName Win32_NetworkAdapter | Where-Object { $_.PhysicalAdapter -and $_.MACAddress }
foreach ($nic in $nics) {
    $speedStr = if ($nic.Speed) { [math]::Round($nic.Speed / 1MB, 0).ToString() + ' Mbps' } else { 'Disconnected' }
    Add-HardwareItem -Category "Physical Network Adapters" -Name $nic.Name -Manufacturer $nic.Manufacturer -Details "Connection Speed: $speedStr" -Identifier "MAC: $($nic.MACAddress)"
}

# Handle OutputPath if parameter is explicitly passed
if ($PSBoundParameters.ContainsKey('OutputPath')) {
    $inventory | Export-Csv -Path $OutputPath -NoTypeInformation -Encoding utf8
    Write-Host "Hardware inventory exported to: $OutputPath" -ForegroundColor Green
}

# Output objects directly to pipeline
return $inventory