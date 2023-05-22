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
$global:File            = ".\file.txt"

#---------------------------------------------------------[Form]--------------------------------------------------------

$iconPath               = "{0}\icon.ico" -f $PSScriptRoot
$url                    = "https://github.com/favicon.ico"
Invoke-WebRequest -Uri $url -OutFile $iconPath
$Icon                   = New-Object system.drawing.icon ($iconPath)

$LocalForm              = New-Object system.Windows.Forms.Form -Property @{
    text                = "Window Title"
    Icon                = $Icon
    BackColor           = "#ffffff"
    ClientSize          = "720, 600"
    MinimumSize         = '500, 500'
    StartPosition       = [System.Windows.Forms.FormStartPosition]::CenterScreen
    
}

$TitleLbl               = New-Object system.Windows.Forms.Label -Property @{
    Text                = "The Title text"
    Font                = "Microsoft Sans Serif, 13"
    Width               = $LocalForm.Width - 24
    Height              = 24
    Location            = '16, 24'
    Anchor              = "Top, Left, Right"
}

$DescriptionLbl         = New-Object system.Windows.Forms.Label -Property @{
    Text                = "The description text"
    Font                = "Microsoft Sans Serif, 10"
    Width               = $LocalForm.Width - 24
    Height              = 50
    Location            = New-Object System.Drawing.Point(16, ($TitleLbl.Bottom + 8))
    Anchor              = "Top, Left, Right"
}

$Checkbox               = New-Object System.Windows.Forms.Checkbox  -Property @{
    Text                = "Checkbox text"
    Width               = 500
    Height              = 24
    Location            = New-Object System.Drawing.Point(16, ($DescriptionLbl.Bottom + 8))
}

$SelectedFolderLbl      = New-Object System.Windows.Forms.Label -Property @{
    Text                = "Folder: "
    Font                = "Microsoft Sans Serif, 10"
    Width               = 50
    Height              = 24
    Location            = New-Object System.Drawing.Point(16, ($Checkbox.Bottom + 8))
}

$SelectedFolderTxt      = New-Object System.Windows.Forms.TextBox -Property @{
    Text                = "{0}" -f $Folder
    Width               = 256
    Height              = 70
    Location            = New-Object System.Drawing.Point(($SelectedFolderLbl.Width + 32), ($SelectedFolderLbl.Top))
    #Enabled            = $false
}

$SelectFolderBtn        = New-Object system.Windows.Forms.Button -Property @{
    Text                = "Change"
    Font                = "Microsoft Sans Serif, 10"
    ForeColor           = "#000"
    BackColor           = "#ffffff"
    Width               = 120
    Height              = 24
    Location            = New-Object System.Drawing.Point(($SelectedFolderTxt.Width + 96), ($SelectedFolderLbl.Top - 2))
    Visible             = $true
}

$SelectedFileLbl        = New-Object System.Windows.Forms.Label -Property @{
    Text                = "File: "
    Font                = "Microsoft Sans Serif, 10"
    Width               = 50
    Height              = 24
    Location            = New-Object System.Drawing.Point(16, ($SelectedFolderLbl.Bottom + 8))
}

$SelectedFileTxt        = New-Object System.Windows.Forms.TextBox -Property @{
    Text                = "{0}" -f $File
    Width               = 256
    Height              = 70
    Location            = New-Object System.Drawing.Point(($SelectedFileLbl.Width + 32), ($SelectedFileLbl.Top))
    #Enabled            = $false
}

$SelectFileBtn          = New-Object system.Windows.Forms.Button -Property @{
    Text                = "Change"
    Font                = "Microsoft Sans Serif, 10"
    ForeColor           = "#000"
    BackColor           = "#ffffff"
    Width               = 120
    Height              = 24
    Location            = New-Object System.Drawing.Point(($SelectedFileTxt.Width + 96), ($SelectedFileLbl.Top - 2))
    Visible             = $true
}

$OutputTxt        = New-Object System.Windows.Forms.TextBox -Property @{
    Text                = ""
    Multiline           = $true
    ReadOnly            = $true
    Width               = ($LocalForm.ClientSize.Width - 24)
    Height              = 300
    Location            = New-Object System.Drawing.Point(16, ($SelectedFileLbl.Bottom + 16))
    Anchor              = "Top, Bottom, Left, Right"
}

$ExecuteBtn             = New-Object system.Windows.Forms.Button -Property @{
    Text                = "Start"
    Font                = "Microsoft Sans Serif, 10"
    ForeColor           = "#000"
    BackColor           = "#ffffff"
    Width               = 90
    Height              = 30
    Location            = New-Object System.Drawing.Point(260, ($OutputTxt.Bottom + 8))
    Anchor              = "Bottom"
    Visible             = $true
}

