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
Exports an authentication methods report for Microsoft Entra ID users.

.DESCRIPTION
This script connects to Microsoft Graph, retrieves authentication methods for each user
and exports a summary report to CSV. It can be used for MFA coverage checks, security
audits and identity governance reviews.

For each user, the report indicates whether they have
- Microsoft Authenticator app
- Phone authentication methods
- FIDO2 security keys
- Windows Hello for Business
- Email authentication
- Any MFA-capable method

.PARAMETER OutputPath
The full file path for the CSV report, for example C:\Reports\AuthenticationMethods.csv

.EXAMPLE
.\Get-AuthenticationMethodsReport.ps1 -OutputPath "C:\Reports\AuthenticationMethods.csv"

.NOTES
Requires:
- Microsoft.Graph module
- Permissions: UserAuthenticationMethod.Read.All, User.Read.All
Some authentication methods APIs may require Graph beta in some tenants.
#>

param (
    [Parameter(Mandatory = $true)]
    [string]$OutputPath
)

Write-Host "Connecting to Microsoft Graph..." -ForegroundColor Cyan

# Install-Module Microsoft.Graph -Scope CurrentUser
Connect-MgGraph -Scopes "UserAuthenticationMethod.Read.All","User.Read.All"

Write-Host "Retrieving users from Microsoft Entra ID..." -ForegroundColor Cyan

try {
    $users = Get-MgUser -All
}
catch {
    Write-Host "Failed to retrieve users. Check permissions and connection." -ForegroundColor Red
    throw
}

if (-not $users) {
    Write-Host "No users found in directory." -ForegroundColor Yellow
    return
}

Write-Host "Found $($users.Count) users. Retrieving authentication methods..." -ForegroundColor Cyan

$results = @()

foreach ($user in $users) {

    Write-Host "Processing user: $($user.DisplayName) ($($user.UserPrincipalName))" -ForegroundColor DarkCyan

    $hasAuthenticatorApp   = $false
    $hasPhoneMethod        = $false
    $hasFido2Key           = $false
    $hasWindowsHello       = $false
    $hasEmailMethod        = $false
    $hasAnyMfaCapable      = $false

    try {
        $methods = Get-MgUserAuthenticationMethod -UserId $user.Id -ErrorAction Stop
    }
    catch {
        Write-Host "Could not retrieve methods for $($user.UserPrincipalName). Skipping." -ForegroundColor DarkYellow
        continue
    }

    foreach ($method in $methods) {
        switch ($method.AdditionalProperties.'@odata.type') {

            "#microsoft.graph.microsoftAuthenticatorAuthenticationMethod" {
                $hasAuthenticatorApp = $true
                $hasAnyMfaCapable = $true
            }

            "#microsoft.graph.phoneAuthenticationMethod" {
                $hasPhoneMethod = $true
                # Phone methods can be used for MFA
                $hasAnyMfaCapable = $true
            }

            "#microsoft.graph.fido2AuthenticationMethod" {
                $hasFido2Key = $true
                $hasAnyMfaCapable = $true
            }

            "#microsoft.graph.windowsHelloForBusinessAuthenticationMethod" {
                $hasWindowsHello = $true
                $hasAnyMfaCapable = $true
            }

            "#microsoft.graph.emailAuthenticationMethod" {
                $hasEmailMethod = $true
            }

            default {
                # Other or future method types can be logged or ignored
            }
        }
    }

    $results += [PSCustomObject]@{
        DisplayName           = $user.DisplayName
        UserPrincipalName     = $user.UserPrincipalName
        AccountEnabled        = $user.AccountEnabled
        HasAuthenticatorApp   = $hasAuthenticatorApp
        HasPhoneMethod        = $hasPhoneMethod
        HasFido2Key           = $hasFido2Key
        HasWindowsHello       = $hasWindowsHello
        HasEmailMethod        = $hasEmailMethod
        HasAnyMfaCapable      = $hasAnyMfaCapable
    }
}

Write-Host "Exporting authentication methods report to $OutputPath ..." -ForegroundColor Cyan

try {
    $results | Export-Csv -Path $OutputPath -NoTypeInformation -Encoding UTF8
    Write-Host "Report created successfully." -ForegroundColor Green
    Write-Host "Total users exported: $($results.Count)"
}
catch {
    Write-Host "Failed to export report. Check path and permissions." -ForegroundColor Red
    throw
}

