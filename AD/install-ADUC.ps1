<#
.SYNOPSIS
Installa RSAT (Active Directory Users and Computers)

.DESCRIPTION
Installa automaticamente gli strumenti RSAT necessari per gestire Active Directory da PC client.
Esegui su un PC nuovo per avere ADUC disponibile.

.EXAMPLE
.\Install-ADUC.ps1

.NOTES
Author: Ivano Frau - CFVA
Version: 1.0
Requires: Administrator privileges
#>

if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "Errore: Esegui come Amministratore!" -ForegroundColor Red
    Exit
}

Write-Host "Installazione RSAT Active Directory..." -ForegroundColor Yellow
Add-WindowsCapability -Online -Name "Rsat.ActiveDirectory.DS-LDS.Tools~~~~0.0.1.0" -WarningAction SilentlyContinue

Write-Host "`nCompleto! Apri ADUC con: dsa.msc" -ForegroundColor Green