$CancelBtn              = New-Object system.Windows.Forms.Button -Property @{
    Text                = "Cancel"
    Font                = "Microsoft Sans Serif, 10"
    ForeColor           = "#000"
    BackColor           = "#ffffff"
    Width               = 90
    Height              = 30
    Location            = New-Object System.Drawing.Point(($ExecuteBtn.Right + 8), ($ExecuteBtn.Top))
    Anchor              = "Bottom"
    DialogResult        = [System.Windows.Forms.DialogResult]::Cancel
}

$StatusLbl              = New-Object system.Windows.Forms.Label -Property @{
    Text                = "Status: "
    Font                = "Microsoft Sans Serif, 10"
    Width               = 50
    Height              = 24
    Location            = New-Object System.Drawing.Point(16, ($ExecuteBtn.Bottom + 8))
    Anchor              = "Bottom, Left"
}

$StatusTxt              = New-Object system.Windows.Forms.Label -Property @{
    Text                = "current status asdfasdf4awrt4awraw;lfoiajse l;kasj fl;kas f ;lkasdf as;ldkfj asd;lkf sad;"
    Font                = "Microsoft Sans Serif, 10"
    Width               = ($LocalForm.Width - 50)
    Height              = 24
    Location            = New-Object System.Drawing.Point(($StatusLbl.Width + 16), ($StatusLbl.Top))
    Anchor              = "Bottom, Left"
}

$ProgressBar = New-Object System.Windows.Forms.ProgressBar -Property @{
    Name                = 'progressBar1'
    Value               = 0
    Style               = "Continuous"
    Width               = ($LocalForm.ClientSize.Width - 32)
    Height              = 10
    Location            = New-Object System.Drawing.Point(16, ($StatusLbl.Bottom - 8))
    Anchor              = "Bottom, Left, Right"
}

$LocalForm.CancelButton = $CancelBtn

$LocalForm.controls.AddRange( @(
    $TitleLbl, $DescriptionLbl, $Checkbox, 
    $SelectedFolderLbl, $SelectedFolderTxt, $SelectFolderBtn, 
    $SelectedFileLbl, $SelectedFileTxt, $SelectFileBtn, 
    $OutputTxt, 
    $ProgressBar, 
    $StatusLbl, $StatusTxt,
    $ExecuteBtn, $CancelBtn
) )

#-----------------------------------------------------------[Functions]------------------------------------------------------------

function Checkbox_Click {
    If ($Checkbox.Checked) {
        Write-Host "Checked"
    } Else {
        Write-Host "Unhecked"
    }
}

function SelectFileBtn_Click {
    $FileDialog = New-Object System.Windows.Forms.OpenFileDialog
    $null = $FileDialog.ShowDialog()
    
    $SelectedFileTxt.Text = $FileDialog.FileName
    $Global:File = $FileDialog.FileName
    Write-Host ("{0}" -f $FileDialog.FileName)
}

function SelectFolderBtn_Click {
    $FolderDialog = New-Object System.Windows.Forms.FolderBrowserDialog
    $null = $FolderDialog.ShowDialog()
    
    $SelectedFolderTxt.Text = $FolderDialog.SelectedPath
    $Global:Folder = $FolderDialog.SelectedPath
    Write-Host ("{0}" -f $FolderDialog.SelectedPath)
}

function ExecuteBtn_Click { 
    $OutputTxt.Text = ($OutputTxt.Text + "Folder: {0}`r`n" -f $Global:Folder)
    $OutputTxt.Text = ($OutputTxt.Text + "File {0}`r`n" -f $Global:File)
    $OutputTxt.Text = ($OutputTxt.Text + "`r`n")
}

#---------------------------------------------------------[Script]--------------------------------------------------------

$Checkbox.Add_CheckStateChanged( {Checkbox_Click} )
$SelectFolderBtn.Add_Click( {SelectFolderBtn_Click} )
$SelectFileBtn.Add_Click( {SelectFileBtn_Click} )
$ExecuteBtn.Add_Click( {ExecuteBtn_Click} )

# Get Last Used Settings & Locale
if (Test-Path "$PSScriptRoot\settings.ini"){
    $h=@{}
    Get-Content "$PSScriptRoot\settings.ini" | foreach-object -process { $k = [regex]::split($_,'='); if(($k[0].CompareTo("") -ne 0) -and ($k[0].StartsWith("[") -ne $True)) { $h.Add($k[0], $k[1]) } }
    $LocalForm.Text = $h."LocalForm.text"
    $TitleLbl.Text = $h."Title.text"
    $DescriptionLbl.Text = $h."Description.text"
}

[void]$LocalForm.ShowDialog()
[void]$LocalForm.Activate()
