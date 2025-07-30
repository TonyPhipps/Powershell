<#
.SYNOPSIS
    Converts Sigma and custom rules to Splunk configuration files and merges them into savedsearches.conf.

.DESCRIPTION
    This script processes Sigma and custom rules from specified directories, converts them to Splunk format using sigma-cli,
    and merges the output into a single savedsearches.conf file.

.PARAMETER Venv
    Path to the Python virtual environment directory.

.PARAMETER SigmaInputDir
    Directory containing Sigma rules.

.PARAMETER CustomInputDir
    Directory containing custom Sigma rules.

.PARAMETER OutputDir
    Directory for output configuration files.

.PARAMETER PipelineDir
    Directory containing pipeline configuration files.

.PARAMETER FilterDir
    Directory containing filter configuration files.

.EXAMPLE
    .\Create-SigmaRulesFromDir.ps1 -SigmaInputDir "D:\github\sigma\rules" `
        -CustomInputDir "D:\github\sigma\rules-custom" `
        -OutputDir "D:\github\sigma\output"
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$Venv = "$($env:USERPROFILE)\python\sigma",

    [Parameter(Mandatory = $false)]
    [string]$SigmaInputDir,

    [Parameter(Mandatory = $false)]
    [string]$CustomInputDir,

    [Parameter(Mandatory = $false)]
    [string]$OutputDir,

    [Parameter(Mandatory = $false)]
    [string]$PipelineDir,

    [Parameter(Mandatory = $false)]
    [string]$FilterDir
)

# Initialize script root
$ScriptRoot = if ($psISE -and (Test-Path -Path $psISE.CurrentFile.FullPath)) {
    Split-Path -Path $psISE.CurrentFile.FullPath -Parent
} else {
    $PSScriptRoot
}
$ScriptParent = Split-Path -Path $ScriptRoot -Parent

# Set default paths if not provided
if (!$Venv)             { $venv = "$($env:USERPROFILE)\python\sigma" }
if (!$SigmaInputDir)    { $SigmaInputDir = (Join-Path -Path $ScriptParent -ChildPath 'rules') }
if (!$CustomInputDir)   { $CustomInputDir = (Join-Path -Path $ScriptParent -ChildPath 'rules-custom') }
if (!$OutputDir)        { $outputDir = (Join-Path -Path $ScriptParent -ChildPath 'output') }
if (!$PipelineDir)      { $pipelineDir = (Join-Path -Path $ScriptParent -ChildPath 'pipelines') }
if (!$FilterDir)        { $filterDir = (Join-Path -Path $ScriptParent -ChildPath 'filters') }

# Validate input directories
$requiredDirs = @($SigmaInputDir, $CustomInputDir, $PipelineDir, $FilterDir)
foreach ($dir in $requiredDirs) {
    if (-not (Test-Path -Path $dir)) {
        Write-Error "Directory not found: $dir"
        exit 1
    }
}

# Count rules
$SigmaRules = (Get-ChildItem $SigmaInputDir -Recurse -Include "*.yml").Count
$CustomRules = (Get-ChildItem $CustomInputDir -Recurse -Include "*.yml").Count

# Exit if no rules found
if ($sigmaRules -eq 0 -and $customRules -eq 0) {
    Write-Warning "No Sigma or custom rules found. Exiting."
    exit 0
} else {
    Write-Host "Sigma rules to process: $SigmaRules"
    Write-Host "Custom Sigma rules to process: $CustomRules"
}

# Create output directory
New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null

# Setup virtual environment
try {
    Write-Host "Setting up virtual environment at $Venv"
    python -m venv $Venv
    Set-Location $Venv
    & "$Venv\Scripts\Activate.ps1"
    python -m pip install --upgrade pip
    python -m pip install --upgrade sigma-cli
}
catch {
    Write-Error "Failed to setup virtual environment: $_"
    exit 1
}

