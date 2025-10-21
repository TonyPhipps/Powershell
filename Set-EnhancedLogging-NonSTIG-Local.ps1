<# 
.SYNOPSIS
    Apply local security policy and advanced audit policy settings without domain GPO.

.NOTES
    Run as Administrator
#>


#region Backup + Reporting Helpers

function New-BackupDirectory {
    param([string]$BaseDir)
    if ([string]::IsNullOrWhiteSpace($BaseDir)) {
        $BaseDir = Join-Path $env:ProgramData ("EnhancedLogging_Backup_" + (Get-Date -Format 'yyyyMMdd-HHmmss'))
    }
    New-Item -ItemType Directory -Force -Path $BaseDir | Out-Null
    return $BaseDir
}

function Export-RegistryKeys {
    <#
        Exports key policy areas to .reg files using reg.exe.
        Returns array of exported file paths (including a merged All.reg).
    #>
    param([Parameter(Mandatory)][string]$OutDir)
    $keys = @(
        'HKLM\System\CurrentControlSet\Control\Lsa',                              # includes SCENoApplyLegacyAuditPolicy, AuditReceivingNTLMTraffic
        'HKLM\SOFTWARE\Policies\Microsoft\Windows\PowerShell'                     # PS logging settings
    )
    $exports = @()
    foreach ($k in $keys) {
        $safe = ($k -replace '[\\/:*?"<>|]', '_')
        $file = Join-Path $OutDir "$safe.reg"
        try {
            Write-Host "Exporting: $k -> $file"
            & reg.exe export "$k" "$file" /y | Out-Null
            if (Test-Path $file) { $exports += $file }
        } catch {
            Write-Warning "Failed to export $k : $($_.Exception.Message)"
        }
    }
}

function Get-EventLogInfo {
    param([string[]]$Names)
    $info = @()
    foreach ($n in $Names) {
        try {
            $raw = & wevtutil.exe gl $n 2>$null
            $h = @{}
            foreach ($line in $raw) {
                if ($line -match '^\s*([A-Za-z ]+):\s*(.*)\s*$') {
                    $h[$matches[1].Trim()] = $matches[2].Trim()
                }
            }
            $info += [pscustomobject]@{
                LogName    = $n
                Enabled    = $h['enabled']
                MaxSizeKB  = [int](([double]($h['maximum size'])/1024))
                Retention  = $h['retention']
                AutoBackup = $h['autoBackup']
            }
        } catch {}
    }
    return $info
}

function Show-ResultantSettings {
    <#
      Summarizes key values after configuration
    #>
    $lsabase    = 'HKLM:\System\CurrentControlSet\Control\Lsa'
    $msvbase    = 'HKLM:\System\CurrentControlSet\Control\Lsa\MSV1_0'
    $psbase     = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\PowerShell'
    $vals = [ordered]@{}
    $vals.SCENoApplyLegacyAuditPolicy = (Get-ItemProperty $lsabase -Name SCENoApplyLegacyAuditPolicy -ErrorAction SilentlyContinue).SCENoApplyLegacyAuditPolicy
    $vals.AuditReceivingNTLMTraffic   = (Get-ItemProperty $msvbase -Name AuditReceivingNTLMTraffic   -ErrorAction SilentlyContinue).AuditReceivingNTLMTraffic
    $vals.PS_ModuleLogging            = (Get-ItemProperty "$psbase\ModuleLogging"      -Name EnableModuleLogging      -ErrorAction SilentlyContinue).EnableModuleLogging
    $ntlmLog                          = Get-EventLogInfo -Names @('Microsoft-Windows-NTLM/Operational')
    Write-Host "`n=== Resultant Settings ===" -ForegroundColor Green
    $vals.GetEnumerator() | ForEach-Object { "{0,-35} : {1}" -f $_.Key, $_.Value } | Write-Host
    Write-Host "`n--- NTLM Operational Channel ---" -ForegroundColor Yellow
    $ntlmLog | Format-Table -AutoSize | Out-String | Write-Host
}
#endregion

#region Main

# Create a backup folder and export the relevant policy keys as .reg files
$bk = New-BackupDirectory  # or: New-BackupDirectory -BaseDir 'D:\MyBackups'
$exports = Export-RegistryKeys -OutDir $bk
Write-Host "Registry backups written to: $bk"

# --- Core settings ---
Set-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control\Lsa' -Name SCENoApplyLegacyAuditPolicy -Value 1
Set-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control\Lsa\MSV1_0' -Name AuditReceivingNTLMTraffic -Value 2
wevtutil set-log 'Microsoft-Windows-NTLM/Operational' /enabled:true /rt:true /q:true

# PowerShell logging
New-Item -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\PowerShell\ModuleLogging\ModuleNames' -Force | Out-Null
Set-ItemProperty 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\PowerShell\ModuleLogging' -Name EnableModuleLogging -Value 1
Set-ItemProperty 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\PowerShell\ModuleLogging\ModuleNames' -Name '*' -Value '*'
Set-ItemProperty 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\PowerShell\ScriptBlockLogging' -Name EnableScriptBlockLogging -Value 1

# Call Report
Show-ResultantSettings

#endregion


