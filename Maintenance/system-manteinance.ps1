<#
.SYNOPSIS
Manutenzione sistema completa (CHKDSK, SFC, DISM)

.DESCRIPTION
Esegue sequenzialmente tutti i controlli di integrità del sistema:
1. CHKDSK - Controlla errori disco
2. SFC - Ripara file sistema corrotti
3. DISM - Ripara immagine Windows

Richiede riavvio del PC alla fine.

.EXAMPLE
.\System-Maintenance.ps1

.NOTES
Author: Ivano Frau - CFVA
Version: 1.0
Requires: Administrator privileges
Requires: Restart after execution
#>

if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "Errore: Esegui come Amministratore!" -ForegroundColor Red
    Exit
}

Write-Host "========================================" -ForegroundColor Yellow
Write-Host "MANUTENZIONE SISTEMA COMPLETA" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Yellow

# 1. CHKDSK
Write-Host "`n[1/3] Esecuzione CHKDSK..." -ForegroundColor Cyan
chkdsk C: /F /R /X
Write-Host "CHKDSK completato!" -ForegroundColor Green

# 2. SFC (System File Checker)
Write-Host "`n[2/3] Esecuzione SFC (System File Checker)..." -ForegroundColor Cyan
sfc /scannow
Write-Host "SFC completato!" -ForegroundColor Green

# 3. DISM (Deployment Image Servicing and Management)
Write-Host "`n[3/3] Esecuzione DISM..." -ForegroundColor Cyan
DISM /Online /Cleanup-Image /RestoreHealth
Write-Host "DISM completato!" -ForegroundColor Green

Write-Host "`n========================================" -ForegroundColor Green
Write-Host "Manutenzione completata!" -ForegroundColor Green
Write-Host "Il PC si riavvierà tra 30 secondi..." -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Green

Start-Sleep -Seconds 30
Restart-Computer -Force
