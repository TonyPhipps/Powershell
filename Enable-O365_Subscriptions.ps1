# Enables all logging subscriptions for an O365 Application (for example, for SIEM ingestion)
# Reference: https://docs.microsoft.com/en-us/office/office-365-management-api/office-365-management-activity-api-reference#list-current-subscriptions

$tenantId = "1"
$clientId = "2"
$clientSecret = "3"

$subscriptions = @(
    'Audit.AzureActiveDirectory',
    'Audit.Exchange',
    'Audit.SharePoint',
    'Audit.General',
    'DLP.All'
)

# Get Access Token

$Headers = @{
    'Content-Type' = 'application/x-www-form-urlencoded'
}

$Body = "grant_type=client_credentials&client_id=$clientId&client_secret=$clientSecret&resource=https://manage.office.com"

$Response = Invoke-WebRequest -UseBasicParsing -Method POST -Headers $Headers -Body $Body -uri https://login.microsoftonline.com/$tenantId/oauth2/token

$Response = ConvertFrom-Json $([String]::new($Response.Content))

$AccessToken = $Response.access_token

# Activate Subscriptions

$Headers = @{
    'Authorization' = 'bearer ' + $AccessToken
}

foreach ($sub in $subscriptions){
    Invoke-WebRequest -UseBasicParsing -method POST -Headers $Headers -uri https://manage.office.com/api/v1.0/$tenantId/activity/feed/subscriptions/start?contentType=$sub
}

# Verify Subscriptions

$Verification_Response = Invoke-WebRequest -UseBasicParsing -method GET -Headers $Headers -uri https://manage.office.com/api/v1.0/$tenantId/activity/feed/subscriptions/list

$Verification_Response = ConvertFrom-Json $([String]::new($Verification_Response.Content))

$Verification_Response
