<# 
.SYNOPSIS
    Apply local security policy and advanced audit policy settings without domain GPO.

.DESCRIPTION
    - Creates secpol.cfg (registry-backed policy) and audit.csv (advanced audit subcategories)
    - Applies with secedit/auditpol
    - Enables BITS Operational log + real-time via wevtutil
    - Verifies and prints results

.NOTES
    Run as Administrator
#>

#-----------------------------#
# 0) Safety & setup
#-----------------------------#
# Require admin
$principal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Error "Please run this script in an elevated PowerShell session (Run as Administrator)."
    exit 1
}

$TimeStamp = Get-Date -Format "yyyyMMdd-HHmmss"
$WorkDir   = Join-Path $env:TEMP "LocalPolicy-Apply-$TimeStamp"
$null = New-Item -ItemType Directory -Force -Path $WorkDir

$CfgPath   = Join-Path $WorkDir "secpol.cfg"
$CsvPath   = Join-Path $WorkDir "audit.csv"
$SecDBPath = Join-Path $WorkDir "secedit.sdb"

#-----------------------------#
# 1) Write secpol.cfg (registry-backed policy)
#-----------------------------#
$secpol = @"
[Unicode]
Unicode=yes
[Version]
signature="`$CHICAGO`$"
Revision=1
[Registry Values]
; --- PowerShell: Turn on Module Logging ---
; Enable module logging
MACHINE\Software\Policies\Microsoft\Windows\PowerShell\ModuleLogging\EnableModuleLogging=4,1
; Log all modules: value name "*" with value "*"
MACHINE\Software\Policies\Microsoft\Windows\PowerShell\ModuleLogging\ModuleNames\*=1,"*"

; --- NTLM restrictions / auditing ---
; Restrict NTLM: Audit Incoming NTLM Traffic (1 = Enable auditing)
MACHINE\System\CurrentControlSet\Control\Lsa\MSV1_0\AuditReceivingNTLMTraffic=4,1

; --- Windows Eventing: BITS Client Operational channel ---
; Enable the ETW channel for Microsoft-Windows-Bits-Client/Operational
MACHINE\Software\Microsoft\Windows\CurrentVersion\WINEVT\Channels\Microsoft-Windows-Bits-Client/Operational\Enabled=4,1
"@

$secpol | Out-File -FilePath $CfgPath -Encoding Unicode -Force

#-----------------------------#
# 2) Write audit.csv (Advanced Audit Policy)
#-----------------------------#
$auditCsv = @"
Machine Name,Policy Target,Subcategory,Subcategory GUID,Inclusion Setting,Exclusion Setting,Setting Value
,System,File System,{0cce922d-69ae-11d9-bed3-505054503030},Success and Failure,,3
,System,Audit Registry,{0cce922f-69ae-11d9-bed3-505054503030},Success and Failure,,3
,System,Detailed File Share,{0cce9244-69ae-11d9-bed3-505054503030},Success and Failure,,3
"@

$auditCsv | Out-File -FilePath $CsvPath -Encoding ASCII -Force

#-----------------------------#
# 3) Apply secpol.cfg with secedit
#-----------------------------#
Write-Host "Applying secpol.cfg via secedit..." -ForegroundColor Cyan
secedit /configure /db "$SecDBPath" /cfg "$CfgPath" /quiet
if ($LASTEXITCODE -ne 0) {
    Write-Warning "secedit returned code $LASTEXITCODE. (It sometimes returns non-zero even when keys apply; verification will confirm.)"
}

#-----------------------------#
# 4) Apply audit.csv with auditpol
#-----------------------------#
Write-Host "Applying audit.csv via auditpol..." -ForegroundColor Cyan
auditpol /restore /file:"$CsvPath" | Out-Null
if ($LASTEXITCODE -ne 0) {
    Write-Warning "auditpol returned code $LASTEXITCODE. Verification will confirm actual state."
}

#-----------------------------#
# 5) Enable BITS Operational channel & real-time
#-----------------------------#
Write-Host "Enabling BITS Operational channel + realtime..." -ForegroundColor Cyan
wevtutil set-log "Microsoft-Windows-Bits-Client/Operational" /enabled:true /q:true | Out-Null
wevtutil set-log "Microsoft-Windows-Bits-Client/Operational" /rt:true /q:true | Out-Null

#-----------------------------#
# 6) Verification
#-----------------------------#
$results = New-Object System.Collections.Generic.List[object]

