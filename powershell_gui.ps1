# https://lazyadmin.nl/powershell/powershell-gui-howto-get-started/

#---------------------------------------------------------[Initialize]--------------------------------------------------------

# Minimize PowerShell Console
if ($host.name -notmatch "ConsoleHost") {
    Add-Type -Name Window -Namespace Console -MemberDefinition '
        [DllImport("Kernel32.dll")]
        public static extern IntPtr GetConsoleWindow();
        [DllImport("user32.dll")]
        public static extern bool ShowWindow(IntPtr hWnd, Int32 nCmdShow);
    ' 
    $consolePtr = [Console.Window]::GetConsoleWindow()
    [Console.Window]::ShowWindow($consolePtr, 7) | Out-Null # Hide = 0
}


# Init PowerShell GUI
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()

#---------------------------------------------------------[Form]--------------------------------------------------------

$iconPath = "{0}\icon.ico" -f $PSScriptRoot
$url = "https://github.com/favicon.ico"
Invoke-WebRequest -Uri $url -OutFile $iconPath
$Icon					= New-Object system.drawing.icon ($iconPath)

$LocalForm				= New-Object system.Windows.Forms.Form -Property @{
    text				= "Window Title"
    BackColor			= "#ffffff"
    ClientSize			= "720, 400"
    MinimumSize			= '300, 300'
    TopMost				= $false
    Icon				= $Icon
}

$Title					= New-Object system.Windows.Forms.Label -Property @{
    text				= "The Title text"
    Font				= "Microsoft Sans Serif, 13"
    width				= $LocalForm.ClientSize.Width - 24
    height				= 24
    AutoSize			= $false
    location			= New-Object System.Drawing.Point(24,24)
}

$Description			= New-Object system.Windows.Forms.Label -Property @{
    text				= "The description text"
    Font				= "Microsoft Sans Serif, 10"
    width				= $LocalForm.ClientSize.Width - 24
    height				= 100
    AutoSize			= $false
    location			= New-Object System.Drawing.Point(24, ($Title.Bottom + 24))
    Anchor				= [System.Windows.Forms.AnchorStyles]::Top `
                            -bor [System.Windows.Forms.AnchorStyles]::Left
}

$SelectFolderBtn		= New-Object system.Windows.Forms.Button -Property @{
    text				= "Select Folder text"
    Font				= "Microsoft Sans Serif, 10"
    ForeColor			= "#000"
    BackColor			= "#ffffff"
    width				= 120
    height				= 30
    location			= New-Object System.Drawing.Point(24, ($Description.Bottom + 24))
    Visible				= $true
}

$SelectFileBtn			= New-Object system.Windows.Forms.Button -Property @{
    text				= "Select File text"
    Font				= "Microsoft Sans Serif, 10"
    ForeColor			= "#000"
    BackColor			= "#ffffff"
    width				= 120
    height				= 30
    location			= New-Object System.Drawing.Point(($SelectFolderBtn.Right + 24), ($Description.Bottom + 24))
    Visible				= $true
}

$Status					= New-Object system.Windows.Forms.Label -Property @{
    text				= "The status text"
    Font				= "Microsoft Sans Serif, 10"
    width				= $LocalForm.ClientSize.Width - 24
    height				= 30
    AutoSize			= $false
    location			= New-Object System.Drawing.Point(24, ($SelectFolderBtn.Bottom + 24))
    
}

$ExecuteBtn				= New-Object system.Windows.Forms.Button -Property @{
    text				= "Start"
    Font				= "Microsoft Sans Serif, 10"
    ForeColor			= "#000"
    BackColor			= "#ffffff"
    width				= 90
    height				= 30
    location			= New-Object System.Drawing.Point(260, ($Status.Bottom + 24))
    Anchor 				= [System.Windows.Forms.AnchorStyles]::Bottom`
                            -bor [System.Windows.Forms.AnchorStyles]::Right
    Visible				= $true
}

$cancelBtn				= New-Object system.Windows.Forms.Button -Property @{
    text				= "Cancel"
    Font				= "Microsoft Sans Serif, 10"
    ForeColor			= "#000"
    BackColor			= "#ffffff"
    width				= 90
    height				= 30
    location			= New-Object System.Drawing.Point(($ExecuteBtn.Right + 24), ($Status.Bottom + 24))
    Anchor 				= [System.Windows.Forms.AnchorStyles]::Bottom`
                            -bor [System.Windows.Forms.AnchorStyles]::Right
    DialogResult		= [System.Windows.Forms.DialogResult]::Cancel
}

$LocalForm.CancelButton	= $cancelBtn

$LocalForm.controls.AddRange( @($Title, $Description, $SelectFolderBtn, $SelectFileBtn, $Status, $ExecuteBtn, $cancelBtn) )

#-----------------------------------------------------------[Functions]------------------------------------------------------------

function SelectFileBtn_Click {
    $FileDialog = New-Object System.Windows.Forms.OpenFileDialog
    $null = $FileDialog.ShowDialog()
    $FileName = $FileDialog.FileName
    Write-Host "$FileName"
}

function SelectFolderBtn_Click {
    $FolderDialog = New-Object System.Windows.Forms.FolderBrowserDialog
    $null = $FolderDialog.ShowDialog()
    $path = $FolderDialog.SelectedPath
    Write-Host "$path"
}

function ExecuteBtn_Click { 
    write-host "Executed"
}

#---------------------------------------------------------[Script]--------------------------------------------------------

$SelectFolderBtn.Add_Click({ SelectFolderBtn_Click })
$SelectFileBtn.Add_Click({ SelectFileBtn_Click })
$ExecuteBtn.Add_Click({ ExecuteBtn_Click })

# Get Last Used Settings & Locale
if (Test-Path "$PSScriptRoot\settings.ini"){
    Get-Content "$PSScriptRoot\settings.ini" | foreach-object -begin {$h=@{}} -process { $k = [regex]::split($_,'='); if(($k[0].CompareTo("") -ne 0) -and ($k[0].StartsWith("[") -ne $True)) { $h.Add($k[0], $k[1]) } }
    $LocalForm.text = $h."LocalForm.text"
    $Title.text = $h."Title.text"
    $Description.text = $h."Description.text"
}

[void]$LocalForm.ShowDialog()
[void]$LocalForm.Activate()
