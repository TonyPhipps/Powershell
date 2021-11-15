Set-ExecutionPolicy Bypass -Scope Process -Force; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))

choco install firefox -y
choco install chromium -y
choco install keepass -y
choco install steam -y
choco install vscode -y
choco install notepadplusplus -y
choco install git -y
choco install spideroakone -y
choco install vlc -y
choco install irfanview -y
choco install irfanviewplugins -y
choco install greenshot -y
choco install 7zip -y
choco install libreoffice -y
choco install citrix-receiver -y
choco install javaruntime -y
choco install veracrypt -y


# Media
choco install audacity -y
choco install gimp -y
choco install inkscape -y

# Security
choco install nmap -y
choco install wireshark -y

# Admin tools
choco install sysinternals -y
choco install speedfan -y
choco install wincdemu -y
choco install cpu-z -y
choco install speccy -y
choco install nirlauncher -y

# Speciality
choco install docker -y
choco install putty -y
choco install ffmpeg -y
choco install shotcut -y
choco install blender -y



# Setup Chocolatey update scheduled task
    # See if choco.exe is available. If not, stop execution
    $chocoCmd = Get-Command -Name 'choco' -ErrorAction SilentlyContinue -WarningAction SilentlyContinue | Select-Object -ExpandProperty Source
    if ($chocoCmd -eq $null) { break }

    # Settings for the scheduled task
    $taskAction = New-ScheduledTaskAction –Execute $chocoCmd -Argument 'upgrade all -y'
    $taskTrigger = New-ScheduledTaskTrigger -AtStartup
    $taskUserPrincipal = New-ScheduledTaskPrincipal -UserId 'SYSTEM'
    $taskSettings = New-ScheduledTaskSettingsSet -Compatibility Win8

    # Set up the task, and register it
    $task = New-ScheduledTask -Action $taskAction -Principal $taskUserPrincipal -Trigger $taskTrigger -Settings $taskSettings
    Register-ScheduledTask -TaskName 'Run a Choco Upgrade All at Startup' -InputObject $task -Force