# Clone and update Sigma repository
try {
    Write-Host "Updating Sigma repository"
    if (-not (Test-Path "sigma")) {
        git clone --branch master https://github.com/SigmaHQ/sigma.git
    }
    Set-Location sigma
    git fetch origin
    git pull origin master
}
catch {
    Write-Error "Failed to update Sigma repository: $_"
    exit 1
}

# Sigma
if (-not $SigmaRules){
    Write-Host "No sigma rules, continuing"
} else {
    Write-Host "Processing Sigma rules"
    sigma convert --skip-unsupported --target splunk --pipeline splunk_windows --pipeline "$pipelineDir\0200_windows_application.yml" --pipeline "$pipelineDir\1000_final_windows.yml" --pipeline "$pipelineDir\7000_final_transforms.yml" --filter $filterDir --output $outputDir\windows_application_rules.conf $SigmaInputDir
    sigma convert --skip-unsupported --target splunk --pipeline splunk_windows --pipeline "$pipelineDir\0210_windows_security.yml" --pipeline "$pipelineDir\1000_final_windows.yml" --pipeline "$pipelineDir\7000_final_transforms.yml" --filter $filterDir --output $outputDir\windows_security_rules.conf $SigmaInputDir
    sigma convert --skip-unsupported --target splunk --pipeline splunk_windows --pipeline "$pipelineDir\0220_windows_system.yml" --pipeline "$pipelineDir\1000_final_windows.yml" --pipeline "$pipelineDir\7000_final_transforms.yml" --filter $filterDir --output $outputDir\windows_system_rules.conf $SigmaInputDir
    sigma convert --skip-unsupported --target splunk --pipeline splunk_windows --pipeline "$pipelineDir\0230_windows_sysmon-to-4688.yml" --pipeline "$pipelineDir\1000_final_windows.yml" --pipeline "$pipelineDir\7000_final_transforms_sysmon-1.yml" --filter $filterDir --output $outputDir\sysmon-to-4688_rules.conf $SigmaInputDir
    sigma convert --skip-unsupported --target splunk --pipeline "$pipelineDir\0100_rec_process.yml" --pipeline "$pipelineDir\7000_final_transforms.yml" --filter $filterDir --output $outputDir\rec_process_rules.conf $SigmaInputDir
    sigma convert --skip-unsupported --target splunk --pipeline "$pipelineDir\0110_rec_registry.yml" --pipeline "$pipelineDir\7000_final_transforms.yml" --filter $filterDir --output $outputDir\rec_registry_rules.conf $SigmaInputDir
    sigma convert --skip-unsupported --target splunk --pipeline "$pipelineDir\0300_forescout_dns.yml" --pipeline "$pipelineDir\7000_final_transforms.yml" --filter $filterDir --output $outputDir\forescout_dns_rules.conf $SigmaInputDir
}

# Custom
if (-not $CustomRules){
    Write-Host "No custom rules, skipping"
} else {
    Write-Host "Processing Custom Sigma rules"
    sigma convert --skip-unsupported --target splunk --pipeline splunk_windows --pipeline "$pipelineDir\0200_windows_application.yml" --pipeline "$pipelineDir\1000_final_windows.yml" --pipeline "$pipelineDir\7000_final_transforms.yml" --filter $filterDir --output $outputDir\custom_windows_application_rules.conf $CustomInputDir
    sigma convert --skip-unsupported --target splunk --pipeline splunk_windows --pipeline "$pipelineDir\0210_windows_security.yml" --pipeline "$pipelineDir\1000_final_windows.yml" --pipeline "$pipelineDir\7000_final_transforms.yml" --filter $filterDir --output $outputDir\custom_windows_security_rules.conf $CustomInputDir
    sigma convert --skip-unsupported --target splunk --pipeline splunk_windows --pipeline "$pipelineDir\0220_windows_system.yml" --pipeline "$pipelineDir\1000_final_windows.yml" --pipeline "$pipelineDir\7000_final_transforms.yml" --filter $filterDir --output $outputDir\custom_windows_system_rules.conf $CustomInputDir
    sigma convert --skip-unsupported --target splunk --pipeline splunk_windows --pipeline "$pipelineDir\0230_windows_sysmon-to-4688.yml" --pipeline "$pipelineDir\1000_final_windows.yml" --pipeline "$pipelineDir\7000_final_transforms.yml" --filter $filterDir --output $outputDir\custom_sysmon-to-4688_rules.conf $CustomInputDir
    sigma convert --skip-unsupported --target splunk --pipeline "$pipelineDir\0100_rec_process.yml" --pipeline "$pipelineDir\7000_final_transforms.yml" --filter $filterDir --output $outputDir\custom_rec_process_rules.conf $CustomInputDir
    sigma convert --skip-unsupported --target splunk --pipeline "$pipelineDir\0110_rec_registry.yml" --pipeline "$pipelineDir\7000_final_transforms.yml" --filter $filterDir --output $outputDir\custom_rec_registry_rules.conf $CustomInputDir
    sigma convert --skip-unsupported --target splunk --pipeline "$pipelineDir\0300_forescout_dns.yml" --pipeline "$pipelineDir\7000_final_transforms.yml" --filter $filterDir --output $outputDir\custom_forescout_dns_rules.conf $CustomInputDir
}

