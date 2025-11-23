# Authentication Methods Scripts

PowerShell scripts to review and report on user authentication methods such as MFA and passwordless options.

- `Get-AuthenticationMethodsReport.ps1`  
  Retrieves authentication methods for all users via Microsoft Graph and exports a report showing who has Microsoft Authenticator, phone methods, FIDO2 keys, Windows Hello and MFA-capable methods. Useful for MFA coverage checks and identity security audits.
