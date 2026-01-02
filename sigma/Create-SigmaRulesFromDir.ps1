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
    D:\github\Splunk\sigma\utils\Create-SigmaRulesFromDir.ps1 -SigmaInputDir "D:\github\sigma" `
        -CustomInputDir "D:\github\Splunk\sigma\rules" `
        -MeerkatInputDir "D:\github\Splunk\sigma\rules-Meerkat" `
        -OutputDir "C:\Splunk\Signature-Pipeline\Output"
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
    [string]$MeerkatInputDir,

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
if (!$OutputDir)        { $outputDir = (Join-Path -Path $ScriptParent -ChildPath 'output') }
if (!$PipelineDir)      { $pipelineDir = (Join-Path -Path $ScriptParent -ChildPath 'pipelines') }
if (!$FilterDir)        { $filterDir = (Join-Path -Path $ScriptParent -ChildPath 'filters') }

# Validate input directories
$requiredDirs = @($SigmaInputDir, $PipelineDir, $FilterDir)
foreach ($dir in $requiredDirs) {
    if (-not (Test-Path -Path $dir)) {
        Write-Error "Directory not found: $dir"
        exit 1
    }
}

# Count and report rules count
$SigmaRules = (Get-ChildItem $SigmaInputDir -Recurse -Include "*.yml").Count
$SigmaMeerkatRules = (Get-ChildItem $MeerkatInputDir -Recurse -Include "*.yml").Count
Write-Host "Sigma rules to process: $SigmaRules"
Write-Host "Sigma Meerkat rules to process: $SigmaMeerkatRules"

# Create output directory
New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null

# Setup virtual environment
try {
    Write-Host "Setting up virtual environment at $Venv"
    python -m venv $Venv
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
        git clone --branch master https://github.com/SigmaHQ/sigma.git $SigmaInputDir 
    }
    git -C "$Venv\sigma" fetch origin
    git -C "$Venv\sigma" pull origin master
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
    sigma convert --skip-unsupported --target splunk --pipeline splunk_windows --pipeline "$pipelineDir\0240_windows_powershell_module.yml" --pipeline "$pipelineDir\1000_final_windows.yml" --pipeline "$pipelineDir\7000_final_transforms.yml" --filter $filterDir --output $outputDir\windows_powershell_module_rules.conf $SigmaInputDir
    sigma convert --skip-unsupported --target splunk --pipeline splunk_windows --pipeline "$pipelineDir\0250_windows_powershell_script.yml" --pipeline "$pipelineDir\1000_final_windows.yml" --pipeline "$pipelineDir\7000_final_transforms.yml" --filter $filterDir --output $outputDir\windows_powershell_script_rules.conf $SigmaInputDir
    sigma convert --skip-unsupported --target splunk --pipeline splunk_windows --pipeline "$pipelineDir\0260_windows_firewall.yml" --pipeline "$pipelineDir\1000_final_windows.yml" --pipeline "$pipelineDir\7000_final_transforms.yml" --filter $filterDir --output $outputDir\windows_firewall_rules.conf $SigmaInputDir
    sigma convert --skip-unsupported --target splunk --pipeline splunk_windows --pipeline "$pipelineDir\0230_windows_sysmon1-to-4688.yml" --pipeline "$pipelineDir\1000_final_windows.yml" --pipeline "$pipelineDir\7000_final_transforms_sysmon1-to-4688.yml" --filter $filterDir --output $outputDir\sysmon-to-4688_rules.conf $SigmaInputDir
    sigma convert --skip-unsupported --target splunk --pipeline "$pipelineDir\0100_windows_sysmon1-to-meerkat-process.yml" --pipeline "$pipelineDir\7000_final_transforms_sysmon1-to-Meerkat.yml" --filter $filterDir --output $outputDir\rec_process_rules.conf $MeerkatInputDir
    sigma convert --skip-unsupported --target splunk --pipeline "$pipelineDir\0110_registry-to-meerkat-registry.yml" --pipeline "$pipelineDir\7000_final_transforms.yml" --filter $filterDir --output $outputDir\rec_registry_rules.conf $SigmaInputDir
    sigma convert --skip-unsupported --target splunk --pipeline "$pipelineDir\0300_dns-to-forescout.yml" --pipeline "$pipelineDir\7000_final_transforms.yml" --filter $filterDir --output $outputDir\forescout_dns_rules.conf $SigmaInputDir
}

#sigma convert --skip-unsupported -t splunk -p splunk_windows  --pipeline "$pipelineDir\1000_final_windows.yml" --pipeline "$pipelineDir\7000_final_transforms.yml"  D:\github\sigma\rules\windows\builtin\iis-configuration\win_iis_logging_etw_disabled.yml

# Deactivate virtual environment
deactivate