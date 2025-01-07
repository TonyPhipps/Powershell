[CmdletBinding()]
Param(
    [String]$IP = "localhost",
    [String]$Port = "8834",
    [String]$Format = "csv", # options are csv, html
    [String]$ApiFile = "$ScriptRoot\ApiCredentials.xml",
    [Array]$ScanIDs = "",
    [String]$OutFolder = $ScriptRoot
)

Add-Type -AssemblyName System.Security


if (($psISE) -and (Test-Path -Path $psISE.CurrentFile.FullPath)) {
    $ScriptRoot = Split-Path -Path $psISE.CurrentFile.FullPath -Parent
} else {
    $ScriptRoot = $PSScriptRoot
}

$ModuleRoot = Split-Path -Path $ScriptRoot -Parent

$ApiKey    = ""
$ApiSecret = ""

# Function to securely store the credentials in an XML file using DPAPI
function Save-Credentials {
    param (
        [string]$ApiKey,
        [string]$ApiSecret
    )
    
    # Create an object to hold the credentials
    $credentials = New-Object PSObject -Property @{
        ApiKey = $ApiKey
        ApiSecret = $ApiSecret
    }

    # Convert the credentials object to XML
    $xml = $credentials | ConvertTo-Xml -NoTypeInformation
    $xmlString = $xml.OuterXml

    # Encrypt the XML string using the Windows Data Protection API
    $encryptedData = [System.Security.Cryptography.ProtectedData]::Protect([System.Text.Encoding]::UTF8.GetBytes($xmlString), $null, [System.Security.Cryptography.DataProtectionScope]::LocalMachine)

    # Save the encrypted data to the file
    [System.IO.File]::WriteAllBytes($ApiFile, $encryptedData)
}


# Function to read and decrypt credentials from the XML file using DPAPI
function Get-Credentials {
    if (Test-Path $ApiFile) {
        # Read the encrypted data from the file
        $encryptedData = [System.IO.File]::ReadAllBytes($ApiFile)

        # Decrypt the data using the Windows Data Protection API
        $decryptedData = [System.Security.Cryptography.ProtectedData]::Unprotect($encryptedData, $null, [System.Security.Cryptography.DataProtectionScope]::LocalMachine)

        # Convert the decrypted byte array back to a string
        $xmlString = [System.Text.Encoding]::UTF8.GetString($decryptedData)

        # Load the XML
        $xml = [xml]$xmlString

        # Convert XML back to PSObject
        $credentials = [PSCustomObject]@{
            ApiKey    = $xml.Objects.Object.Property[1].'#text' #$xml.DocumentElement.ApiKey
            ApiSecret = $xml.Objects.Object.Property[0].'#text' #$xml.DocumentElement.ApiSecret
        }
        
        return $credentials
    } else {
        return $null
    }
}

# Function to prompt for secure input
function Prompt-ForSecureInput {
    param (
        [string]$Message
    )
    return Read-Host -Prompt $Message -AsSecureString
}

Write-Verbose "Check if the credentials file exists"
$existingCredentials = Get-Credentials

if ($existingCredentials) {
    Write-Verbose "If the file exists, use the existing credentials"
    Write-Host "Existing credentials found."
    $ApiKey = $existingCredentials.ApiKey
    $ApiSecret = $existingCredentials.ApiSecret
} else {
    Write-Verbose "If the file does not exist, prompt for new credentials"
    $ApiKeySecure = Prompt-ForSecureInput "Enter your API Key"
    $ApiSecretSecure = Prompt-ForSecureInput "Enter your API Secret"

    Write-Verbose "Convert SecureString to plain text for storage"
    $ApiKeyPtr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($ApiKeySecure)
    $ApiKey = [Runtime.InteropServices.Marshal]::PtrToStringAuto($ApiKeyPtr)
    
    $ApiSecretPtr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($ApiSecretSecure)
    $ApiSecret = [Runtime.InteropServices.Marshal]::PtrToStringAuto($ApiSecretPtr)

    Write-Verbose "Save the credentials"
    Save-Credentials -ApiKey $ApiKey -ApiSecret $ApiSecret
    Write-Host "Credentials saved securely."
}

$Headers = @{"X-ApiKeys" = "accessKey=$($ApiKey); secretKey=$($ApiSecret)"}

Write-Verbose "Trust all certificates (use if self-signed cert is being used)"
add-type @"
using System.Net;
using System.Security.Cryptography.X509Certificates;
public class TrustAllCertsPolicy : ICertificatePolicy {
    public bool CheckValidationResult(
        ServicePoint srvPoint, X509Certificate certificate,
        WebRequest request, int certificateProblem) {
        return true;
    }
}
"@
[System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy


Write-Verbose "Prepare params to get all scans"
$ScanParams = @{
    "Uri"     = "https://$($IP):$($Port)/scans"
    "Method"  = "GET"
    "Headers" = $Headers
}

Write-Verbose "Get Available Scans"
if ($ScanIDs) {
    Write-Host "Exporting Nessus Scan ID(s): $($ScanIDs)"
} else {
    try {
    $ScanResponse = Invoke-WebRequest @ScanParams 
    $ScanResponse = ConvertFrom-Json $ScanResponse.Content
    $ScanResponse.scans | Select-Object name, id | Out-String | Write-Host
    $ScanIDs = Read-Host "Enter target ScanID(s)"
    } catch {
        if ($_.Exception.Response.StatusCode -eq "429") {
            Write-Verbose "Too many requests made in specific period of time. Wait 30 seconds before re-running script."
            return 1
        } else {
            throw $_
        }
    }  
}

foreach ($ScanID in $ScanIDs) {
    Write-Verbose "Prepare params to get all reports from scans"
    $ReportParams = @{
        "Uri"     = "https://$($IP):$($Port)/scans/$($ScanID)/export"
        "Method"  = "POST"
        "ContentType"  = "application/json"
        "Headers" = $Headers

	    "Body"     = @{
            "format"   = $Format
        } | ConvertTo-Json -Depth 10
    }

    Write-Verbose "Request Report export"
    $ReportResponse = Invoke-RestMethod @ReportParams


    Write-Verbose "Prepare params to get scan export status"
    $StatusParams = @{
        "Uri"         = "https://$($IP):$($Port)/scans/$($ScanID)/export/$($ReportResponse.file)/status"
        "Method"      = "GET"
        "Headers" = $Headers
    }

    Write-Verbose "Check export status"
    while ($true) {
        Start-Sleep -Seconds 5
        try{
            $StatusResponse = Invoke-RestMethod @StatusParams
        } catch {
            Write-Host "Error: $($_.Exception.Message) `n" -ForegroundColor Yellow
        }
        if ($StatusResponse.status -eq "ready") { break }
    }

    Write-Verbose "Prepare params to get all files from reports"
    $FileParams = @{
        "Uri"     = "https://$($IP):$($Port)/scans/$($ScanID)/export/$($ReportResponse.file)/download"
        "Method"  = "GET"
        "Headers" = $Headers
    }

    Write-Verbose "Download the exported file"
    $FilePath = $OutFolder + "\NessusReport_$($ScanID)_$(Get-Date -Format 'yyyy-MM-dd').csv"
    $DownloadResponse = Invoke-WebRequest @FileParams -OutFile $FilePath
    Write-Verbose "Exported: $FilePath"
}