#sigma convert --skip-unsupported -t splunk -p splunk_windows  --pipeline "$pipelineDir\1000_final_windows.yml" --pipeline "$pipelineDir\7000_final_transforms.yml"  D:\github\sigma\rules\windows\builtin\iis-configuration\win_iis_logging_etw_disabled.yml

# Deactivate virtual environment and return to script root
deactivate
Set-Location $ScriptRoot

# Merge each pipeline output into a single savedsearches.conf
$confFiles = Get-ChildItem -Path $outputDir -Filter '*.conf' | Where-Object {$_.Name -match '_rules.conf'}
[System.Collections.ArrayList]$outputContent = @()
[System.Collections.Hashtable]$stanzas = @{}
ForEach ($file in $confFiles) {
    $fileContent = Get-Content -Path $file.FullName -Encoding UTF8
    $currentStanza = ''
    ForEach ($line in $fileContent) {
        if ($line -match '^\[') {
                $currentStanza = $line
                if ($null -eq $stanzas[$currentStanza]){
                    $stanzas[$currentStanza] = [System.Collections.ArrayList]@($line) 
                } else {
                    if ($currentStanza -match "\[default\]") {
                        #multiple defaults expected, silently accept the last one
                        $stanzas[$currentStanza] = [System.Collections.ArrayList]@($line)
                    } else {
                        Write-Warning "Duplicate Stanza Detected: $($currentStanza) | Using stanza from: $($file)"
                    }
                }
        } else {
            $stanzas[$currentStanza].Add($line) > $null        
        }
    }
}
if ($null -ne $stanzas['[default]']){
    ForEach ($line in $stanzas['[default]']){
        $outputContent.Add($line) > $null
    }
} else {
    Write-Warning "No [default] stanza found - savedsearches will not run"
}
$sortedStanzas = $stanzas.Keys | Where { $_ -notmatch "\[default\]"} | Sort-Object
ForEach ($stanza in $sortedStanzas) {
    ForEach ($line in $stanzas[$stanza]){
        $outputContent.Add($line) > $null
    }
}

# Check if the file exists; if not, create it
$SavedsearchesConfPath = Join-Path -Path $outputDir -ChildPath 'savedsearches_sorted.conf'
if (-not (Test-Path -Path $SavedsearchesConfPath)) {
    New-Item -Path $SavedsearchesConfPath -ItemType File -Force | Out-Null
}

$SavedsearchesConfPath = Resolve-Path -Path $SavedsearchesConfPath #WriteAllText function requires an absolute path
Clear-Content -Path $SavedsearchesConfPath
[String]$outputContentRaw = ($outputContent -join "`n") + "`n"
$Utf8NoBomEncoding = New-Object System.Text.UTF8Encoding $False
[System.IO.File]::WriteAllText($SavedsearchesConfPath, $outputContentRaw, $Utf8NoBomEncoding)