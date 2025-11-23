<#
.SYNOPSIS
Helper script to connect to Microsoft Graph.

.DESCRIPTION
Provides a reusable function to connect to Microsoft Graph with a standard or custom set of scopes.
Can be dot sourced from other scripts so that connection logic is centralised.

.EXAMPLE
. "$PSScriptRoot\Connect-Graph.ps1"
Connect-LatiGraph

.EXAMPLE
Connect-LatiGraph -Scopes "User.Read.All","Policy.Read.All"
#>

function Connect-LatiGraph {
    [CmdletBinding()]
    param (
        # Custom scopes can be passed in if needed
        [string[]]$Scopes = @(
            "User.Read.All",
            "User.ReadWrite.All",
            "Directory.Read.All",
            "Directory.ReadWrite.All"
        )
    )

    Write-Host "Checking Microsoft.Graph module..." -ForegroundColor Cyan

    if (-not (Get-Module -ListAvailable -Name Microsoft.Graph)) {
        Write-Host "Microsoft.Graph module not found. Install it with:" -ForegroundColor Yellow
        Write-Host "Install-Module Microsoft.Graph -Scope CurrentUser" -ForegroundColor Yellow
        throw "Microsoft.Graph module is not installed."
    }

    Write-Host "Connecting to Microsoft Graph with scopes:" -ForegroundColor Cyan
    Write-Host ($Scopes -join ", ") -ForegroundColor DarkCyan

    try {
        Connect-MgGraph -Scopes $Scopes -ErrorAction Stop
        $context = Get-MgContext
        Write-Host "Connected to Microsoft Graph as $($context.Account)" -ForegroundColor Green
    }
    catch {
        Write-Host "Failed to connect to Microsoft Graph. Check permissions, scopes and network connectivity." -ForegroundColor Red
        throw
    }
}
