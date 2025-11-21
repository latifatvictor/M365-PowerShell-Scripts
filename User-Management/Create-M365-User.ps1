<#
.SYNOPSIS
Creates a new Microsoft 365 user in Microsoft Entra ID using Microsoft Graph.

.DESCRIPTION
This script connects to Microsoft Graph, creates a new user with a temporary password
and optionally assigns a licence if a SkuId is provided.

.PARAMETER FirstName
First name of the user.

.PARAMETER LastName
Last name of the user.

.PARAMETER UserPrincipalName
User principal name for the new account (for example user@contoso.onmicrosoft.com).

.PARAMETER UsageLocation
Two letter country code, for example GB or US. Required for licence assignment.

.PARAMETER TemporaryPassword
Temporary password given to the new user.

.PARAMETER SkuId
Optional. The SkuId of the licence to assign. If not provided, no licence is assigned.

.EXAMPLE
.\Create-M365-User.ps1 -FirstName "Alex" -LastName "Smith" -UserPrincipalName "alex.smith@contoso.onmicrosoft.com" -UsageLocation "GB" -TemporaryPassword "P@ssword123!" -SkuId "c42b9cae-ea4f-4ab7-9717-81576235ccac"
#>

param (
    [Parameter(Mandatory = $true)]
    [string]$FirstName,

    [Parameter(Mandatory = $true)]
    [string]$LastName,

    [Parameter(Mandatory = $true)]
    [string]$UserPrincipalName,

    [Parameter(Mandatory = $true)]
    [string]$UsageLocation,

    [Parameter(Mandatory = $true)]
    [string]$TemporaryPassword,

    [Parameter(Mandatory = $false)]
    [string]$SkuId
)

Write-Host "Connecting to Microsoft Graph..." -ForegroundColor Cyan

# Connect to Microsoft Graph with the right scopes
Connect-MgGraph -Scopes "User.ReadWrite.All","Directory.ReadWrite.All","Directory.AccessAsUser.All"

# Build display name and mail nickname
$displayName = "$FirstName $LastName"
$mailNickname = ($FirstName.Substring(0,1) + $LastName).ToLower()

$passwordProfile = @{
    ForceChangePasswordNextSignIn = $true
    Password                       = $TemporaryPassword
}

Write-Host "Creating user $displayName..." -ForegroundColor Cyan

$newUserParams = @{
    AccountEnabled  = $true
    DisplayName     = $displayName
    MailNickname    = $mailNickname
    UserPrincipalName = $UserPrincipalName
    PasswordProfile = $passwordProfile
    UsageLocation   = $UsageLocation
}

$newUser = New-MgUser -BodyParameter $newUserParams

Write-Host "User created successfully:"
Write-Host "DisplayName: $($newUser.DisplayName)"
Write-Host "UPN:         $($newUser.UserPrincipalName)"
Write-Host "Id:          $($newUser.Id)" -ForegroundColor Green

if ($SkuId) {
    Write-Host "Assigning licence $SkuId to user..." -ForegroundColor Cyan

    $addLicences = @(
        @{
            SkuId = $SkuId
        }
    )

    $removeLicences = @()

    Set-MgUserLicense -UserId $newUser.Id -AddLicenses $addLicences -RemoveLicenses $removeLicences

    Write-Host "Licence assignment requested." -ForegroundColor Green
}
else {
    Write-Host "No SkuId provided. Licence assignment skipped." -ForegroundColor Yellow
}

Write-Host "Script complete." -ForegroundColor Cyan