function Test-RegistryValue {
    param(
        [Parameter(Mandatory)][string]$HivePath,   # e.g. HKLM:\System\...
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)]$Expected
    )
    $actual = $null
    $ok = $false
    try {
        # Use -LiteralPath to tolerate unusual key names (e.g., with '/')
        $actual = (Get-ItemProperty -LiteralPath $HivePath -ErrorAction Stop).$Name
        $ok = ($actual -eq $Expected)
    } catch {
        $actual = $null
        $ok = $false
    }
    [pscustomobject]@{
        Item      = "REG:`$($HivePath) [$Name]"
        Expected  = $Expected
        Actual    = $actual
        Compliant = $ok
    }
}

# Module Logging: EnableModuleLogging=1
$results.Add( (Test-RegistryValue -HivePath 'HKLM:\Software\Policies\Microsoft\Windows\PowerShell\ModuleLogging' -Name 'EnableModuleLogging' -Expected 1) )

# Module Logging: ModuleNames value "*" with data "*"
# Reading a property literally named "*" requires using .NET registry, since PS property access is awkward for that.
try {
    $baseKey = [Microsoft.Win32.RegistryKey]::OpenBaseKey([Microsoft.Win32.RegistryHive]::LocalMachine,'Default')
    $subKey  = $baseKey.OpenSubKey('Software\Policies\Microsoft\Windows\PowerShell\ModuleLogging\ModuleNames')
    $starVal = $null
    if ($subKey) { $starVal = $subKey.GetValue('*', $null) }
    $results.Add([pscustomobject]@{
        Item      = 'REG: HKLM\...\ModuleLogging\ModuleNames ["*"]'
        Expected  = '*'
        Actual    = $starVal
        Compliant = ($starVal -eq '*')
    })
} catch {
    $results.Add([pscustomobject]@{
        Item='REG: HKLM\...\ModuleLogging\ModuleNames ["*"]'; Expected='*'; Actual=$null; Compliant=$false
    })
}

# NTLM auditing (domain audit is DC-only)
$results.Add( (Test-RegistryValue -HivePath 'HKLM:\System\CurrentControlSet\Control\Lsa\MSV1_0' -Name 'AuditReceivingNTLMTraffic' -Expected 1) )

# BITS Operational channel enabled (verify via wevtutil to avoid key-name issues)
$bitsStatus = (wevtutil get-log "Microsoft-Windows-Bits-Client/Operational" 2>$null)
$enabled = $false
$rt      = $false
if ($bitsStatus) {
    $enabled = ($bitsStatus -match 'enabled:\s*true')
    $rt      = ($bitsStatus -match 'LOG\smode:\s*RealTime' -or $bitsStatus -match 'retention:\s*false' ) # heuristic; RealTime often shown differently by OS build
}
$results.Add([pscustomobject]@{
    Item='BITS Operational channel enabled'
    Expected='True'
    Actual=$enabled
    Compliant=$enabled
})
$results.Add([pscustomobject]@{
    Item='BITS Operational channel realtime'
    Expected='True'
    Actual=$rt
    Compliant=$rt
})

# Auditpol verification
function Get-AuditSubcategoryState {
    param([string[]]$Names)
    $rows = foreach ($n in $Names) {
        $out = auditpol /get /subcategory:"$n" /r 2>$null
        # CSV-ish single line, we just need the 'Inclusion Setting'
        # Example line: "System,File System,{GUID},Success and Failure"
        $inc = $null
        if ($out) {
            $line = ($out | Select-Object -Last 1).Trim()
            if ($line -and $line.Contains(',')) {
                $parts = $line.Split(',') | ForEach-Object { $_.Trim() }
                $inc = $parts[-1]
            }
        }
        [pscustomobject]@{ Name=$n; Inclusion=$inc }
    }
    return $rows
}
$audRows = Get-AuditSubcategoryState -Names @('File System','Audit Registry','Detailed File Share')
foreach ($r in $audRows) {
    $results.Add([pscustomobject]@{
        Item      = "Auditpol: $($r.Name)"
        Expected  = 'Success and Failure'
        Actual    = $r.Inclusion
        Compliant = ($r.Inclusion -eq 'Success and Failure')
    })
}

#-----------------------------#
# 7) Output results
#-----------------------------#
$results |
    Sort-Object Item |
    Format-Table -AutoSize

Write-Host "`nWork files saved to: $WorkDir" -ForegroundColor DarkGray
