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

$global:Folder          = $PSScriptRoot
$global:File            = $PSScriptRoot.$FileName

#---------------------------------------------------------[Form]--------------------------------------------------------

$iconPath               = "{0}\icon.ico" -f $PSScriptRoot
$url                    = "https://github.com/favicon.ico"
Invoke-WebRequest -Uri $url -OutFile $iconPath
$Icon					= New-Object system.drawing.icon ($iconPath)

$LocalForm				= New-Object system.Windows.Forms.Form -Property @{
    text				= "Window Title"
    BackColor			= "#ffffff"
    ClientSize			= "720, 600"
    MinimumSize			= '300, 300'
    Icon				= $Icon
}

$TitleLbl				= New-Object system.Windows.Forms.Label -Property @{
    Text				= "The Title text"
    Font				= "Microsoft Sans Serif, 13"
    Width				= $LocalForm.ClientSize.Width - 24
    Height				= 24
    Location			= New-Object System.Drawing.Point(16, 24)
}

$DescriptionLbl			= New-Object system.Windows.Forms.Label -Property @{
    Text				= "The description text"
    Font				= "Microsoft Sans Serif, 10"
    Width				= $LocalForm.ClientSize.Width - 24
    Height				= 100
    Location			= New-Object System.Drawing.Point(16, ($Title.Bottom + 24))
    Anchor				= [System.Windows.Forms.AnchorStyles]::Top `
                            -bor [System.Windows.Forms.AnchorStyles]::Left
}

$Checkbox               = New-Object System.Windows.Forms.Checkbox  -Property @{
    Text                = "Checkbox text"
    Width               = 500
    Height              = 20
    Location            = New-Object System.Drawing.Size(16, ($Description.Bottom + 8))
}

$SelectedFolderLbl      = New-Object System.Windows.Forms.Label -Property @{
    Text				= "Folder: "
    Font				= "Microsoft Sans Serif, 10"
    Width				= $SelectedFolderLbl.Text.Length * 8
    Height				= $SelectedFolderLbl.Font.Size * 2
    Location			= New-Object System.Drawing.Point(16, ($Checkbox.Bottom + 8))
}

$SelectedFolderTxt      = New-Object System.Windows.Forms.TextBox -Property @{
    Text                = "{0}" -f $Folder
    Width               = 256
    Height              = 70
    Location            = New-Object System.Drawing.Point(($SelectedFolderLbl.Right + 8), ($SelectedFolderLbl.Top))
    #Enabled             = $false
}

$SelectFolderBtn		= New-Object system.Windows.Forms.Button -Property @{
    Text				= "Change"
    Font				= "Microsoft Sans Serif, 10"
    ForeColor			= "#000"
    BackColor			= "#ffffff"
    Width				= 120
    Height				= 24
    Location			= New-Object System.Drawing.Point(($SelectedFolderTxt.Right + 8), ($SelectedFolderTxt.Top - 2))
    Visible				= $true
}

$SelectedFileLbl        = New-Object System.Windows.Forms.Label -Property @{
    Text				= "File: "
    Font				= "Microsoft Sans Serif, 10"
    Width				= $SelectedFolder.Text.Length * 8
    Height				= $SelectedFile.Font.Size * 2
    Location			= New-Object System.Drawing.Point(16, ($SelectedFolderLbl.Bottom + 8))
}

$SelectedFileTxt        = New-Object System.Windows.Forms.TextBox -Property @{
    Text                = "{0}" -f $File
    Width               = 256
    Height              = 70
    Location            = New-Object System.Drawing.Point(($SelectedFileLbl.Right + 8), ($SelectedFileLbl.Top))
    #Enabled             = $false
}

$SelectFileBtn			= New-Object system.Windows.Forms.Button -Property @{
    Text				= "Select File"
    Font				= "Microsoft Sans Serif, 10"
    ForeColor			= "#000"
    BackColor			= "#ffffff"
    Width				= 120
    Height				= 24
    Location			= New-Object System.Drawing.Point(($SelectedFileTxt.Right + 8), ($SelectedFileTxt.Top - 2))
    Visible				= $true
}

$ExecuteBtn				= New-Object system.Windows.Forms.Button -Property @{
    Text				= "Start"
    Font				= "Microsoft Sans Serif, 10"
    ForeColor			= "#000"
    BackColor			= "#ffffff"
    Width				= 90
    Height				= 30
    Location			= New-Object System.Drawing.Point(260, ($StatusLbl.Top - 48))
    Anchor 				= [System.Windows.Forms.AnchorStyles]::Bottom`
                            -bor [System.Windows.Forms.AnchorStyles]::Right
    Visible				= $true
}

