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

$output = [System.Collections.Generic.List[string]]::new()

function Add-Section ([string]$title) {
    $output.Add("")
    $output.Add("================================================================================")
    $output.Add("  $title")
    $output.Add("================================================================================")
}

function Add-Line ([string]$label, [string]$value) {
    $output.Add(("{0,-28} : {1}" -f $label, $value))
}

# --- System Summary ---
Add-Section "SYSTEM SUMMARY"
$cs   = Get-CimInstance -ClassName Win32_ComputerSystem
$bios = Get-CimInstance -ClassName Win32_BIOS

Add-Line "Computer Name" $env:COMPUTERNAME
Add-Line "System Manufacturer" $cs.Manufacturer
Add-Line "System Model" $cs.Model
Add-Line "System Type" $cs.SystemType
Add-Line "BIOS Version / Date" "$($bios.SMBIOSBIOSVersion) ($($bios.ReleaseDate.ToString('yyyy-MM-dd')))"
Add-Line "System Serial Number" $bios.SerialNumber

# --- Motherboard ---
Add-Section "MOTHERBOARD"
$mobo = Get-CimInstance -ClassName Win32_BaseBoard
Add-Line "Manufacturer" $mobo.Manufacturer
Add-Line "Product" $mobo.Product
Add-Line "Version / Serial" "$($mobo.Version) / $($mobo.SerialNumber)"

# --- Processor ---
Add-Section "PROCESSOR (CPU)"
$cpus = Get-CimInstance -ClassName Win32_Processor
foreach ($cpu in $cpus) {
    Add-Line "Name" $cpu.Name.Trim()
    Add-Line "Cores / Threads" "$($cpu.NumberOfCores) Cores / $($cpu.NumberOfLogicalProcessors) Threads"
    Add-Line "Max Clock Speed" "$($cpu.MaxClockSpeed) MHz"
    Add-Line "Socket" $cpu.SocketDesignation
}

# --- Memory ---
Add-Section "MEMORY (RAM)"
$ramModules = Get-CimInstance -ClassName Win32_PhysicalMemory
$totalRAM = [math]::Round(($ramModules | Measure-Object -Property Capacity -Sum).Sum / 1GB, 2)
Add-Line "Total Installed RAM" "$totalRAM GB"
Add-Line "Populated Slots" "$($ramModules.Count)"

$stickNum = 1
foreach ($ram in $ramModules) {
    $capGB = [math]::Round($ram.Capacity / 1GB, 2)
    $speed = if ($ram.ConfiguredClockSpeed) { $ram.ConfiguredClockSpeed } else { $ram.Speed }
    Add-Line "  [Slot $stickNum]" "$($ram.Manufacturer.Trim()) $($ram.PartNumber.Trim()) - $capGB GB @ $speed MHz ($($ram.DeviceLocator))"
    $stickNum++
}

# --- Graphics ---
Add-Section "GRAPHICS (GPU)"
$gpus = Get-CimInstance -ClassName Win32_VideoController
foreach ($gpu in $gpus) {
    $vramGB = if ($gpu.AdapterRAM) { [math]::Round($gpu.AdapterRAM / 1GB, 2) } else { "N/A" }
    Add-Line "GPU Name" $gpu.Name
    Add-Line "Dedicated VRAM" "$vramGB GB"
    Add-Line "Current Mode" "$($gpu.CurrentHorizontalResolution)x$($gpu.CurrentVerticalResolution) @ $($gpu.CurrentRefreshRate) Hz"
    Add-Line "Driver Version" $gpu.DriverVersion
    $output.Add("")
}

# --- Storage Drives ---
Add-Section "STORAGE DRIVES & VOLUMES"
$disks = Get-CimInstance -ClassName Win32_DiskDrive
foreach ($disk in $disks) {
    $sizeGB = [math]::Round($disk.Size / 1GB, 2)
    Add-Line "Model" $disk.Model
    Add-Line "Capacity" "$sizeGB GB"
    Add-Line "Interface Type" $disk.InterfaceType
    Add-Line "Media Type" $disk.MediaType
    Add-Line "Partitions" $disk.Partitions
    Add-Line "Serial Number" $disk.SerialNumber.Trim()

    # Map drive letters / volumes to the physical disk
    $partitions = Get-CimAssociatedInstance -InputObject $disk -ResultClassName Win32_DiskPartition -ErrorAction SilentlyContinue
    $volumes = foreach ($part in $partitions) {
        Get-CimAssociatedInstance -InputObject $part -ResultClassName Win32_LogicalDisk -ErrorAction SilentlyContinue
    }
    if ($volumes) {
        $driveList = ($volumes | ForEach-Object { "$($_.DeviceID) ($([math]::Round($_.Size / 1GB, 1)) GB)" }) -join ", "
        Add-Line "Volume(s)" $driveList
    }
    $output.Add("")
}

