# https://lazyadmin.nl/powershell/powershell-gui-howto-get-started/

#----------------------------------------------------[Allow use of -Verbose]--------------------------------------------------

[CmdletBinding()] param ()

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

#-------------------------------------------------------[Init Form]-----------------------------------------------------

$global:InFile          = ".\settings.ini"
$global:BaseCommand     = "Measure-Object"
$global:OutFolder       = $PSScriptRoot
$global:Command         = ("Get-Content '{0}' `| {1}" -f $global:InFile, $global:BaseCommand)

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

$SelectInputLbl        = New-Object System.Windows.Forms.Label -Property @{
    Text                = "Input:"
    Font                = "Microsoft Sans Serif, 10"
    Width               = 60
    Height              = 24
    Location            = New-Object System.Drawing.Point(16, ($DescriptionLbl.Bottom + 8))
}

$SelectInputTxt        = New-Object System.Windows.Forms.TextBox -Property @{
    Text                = "{0}" -f $File
    ReadOnly            = $true
    Width               = 256
    Height              = 70
    Location            = New-Object System.Drawing.Point(($SelectInputLbl.Right + 8), ($SelectInputLbl.Top))
}

$SelectInputBtn          = New-Object system.Windows.Forms.Button -Property @{
    Text                = "Change"
    Font                = "Microsoft Sans Serif, 10"
    ForeColor           = "#000"
    BackColor           = "#ffffff"
    Width               = 120
    Height              = 24
    Location            = New-Object System.Drawing.Point(($SelectInputTxt.Right + 8), ($SelectInputLbl.Top - 2))
    Visible             = $true
}

$SelectOutputLbl      = New-Object System.Windows.Forms.Label -Property @{
    Text                = "Output:"
    Font                = "Microsoft Sans Serif, 10"
    Width               = 60
    Height              = 24
    Location            = New-Object System.Drawing.Point(16, ($SelectInputLbl.Bottom + 8))
}

$SelectOutputTxt      = New-Object System.Windows.Forms.TextBox -Property @{
    Text                = "{0}" -f $Folder
    ReadOnly            = $true
    Width               = 256
    Height              = 70
    Location            = New-Object System.Drawing.Point(($SelectOutputLbl.Right + 8), ($SelectOutputLbl.Top))
}

$SelectOutputBtn        = New-Object system.Windows.Forms.Button -Property @{
    Text                = "Change"
    Font                = "Microsoft Sans Serif, 10"
    ForeColor           = "#000"
    BackColor           = "#ffffff"
    Width               = 120
    Height              = 24
    Location            = New-Object System.Drawing.Point(($SelectOutputTxt.Right + 8), ($SelectOutputLbl.Top - 2))
    Visible             = $true
}

$Checkbox               = New-Object System.Windows.Forms.Checkbox  -Property @{
    Text                = "Output to File"
    Width               = 100
    Height              = 24
    Location            = New-Object System.Drawing.Point(($SelectOutputBtn.Right + 8), ($SelectOutputBtn.Top))
}

$CommandToRunLbl        = New-Object System.Windows.Forms.Label -Property @{
    Text                = "Command:"
    Font                = "Microsoft Sans Serif, 10"
    Width               = 75
    Height              = 24
    Location            = New-Object System.Drawing.Point(16, ($SelectOutputLbl.Bottom + 8))
}

$CommandToRunTxt        = New-Object system.Windows.Forms.TextBox -Property @{
    Text                = $global:Command
    ReadOnly            = $true
    Font                = "Microsoft Sans Serif, 10"
    Width               = 450
    Height              = 24
    Location            = New-Object System.Drawing.Point(($CommandToRunLbl.Right + 8), ($CommandToRunLbl.Top - 2))
    Visible             = $true
}

$OutputTxt        = New-Object System.Windows.Forms.TextBox -Property @{
    Text                = ""
    Multiline           = $true
    ScrollBars          = "Vertical"
    ReadOnly            = $true
    Width               = ($LocalForm.ClientSize.Width - 24)
    Height              = 300
    Location            = New-Object System.Drawing.Point(16, ($CommandToRunLbl.Bottom + 16))
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
    Location            = New-Object System.Drawing.Point(($StatusLbl.Right + 8), ($StatusLbl.Top))
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
    $TitleLbl, 
    $DescriptionLbl,
    $SelectInputLbl, $SelectInputTxt, $SelectInputBtn, 
    $SelectOutputLbl, $SelectOutputTxt, $SelectOutputBtn, $Checkbox,
    $CommandToRunLbl, $CommandToRunTxt, 
    $OutputTxt, 
    $ProgressBar, 
    $ExecuteBtn, $CancelBtn, 
    $StatusLbl, $StatusTxt
) )

#-----------------------------------------------------------[Functions]------------------------------------------------------------

function Update-Command {
    $global:Command = ("Get-Content '{0}' `| {1}" -f $global:InFile, $global:BaseCommand)
    $CommandToRunTxt.Text = $global:Command
}

function Checkbox_Click {
    If ($Checkbox.Checked) {
        Write-Verbose "Checked"
        Update-Command
    } Else {
        Write-Verbose "Unhecked"
        Update-Command
    }
}

function SelectInputBtn_Click {
    $FileDialog = New-Object System.Windows.Forms.OpenFileDialog
    $null = $FileDialog.ShowDialog()
    
    $SelectInputTxt.Text = $FileDialog.FileName
    $global:InFile = $FileDialog.FileName
    Update-Command
    Write-Verbose ("{0}" -f $FileDialog.FileName)
}

function SelectOutputBtn_Click {
    $FolderDialog = New-Object System.Windows.Forms.FolderBrowserDialog
    $null = $FolderDialog.ShowDialog()
    
    $SelectOutputTxt.Text = $FolderDialog.SelectedPath
    $global:OutFolder = $FolderDialog.SelectedPath
    Update-Command
    Write-Verbose ("{0}" -f $FolderDialog.SelectedPath)
}

function ExecuteBtn_Click { 

    $StatusTxt.Text = "Executing..."

    $OutputTxt.AppendText("Running: `r`n`t {0}`r`n" -f $global:Command)
    Invoke-Expression -Command "$global:Command *>&1" |
        ForEach-Object {
            $OutputTxt.AppendText("$_`r`n")
        }

    If ($Checkbox.Checked) {
        $Result | Out-File ("{0}\test.txt" -f $global:OutFolder)
        $OutputTxt.AppendText("Saved to {0}\test.txt `r`n" -f $global:OutFolder)
    }

    $OutputTxt.AppendText("`r`n`r`n")
    $StatusTxt.Text = "Completed."
}

#---------------------------------------------------------[Script]--------------------------------------------------------

$Checkbox.Add_CheckStateChanged( {Checkbox_Click} )
$SelectOutputBtn.Add_Click( {SelectOutputBtn_Click} )
$SelectInputBtn.Add_Click( {SelectInputBtn_Click} )
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
