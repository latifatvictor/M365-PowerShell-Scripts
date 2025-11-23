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
Exports a basic user report from Microsoft Entra ID using Microsoft Graph.

.DESCRIPTION
This script connects to Microsoft Graph, retrieves all users and exports selected
properties to a CSV file for reporting or audit purposes.

.PARAMETER OutputPath
Path to the CSV file that will be created.

.EXAMPLE
.\Get-M365-UsersReport.ps1 -OutputPath "C:\Reports\M365Users.csv"
#>

param (
    [Parameter(Mandatory = $true)]
    [string]$OutputPath
)

Write-Host "Connecting to Microsoft Graph..." -ForegroundColor Cyan

Connect-MgGraph -Scopes "User.Read.All"

Write-Host "Retrieving users from Microsoft Entra ID..." -ForegroundColor Cyan

$allUsers = Get-MgUser -All

$userReport = $allUsers | Select-Object `
    DisplayName,
    UserPrincipalName,
    AccountEnabled,
    JobTitle,
    Department,
    CreatedDateTime

Write-Host "Exporting report to $OutputPath ..." -ForegroundColor Cyan

$userReport | Export-Csv -Path $OutputPath -NoTypeInformation -Encoding UTF8

Write-Host "Report created successfully." -ForegroundColor Green
Write-Host "Total users exported: $($userReport.Count)"
