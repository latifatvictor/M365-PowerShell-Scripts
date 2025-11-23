<#
.SYNOPSIS
Exports a report of Microsoft Entra ID PIM role assignments (eligible and active).

.DESCRIPTION
This script connects to Microsoft Graph, retrieves Privileged Identity Management (PIM)
role eligibility and active assignment schedules for directory roles and exports them
to a CSV file for governance and audit purposes.

It includes user details, role names, assignment type, start and end times and approval state.

.PARAMETER OutputPath
The full path to the CSV report, for example C:\Reports\PIMRoleAssignments.csv

.EXAMPLE
.\Get-PIMRoleAssignmentsReport.ps1 -OutputPath "C:\Reports\PIMRoleAssignments.csv"

.NOTES
Requires:
- Microsoft.Graph module
- Permissions: RoleManagement.Read.Directory, Directory.Read.All
#>

param (
    [Parameter(Mandatory = $true)]
    [string]$OutputPath
)

Write-Host "Connecting to Microsoft Graph..." -ForegroundColor Cyan

# Install-Module Microsoft.Graph -Scope CurrentUser
Connect-MgGraph -Scopes "RoleManagement.Read.Directory","Directory.Read.All"

Write-Host "Retrieving PIM role definitions..." -ForegroundColor Cyan

# Cache directory role definitions so we can map RoleDefinitionId to names
$roleDefinitions = Get-MgRoleManagementDirectoryRoleDefinition -All
$roleDefLookup = @{}
foreach ($def in $roleDefinitions) {
    $roleDefLookup[$def.Id] = $def.DisplayName
}

Write-Host "Retrieving PIM eligible role assignments..." -ForegroundColor Cyan
$eligibleAssignments = Get-MgRoleManagementDirectoryRoleEligibilitySchedule -All

Write-Host "Retrieving PIM active role assignments..." -ForegroundColor Cyan
$activeAssignments = Get-MgRoleManagementDirectoryRoleAssignmentSchedule -All

if (-not $eligibleAssignments -and -not $activeAssignments) {
    Write-Host "No PIM role assignments found." -ForegroundColor Yellow
    return
}

Write-Host "Resolving unique principals..." -ForegroundColor Cyan

# Collect unique principal IDs from both sets
$principalIds = @(
    $eligibleAssignments.PrincipalId +
    $activeAssignments.PrincipalId
) | Where-Object { $_ -ne $null } | Select-Object -Unique

$principalLookup = @{}

foreach ($principalId in $principalIds) {
    # Try to resolve as user or service principal
    try {
        $user = Get-MgUser -UserId $principalId -ErrorAction SilentlyContinue
        if ($user) {
            $principalLookup[$principalId] = [PSCustomObject]@{
                Type  = "User"
                Name  = $user.DisplayName
                UPN   = $user.UserPrincipalName
                Email = $user.Mail
            }
            continue
        }

        $sp = Get-MgServicePrincipal -ServicePrincipalId $principalId -ErrorAction SilentlyContinue
        if ($sp) {
            $principalLookup[$principalId] = [PSCustomObject]@{
                Type  = "ServicePrincipal"
                Name  = $sp.DisplayName
                UPN   = $null
                Email = $null
            }
            continue
        }

        # Fallback if object type unknown
        $principalLookup[$principalId] = [PSCustomObject]@{
            Type  = "Unknown"
            Name  = $null
            UPN   = $null
            Email = $null
        }
    }
    catch {
        $principalLookup[$principalId] = [PSCustomObject]@{
            Type  = "Error"
            Name  = $null
            UPN   = $null
            Email = $null
        }
    }
}

Write-Host "Building combined PIM role assignment report..." -ForegroundColor Cyan

$report = @()

foreach ($item in $eligibleAssignments) {
    $principal = $principalLookup[$item.PrincipalId]
    $roleName = $roleDefLookup[$item.RoleDefinitionId]

    $report += [PSCustomObject]@{
        AssignmentType     = "Eligible"
        RoleName           = $roleName
        RoleDefinitionId   = $item.RoleDefinitionId
        PrincipalType      = $principal.Type
        PrincipalName      = $principal.Name
        PrincipalUPN       = $principal.UPN
        PrincipalEmail     = $principal.Email
        AssignmentId       = $item.Id
        ScopeId            = $item.DirectoryScopeId
        StartDateTime      = $item.StartDateTime
        EndDateTime        = $item.EndDateTime
        Status             = $item.Status
        CreatedDateTime    = $item.CreatedDateTime
        ModifiedDateTime   = $item.ModifiedDateTime
    }
}

foreach ($item in $activeAssignments) {
    $principal = $principalLookup[$item.PrincipalId]
    $roleName = $roleDefLookup[$item.RoleDefinitionId]

    $report += [PSCustomObject]@{
        AssignmentType     = "Active"
        RoleName           = $roleName
        RoleDefinitionId   = $item.RoleDefinitionId
        PrincipalType      = $principal.Type
        PrincipalName      = $principal.Name
        PrincipalUPN       = $principal.UPN
        PrincipalEmail     = $principal.Email
        AssignmentId       = $item.Id
        ScopeId            = $item.DirectoryScopeId
        StartDateTime      = $item.StartDateTime
        EndDateTime        = $item.EndDateTime
        Status             = $item.Status
        CreatedDateTime    = $item.CreatedDateTime
        ModifiedDateTime   = $item.ModifiedDateTime
    }
}

Write-Host "Exporting PIM role assignments report to $OutputPath" -ForegroundColor Cyan

try {
    $report | Export-Csv -Path $OutputPath -NoTypeInformation -Encoding UTF8
    Write-Host "Report created successfully." -ForegroundColor Green
    Write-Host "Total assignments exported: $($report.Count)"
}
catch {
    Write-Host "Failed to export report. Check the output path and permissions." -ForegroundColor Red
    throw
}