$cancelBtn				= New-Object system.Windows.Forms.Button -Property @{
    Text				= "Cancel"
    Font				= "Microsoft Sans Serif, 10"
    ForeColor			= "#000"
    BackColor			= "#ffffff"
    Width				= 90
    Height				= 30
    Location			= New-Object System.Drawing.Point(($ExecuteBtn.Right + 24), ($ExecuteBtn.Top))
    Anchor 				= [System.Windows.Forms.AnchorStyles]::Bottom`
                            -bor [System.Windows.Forms.AnchorStyles]::Right
    DialogResult		= [System.Windows.Forms.DialogResult]::Cancel
}

$StatusLbl					= New-Object system.Windows.Forms.Label -Property @{
    Text				= "Status"
    Font				= "Microsoft Sans Serif, 10"
    Width				= $SelectedFolderLbl.Text.Length * 8
    Height				= $StatusLbl.Font.Size * 2
    Location			= New-Object System.Drawing.Point(16, ($LocalForm.Bottom - 72))
    Anchor 				= [System.Windows.Forms.AnchorStyles]::Bottom`
                            -bor [System.Windows.Forms.AnchorStyles]::Right
}

$StatusTxt				= New-Object system.Windows.Forms.Label -Property @{
    Text				= "current status"
    Font				= "Microsoft Sans Serif, 10"
    Width				= $StatusTxt.Text.Length * 8
    Height				= $StatusTxt.Font.Size * 2
    Location			= New-Object System.Drawing.Point(($StatusLbl.Right + 8), ($StatusLbl.Top))
    Anchor 				= [System.Windows.Forms.AnchorStyles]::Bottom`
                            -bor [System.Windows.Forms.AnchorStyles]::Right
}

$LocalForm.CancelButton	= $cancelBtn

$LocalForm.controls.AddRange( @(
    $TitleLbl, $DescriptionLbl, $Checkbox, 
    $SelectedFolderLbl, $SelectedFolderTxt, $SelectFolderBtn, 
    $SelectedFileLbl, $SelectedFileTxt, $SelectFileBtn, 
    $ExecuteBtn, $cancelBtn,
    $StatusLbl, $StatusTxt
) )

#-----------------------------------------------------------[Functions]------------------------------------------------------------

function Checkbox_Click {
    If ($Checkbox.Checked) {
        Write-Host "Checked"
    } Else {
        Write-Host "Unhecked"
    }
}

function SelectFolderTxt_Changed {
    $global:Folder = $SelectedFolderTxt.Text
}

function SelectFileBtn_Click {
    $FileDialog = New-Object System.Windows.Forms.OpenFileDialog
    $null = $FileDialog.ShowDialog()
    $FileName = $FileDialog.FileName
    Write-Host "$FileName"
}

function SelectFolderBtn_Click {
    $FolderDialog = New-Object System.Windows.Forms.FolderBrowserDialog
    $null = $FolderDialog.ShowDialog()
    $global:Folder = $FolderDialog.SelectedPath
}

function ExecuteBtn_Click { 
    write-host "$global:Folder"
}

#---------------------------------------------------------[Script]--------------------------------------------------------

$Checkbox.Add_CheckStateChanged( {Checkbox_Click} )
$SelectFolderTxt.Add_CheckStateChanged( {SelectFolderTxt_Changed} )
$SelectFolderBtn.Add_Click( {SelectFolderBtn_Click} )
$SelectFileBtn.Add_Click( {SelectFileBtn_Click} )
$ExecuteBtn.Add_Click( {ExecuteBtn_Click} )

# Get Last Used Settings & Locale
if (Test-Path "$PSScriptRoot\settings.ini"){
    Get-Content "$PSScriptRoot\settings.ini" | foreach-object -begin {$h=@{}} -process { $k = [regex]::split($_,'='); if(($k[0].CompareTo("") -ne 0) -and ($k[0].StartsWith("[") -ne $True)) { $h.Add($k[0], $k[1]) } }
    $LocalForm.text = $h."LocalForm.text"
    $Title.text = $h."Title.text"
    $Description.text = $h."Description.text"
}

[void]$LocalForm.ShowDialog()
[void]$LocalForm.Activate()
