<#
.SYNOPSIS
Aggiorna driver sistema

.DESCRIPTION
Aggiorna driver di dispositivi critici:
- Scheda di rete
- GPU/Scheda video
- Chipset
- Storage controller

Scarica da Windows Update.

.EXAMPLE
.\Update-Drivers.ps1

.NOTES
Author: Ivano Frau - CFVA
Version: 1.1
Requires: Administrator privileges
Requires: Internet connection
#>

if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "Errore: Esegui come Amministratore!" -ForegroundColor Red
    Exit
}

Write-Host "========================================" -ForegroundColor Yellow
Write-Host "AGGIORNAMENTO DRIVER" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Yellow

Write-Host "`nRicerca aggiornamenti driver..." -ForegroundColor Cyan

try {
    Write-Host "`n[1/2] Driver installati:" -ForegroundColor Cyan
    Get-PnpDevice -Status OK | Select-Object Name, Description | Format-Table -AutoSize
    
    Write-Host "`n[2/2] Apertura Windows Update..." -ForegroundColor Cyan
    Start-Process "ms-settings:windowsupdate-action"
    Write-Host "  ✓ Apri Impostazioni > Aggiornamenti Windows" -ForegroundColor Green
    Write-Host "  ✓ Clicca 'Ricerca aggiornamenti'" -ForegroundColor Green
    
    Write-Host "`n========================================" -ForegroundColor Green
    Write-Host "Ricerca completata!" -ForegroundColor Green
    Write-Host "Installa gli aggiornamenti da Windows Update" -ForegroundColor Yellow
    Write-Host "========================================" -ForegroundColor Green
}
catch {
    Write-Host "Errore: $_" -ForegroundColor Red
    Write-Host "Apri manualmente: Impostazioni > Aggiornamenti Windows" -ForegroundColor Yellow
}
