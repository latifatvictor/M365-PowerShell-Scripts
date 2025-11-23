<#
.SYNOPSIS
Generates a Microsoft 365 licensing report using Microsoft Graph.

.DESCRIPTION
This script connects to Microsoft Graph and retrieves:
- All licences available in the tenant
- Total licences purchased
- Assigned licences
- Unassigned/licences remaining
- User-level licence assignments

The report is exported to a CSV file and is useful for audits, cost control, governance
and identity lifecycle analysis.

.PARAMETER OutputPath
Path for the CSV file containing the output.

.EXAMPLE
.\Get-M365LicencesReport.ps1 -OutputPath "C:\Reports\M365LicencesReport.csv"
#>

param (
    [Parameter(Mandatory = $true)]
    [string]$OutputPath
)

Write-Host "Connecting to Microsoft Graph..." -ForegroundColor Cyan

Connect-MgGraph -Scopes "Directory.Read.All","User.Read.All"

Write-Host "Retrieving licence SKU details..." -ForegroundColor Cyan

# Pull tenant licence information
$licences = Get-MgSubscribedSku

if (-not $licences) {
    Write-Host "No licence data found. Ensure your account has Directory.Read.All permissions." -ForegroundColor Red
    return
}

Write-Host "Retrieving Microsoft 365 users..." -ForegroundColor Cyan

$users = Get-MgUser -All -Property "displayName,userPrincipalName,assignedLicenses"

Write-Host "Processing licence usage..." -ForegroundColor Cyan

$report = @()

foreach ($licence in $licences) {

    $skuId = $licence.SkuId
    $skuPartNumber = $licence.SkuPartNumber
    $totalLicences = $licence.PrepaidUnits.Enabled
    $consumedLicences = $licence.ConsumedUnits
    $unusedLicences = $totalLicences - $consumedLicences

    # Get list of users assigned this licence
    $assignedUsers = $users |
        Where-Object { $_.AssignedLicenses.SkuId -contains $skuId }

    foreach ($user in $assignedUsers) {
        $report += [PSCustomObject]@{
            SkuPartNumber      = $skuPartNumber
            SkuId              = $skuId
            TotalLicences      = $totalLicences
            ConsumedLicences   = $consumedLicences
            UnusedLicences     = $unusedLicences
            UserDisplayName    = $user.DisplayName
            UserPrincipalName  = $user.UserPrincipalName
        }
    }

    # Add a summary row for SKUs with no users
    if ($assignedUsers.Count -eq 0) {
        $report += [PSCustomObject]@{
            SkuPartNumber      = $skuPartNumber
            SkuId              = $skuId
            TotalLicences      = $totalLicences
            ConsumedLicences   = $consumedLicences
            UnusedLicences     = $unusedLicences
            UserDisplayName    = "None"
            UserPrincipalName  = "None"
        }
    }
}

Write-Host "Exporting report to $OutputPath..." -ForegroundColor Cyan

try {
    $report | Export-Csv -Path $OutputPath -NoTypeInformation -Encoding UTF8
    Write-Host "✔ Microsoft 365 licence report created successfully!" -ForegroundColor Green
    Write-Host "Total records exported: $($report.Count)"
}
catch {
    Write-Host "Failed to export the report. Check the output path and permissions." -ForegroundColor Red
    throw
}
