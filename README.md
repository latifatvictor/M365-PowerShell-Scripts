# Microsoft 365 PowerShell Scripts
This repository contains PowerShell scripts that I have written as part of my Microsoft 365 identity and security learning journey.

These scripts help automate common identity, reporting and administration tasks in Microsoft Entra ID and Microsoft 365.

---

## Scripts Included

### User and Group Management
• Create a Microsoft 365 user  
• Bulk user creation template  
• List all groups in Entra ID  
• Add and remove group members  

---

### Identity and Authentication Reporting
• Export Entra sign in logs  
• Export audit logs  
• Report on Conditional Access policies  
• List authentication methods per user  

---

### Licence and Role Management
• Assign licences to users in bulk  
• List all users with missing licences  
• Check PIM eligible assignments  
• Get role assignments for admins  

---

## Skills Demonstrated
• PowerShell for cloud administration  
• Microsoft Graph basics  
• Automating Microsoft 365 tasks  
• Identity reporting  
• Conditional Access auditing  
• Working with modules such as MSOnline, AzureAD and Microsoft Graph  

---

## Notes
These scripts are created for study and demonstration purposes. They will grow in complexity as my automation skills improve.

## ⚠ How To Run These Scripts Safely

These scripts are designed for learning, lab and demonstration purposes. To use them safely:

1. Use a test or lab tenant  
   Run these scripts in a non production Microsoft 365 tenant wherever possible.

2. Review the script before running it  
   Always read through the code to understand what it does, especially where it creates, updates or deletes objects.

3. Use least privilege  
   Only grant the Graph permissions and roles that are required. Avoid using highly privileged accounts unless necessary.

4. Start with read only scripts  
   Begin with reporting scripts (for example user reports, Conditional Access reports, PIM reports) before using scripts that make changes.

5. Log and document changes  
   When running scripts that modify configuration, keep a record of what was run and in which environment.

6. Secure your credentials  
   Do not hard code passwords, secrets or client credentials in scripts. Use secure methods such as interactive sign in, managed identities or secure vaults in real environments.

These scripts are part of my learning journey in Microsoft 365 security, identity and cloud automation. They should be adapted and reviewed carefully before any production use.

