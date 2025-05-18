if ( ($psISE) -and (Test-Path -Path $psISE.CurrentFile.FullPath)) {
    $ScriptRoot = Split-Path -Path $psISE.CurrentFile.FullPath -Parent
} else {
    $ScriptRoot = $PSScriptRoot
}
$ScriptParent = Split-Path -Path $ScriptRoot -Parent

$venv = "$($env:USERPROFILE)\python\sigma"
$inputDir = (Join-Path -Path $ScriptParent -ChildPath 'rules')
$outputDir = (Join-Path -Path $ScriptParent -ChildPath 'output')
$pipelineDir = (Join-Path -Path $ScriptParent -ChildPath 'pipelines')
$filterDir = (Join-Path -Path $ScriptParent -ChildPath 'filters')

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

sigma convert --target splunk --pipeline splunk_windows --pipeline $pipelineDir --filter $filterDir --output $outputDir\selected_rules.conf $inputDir

deactivate