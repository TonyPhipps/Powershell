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

