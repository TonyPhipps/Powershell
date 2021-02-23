# Setup
# https://outlook.office365.com/ecp > Hybrid > "The Exchange Online PowerShell Module..." > Configure > Install
#Uninstall-Module ExchangeOnlineManagement
#Install-Module ExchangeOnlineManagement

# Single Factor
#$UserCredential = Get-Credential
#Connect-ExchangeOnline -Credential $UserCredential -ShowProgress $true

# MFA
Import-Module ExchangeOnlineManagement
Connect-EXOPSSession -UserPrincipalName user@email.com

$OutDir = "C:\Logs"
$StartDate = (Get-Date).AddDays(-365)
$EndDate = get-date

# Set the user you wish to gather data for
$userSMTP = "user@domain.com"

If (!(Test-Path $OutDir))
   {
    New-Item -ItemType Directory -Path $OutDir -ErrorAction SilentlyContinue | Out-Null
   }
   
# Note: Splitting out recordtypes is one of many workarounds to the 5000 result limit.
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
