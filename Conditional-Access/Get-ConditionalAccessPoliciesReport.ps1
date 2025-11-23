# Dot source the Graph helper script
. "$PSScriptRoot\..\Utility\Connect-Graph.ps1"

# Then call the function with the scopes you need
Connect-LatiGraph -Scopes @(
    "User.Read.All",
    "User.ReadWrite.All",
    "Directory.Read.All",
    "Directory.ReadWrite.All"
)

<#
.SYNOPSIS
Exports a report of all Microsoft Entra ID Conditional Access policies.

.DESCRIPTION
This script connects to Microsoft Graph, retrieves all Conditional Access policies
and exports selected details to a CSV file. It is useful for governance, audit,
documentation and reviewing policy configuration.

.PARAMETER OutputPath
The full file path for the CSV report, for example C:\Reports\ConditionalAccessPolicies.csv

.EXAMPLE
.\Get-ConditionalAccessPoliciesReport.ps1 -OutputPath "C:\Reports\ConditionalAccessPolicies.csv"
#>

param (
    [Parameter(Mandatory = $true)]
    [string]$OutputPath
)

Write-Host "Connecting to Microsoft Graph..." -ForegroundColor Cyan

# Requires the Microsoft.Graph module
# Install-Module Microsoft.Graph -Scope CurrentUser
Connect-MgGraph -Scopes "Policy.Read.All","Directory.Read.All"

Write-Host "Retrieving Conditional Access policies..." -ForegroundColor Cyan

try {
    $policies = Get-MgIdentityConditionalAccessPolicy -All
}
catch {
    Write-Host "Failed to retrieve Conditional Access policies. Check your permissions and connection." -ForegroundColor Red
    throw
}

if (-not $policies) {
    Write-Host "No Conditional Access policies found." -ForegroundColor Yellow
    return
}

Write-Host "Processing $($policies.Count) policies..." -ForegroundColor Cyan

$report = foreach ($policy in $policies) {

    # Build comma separated summaries for key conditions and controls
    $users = $null
    if ($policy.Conditions.Users) {
        $includeUsers = $policy.Conditions.Users.IncludeUsers -join ";"
        $includeRoles = $policy.Conditions.Users.IncludeRoles -join ";"
        $includeGroups = $policy.Conditions.Users.IncludeGroups -join ";"

        $users = "Users: $includeUsers | Roles: $includeRoles | Groups: $includeGroups"
    }

    $locations = $null
    if ($policy.Conditions.Locations) {
        $includeLocations = $policy.Conditions.Locations.IncludeLocations -join ";"
        $excludeLocations = $policy.Conditions.Locations.ExcludeLocations -join ";"
        $locations = "Include: $includeLocations | Exclude: $excludeLocations"
    }

    $platforms = $null
    if ($policy.Conditions.Platforms) {
        $includePlatforms = $policy.Conditions.Platforms.IncludePlatforms -join ";"
        $excludePlatforms = $policy.Conditions.Platforms.ExcludePlatforms -join ";"
        $platforms = "Include: $includePlatforms | Exclude: $excludePlatforms"
    }

    $clientApps = $null
    if ($policy.Conditions.ClientAppTypes) {
        $clientApps = $policy.Conditions.ClientAppTypes -join ";"
    }

    $grantControls = $null
    if ($policy.GrantControls) {
        $grantControls = $policy.GrantControls.BuiltInControls -join ";"
    }

    $sessionControls = $null
    if ($policy.SessionControls) {
        $sessionControlsList = @()
        if ($policy.SessionControls.Applications) { $sessionControlsList += "App enforced" }
        if ($policy.SessionControls.CloudAppSecurity) { $sessionControlsList += "MCAS" }
        if ($policy.SessionControls.PersistentBrowser) { $sessionControlsList += "Persistent browser" }
        if ($policy.SessionControls.SignInFrequency) { $sessionControlsList += "Sign-in frequency" }
        $sessionControls = $sessionControlsList -join ";"
    }

    [PSCustomObject]@{
        PolicyName         = $policy.DisplayName
        PolicyId           = $policy.Id
        State              = $policy.State                  # enabled / disabled / reportOnly
        Conditions_Users   = $users
        Conditions_Locations = $locations
        Conditions_Platforms = $platforms
        Conditions_ClientApps = $clientApps
        GrantControls      = $grantControls
        SessionControls    = $sessionControls
        CreatedDateTime    = $policy.CreatedDateTime
        ModifiedDateTime   = $policy.ModifiedDateTime
    }
}

Write-Host "Exporting Conditional Access policy report to $OutputPath" -ForegroundColor Cyan

try {
    $report | Export-Csv -Path $OutputPath -NoTypeInformation -Encoding UTF8
    Write-Host "Report created successfully." -ForegroundColor Green
    Write-Host "Total policies exported: $($report.Count)"
}
catch {
    Write-Host "Failed to export report. Check the output path and permissions." -ForegroundColor Red
    throw
}
