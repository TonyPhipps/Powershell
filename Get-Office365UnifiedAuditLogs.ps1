# References
# https://docs.microsoft.com/en-us/microsoft-365/compliance/search-the-audit-log-in-security-and-compliance?view=o365-worldwide
# https://docs.microsoft.com/en-us/powershell/module/exchange/search-unifiedauditlog?view=exchange-ps
# https://docs.microsoft.com/en-us/office/office-365-management-api/office-365-management-activity-api-schema#auditlogrecordtype
# https://docs.microsoft.com/en-us/microsoft-365/compliance/export-view-audit-log-records?view=o365-worldwide

# Prereq Option 1: Use ConnectO365Services or another means to establish a connection to Exchange Online using MFA
# https://gallery.technet.microsoft.com/office/PowerShell-Script-to-4081ec0f
#ConnectO365Services.ps1 -MFA

# Prereq Option 2: for single-factor authentication, follow these steps
# https://docs.microsoft.com/en-us/powershell/exchange/exchange-online-powershell-v2?view=exchange-ps#install-and-maintain-the-exo-v2-module
# https://docs.microsoft.com/en-us/powershell/exchange/connect-to-exchange-online-powershell?view=exchange-ps
#Install-Module ExchangeOnlineManagement
#Import-Module ExchangeOnlineManagement
#$UserCredential = Get-Credential
#Connect-ExchangeOnline -Credential $UserCredential -ShowProgress $true

# Note
# Splitting out recordtypes is one of many workarounds to the 5000 result limit.

$OutDir = "C:\Logs"
$StartDate = (Get-Date).AddDays(-365)
$EndDate = get-date

# Set the user you wish to gather data for
$userSMTP = "user@domain.com"

If (!(Test-Path $OutDir))
   {
    New-Item -ItemType Directory -Path $OutDir -ErrorAction SilentlyContinue | Out-Null
   }
$RecordTypes = (
	"AeD",
	"AipDiscover",
	"AipFileDeleted",
	"AipHeartBeat",
	"AipProtectionAction",
	"AipSensitivityLabelAction",
	"AirAdminActionInvestigation",
	"AirInvestigation",
	"AirManualInvestigation",
	"ApplicationAudit",
	"AttackSim",
	"AzureActiveDirectory",
	"AzureActiveDirectoryAccountLogon",
	"AzureActiveDirectoryStsLogon",
	"CRM",
	"Campaign",
	"ComplianceDLPExchange",
	"ComplianceDLPExchangeClassification",
	"ComplianceDLPSharePoint",
	"ComplianceDLPSharePointClassification",
	"ComplianceSupervisionExchange",
	"CortanaBriefing",
	"CustomerKeyServiceEncryption",
	"DLPEndpoint",
	"DataCenterSecurityCmdlet",
	"DataGovernance",
	"DataInsightsRestApiAudit",
	"Discovery",
	"ExchangeAdmin",
	"ExchangeAggregatedOperation",
	"ExchangeItem",
	"ExchangeItemAggregated",
	"ExchangeItemGroup",
	"ExchangeSearch",
	"HRSignal",
	"HygieneEvent",
	"InformationBarrierPolicyApplication",
	"InformationWorkerProtection",
	"Kaizala",
	"LabelContentExplorer",
	"MCASAlerts",
	"MDATPAudit",
	"MIPLabel",
	"MS365DCustomDetection",
	"MSDEGeneralSettings",
	"MSDEIndicatorsSettings",
	"MSDEResponseActions",
	"MSDERolesSettings",
	"MSTIC",
	"MailSubmission",
	"MicrosoftFlow",
	"MicrosoftForms",
	"MicrosoftStream",
	"MicrosoftTeams",
	"MicrosoftTeamsAdmin",
	"MicrosoftTeamsAnalytics",
	"MicrosoftTeamsDevice",
	"MicrosoftTeamsShifts",
	"MipAutoLabelExchangeItem",
	"MipAutoLabelSharePointItem",
	"MipAutoLabelSharePointPolicyLocation",
	"MipExactDataMatch",
	"MyAnalyticsSettings",
	"OfficeNative",
	"OnPremisesFileShareScannerDlp",
	"OnPremisesSharePointScannerDlp",
	"OneDrive",
	"PhysicalBadgingSignal",
	"PowerAppsApp",
	"PowerAppsPlan",
	"PowerBIAudit",
	"PrivacyInsights",
	"Project",
	"Quarantine",
	"Search",
	"SecurityComplianceAlerts",
	"SecurityComplianceCenterEOPCmdlet",
	"SecurityComplianceInsights",
	"SecurityComplianceRBAC",
	"SecurityComplianceUserChange",
	"SensitivityLabelAction",
	"SensitivityLabelPolicyMatch",
	"SensitivityLabeledFileAction",
	"SharePoint",
	"SharePointCommentOperation",
	"SharePointContentTypeOperation",
	"SharePointFieldOperation",
	"SharePointFileOperation",
	"SharePointListItemOperation",
	"SharePointListOperation",
	"SharePointSearch",
	"SharePointSharingOperation",
	"SkypeForBusinessCmdlets",
	"SkypeForBusinessPSTNUsage",
	"SkypeForBusinessUsersBlocked",
	"Sway",
	"SyntheticProbe",
	"TeamsHealthcare",
	"ThreatFinder",
	"ThreatIntelligence",
	"ThreatIntelligenceAtpContent",
	"ThreatIntelligenceUrl",
	"UserTraining",
	"WDATPAlerts",
	"WorkplaceAnalytics",
	"Yammer"
)

foreach ($RecordType in $RecordTypes){
    Write-Output $RecordType
    $UnifiedAuditLog = Search-UnifiedAuditLog -UserIds $userSMTP -StartDate $StartDate -EndDate $EndDate -SessionCommand ReturnLargeSet -ResultSize 5000 -RecordType $RecordType
    if ($UnifiedAuditLog){
        $UnifiedAuditLog | Select-Object CreationDate, UserIDs, Operations, AuditData | Export-Csv -Path "$OutDir\UnifiedAuditLog_$RecordType.csv" -NoTypeInformation -Append
    }
}