# --- Audio Devices & Sound Cards ---
Add-Section "AUDIO DEVICES & SOUND CARDS"
$audioDevs = Get-CimInstance -ClassName Win32_SoundDevice
foreach ($audio in $audioDevs) {
    Add-Line "Device Name" $audio.Name
    Add-Line "Manufacturer" $audio.Manufacturer
    Add-Line "Status" $audio.Status
    $output.Add("")
}

# --- Connected Bluetooth Devices ---
Add-Section "CONNECTED BLUETOOTH DEVICES"
$btDevices = Get-CimInstance -ClassName Win32_PnPEntity | Where-Object {
    ($_.PNPClass -eq 'Bluetooth' -or $_.DeviceID -like 'BTHENUM*') -and
    $_.Name -and
    $_.Name -notmatch 'Bluetooth Device|Enumerator|Adapter|Radio|Protocol'
}
if ($btDevices) {
    foreach ($bt in $btDevices) {
        Add-Line "Device Name" $bt.Name
        Add-Line "Manufacturer" $bt.Manufacturer
        Add-Line "Status" $bt.Status
        $output.Add("")
    }
} else {
    Add-Line "Bluetooth" "No active Bluetooth peripheral devices detected."
}

# --- Gaming Controllers ---
Add-Section "GAMING CONTROLLERS"
$controllers = Get-CimInstance -ClassName Win32_PnPEntity | Where-Object {
    $_.Name -and (
        $_.Name -match 'Controller|Gamepad|Joystick|Xbox|PlayStation|DualSense|XINPUT' -or
        $_.PNPClass -eq 'XINPUT'
    ) -and
    $_.Name -notmatch 'Virtual|Software|Root'
}
if ($controllers) {
    foreach ($ctl in $controllers) {
        Add-Line "Controller Name" $ctl.Name
        Add-Line "Manufacturer" $ctl.Manufacturer
        Add-Line "Status" $ctl.Status
        $output.Add("")
    }
} else {
    Add-Line "Gaming Controllers" "No connected game controllers detected."
}

# --- USB & External Peripherals ---
Add-Section "CONNECTED USB & EXTERNAL PERIPHERALS"
$usbDevices = Get-CimInstance -ClassName Win32_PnPEntity | Where-Object {
    $_.DeviceID -like 'USB*' -and
    $_.Name -and
    $_.Name -notmatch 'Host Controller|Root Hub|Generic USB Hub|Composite Device|PCI to USB|USB Input Device'
}
if ($usbDevices) {
    foreach ($usb in $usbDevices) {
        Add-Line "Device Name" $usb.Name
        Add-Line "Manufacturer" $usb.Manufacturer
        Add-Line "Status" $usb.Status
        $output.Add("")
    }
} else {
    Add-Line "USB Peripherals" "No connected external USB peripherals detected."
}

# --- Network Adapters ---
Add-Section "PHYSICAL NETWORK ADAPTERS"
$nics = Get-CimInstance -ClassName Win32_NetworkAdapter | Where-Object { $_.PhysicalAdapter -and $_.MACAddress }
foreach ($nic in $nics) {
    Add-Line "Adapter Name" $nic.Name
    Add-Line "MAC Address" $nic.MACAddress
    Add-Line "Connection Speed" "$(if ($nic.Speed) { [math]::Round($nic.Speed / 1MB, 0).ToString() + ' Mbps' } else { 'Disconnected' })"
    $output.Add("")
}

# Export report
$output | Out-File -FilePath $OutputPath -Encoding utf8
Write-Host "Hardware inventory successfully generated at: $OutputPath" -ForegroundColor Green