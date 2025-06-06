﻿# Defaults asusme the folder structure:
# .\sigma\util\SCRIPT_IS_HERE
# .\sigma\rules
# .\sigma\output
# .\sigma\pipelines
# .\sigma\filters

# Example
# .\Create-SigamRulesFromDir.ps1 `
# -inputDir "C:\Users\you\sigma\selected-rules" `
# -outputDir "C:\Users\you\sigma\"

param (
    [string]$venv,
    [string]$inputDir,
    [string]$outputDir,
    [string]$pipelineDir,
    [string]$filterDir
)

if ( ($psISE) -and (Test-Path -Path $psISE.CurrentFile.FullPath)) {
    $ScriptRoot = Split-Path -Path $psISE.CurrentFile.FullPath -Parent
} else {
    $ScriptRoot = $PSScriptRoot
}
$ScriptParent = Split-Path -Path $ScriptRoot -Parent

if (!$venv)         { $venv = "$($env:USERPROFILE)\python\sigma" }
if (!$inputDir)     { $inputDir = (Join-Path -Path $ScriptParent -ChildPath 'rules') }
if (!$outputDir)    { $outputDir = (Join-Path -Path $ScriptParent -ChildPath 'output') }
if (!$pipelineDir)  { $pipelineDir = (Join-Path -Path $ScriptParent -ChildPath 'pipelines') }
if (!$filterDir)    { $filterDir = (Join-Path -Path $ScriptParent -ChildPath 'filters') }

# Ensure rules exist in \rules\
if ((Get-ChildItem $inputDir -Recurse -Include "*.yml").Length -eq 0 ){
    Write-Host "No rules, exiting"
    return
}

# Ensure output directory exists
New-Item -ItemType Directory -Path $outputDir -Force

python -m venv $venv

Set-Location $venv

& "$venv\Scripts\Activate.ps1"

python -m pip install --upgrade pip
python -m pip install --upgrade sigma-cli
git clone --branch master https://github.com/SigmaHQ/sigma.git
Set-Location sigma
git fetch origin
git pull origin master

sigma convert --skip-unsupported --target splunk --pipeline splunk_windows --pipeline $pipelineDir --filter $filterDir --output $outputDir\selected_rules.conf $inputDir

deactivate
Set-Location $ScriptRoot