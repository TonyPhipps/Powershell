choco install libreoffice -y

# choco install firefox -y
choco install filezilla -y
choco install citrix-receiver -y
choco install putty -y


choco install keepass -y
choco install malwarebytes -y
choco install sysinternals -y
choco install nmap -y
choco install cpu-z -y
choco install speccy -y
choco install nirlauncher -y
choco install speedfan -y
choco install wincdemu -y
choco install 7zip -y
choco install wireshark -y

choco install notepadplusplus -y
choco install javaruntime -y
choco install git -y
choco install visualstudiocode -y

choco install spideroakone -y

choco install steam -y

choco install inkscape -y
choco install audacity -y
choco install vlc -y
choco install irfanview -y
choco install irfanviewplugins -y
choco install gimp -y
choco install greenshot -y
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

