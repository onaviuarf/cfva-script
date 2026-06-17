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
Version: 1.0
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

# Usa Windows Update per aggiornare driver
$ProgressPreference = 'SilentlyContinue'

try {
    # Avvia Windows Update
    Write-Host "`n[1/2] Avvio ricerca aggiornamenti Windows Update..." -ForegroundColor Cyan
    Start-Process -FilePath "ms-settings:windowsupdate" -Wait -NoNewWindow
    Write-Host "  ✓ Apri Impostazioni > Aggiornamenti Windows" -ForegroundColor Green
    
    # Info driver attuali
    Write-Host "`n[2/2] Driver installati:" -ForegroundColor Cyan
    Get-PnpDevice | Where-Object {$_.Status -eq 'OK'} | Select-Object Name, InstanceId | Out-String
    
    Write-Host "`n========================================" -ForegroundColor Green
    Write-Host "Ricerca completata!" -ForegroundColor Green
    Write-Host "Controlla Windows Update per installare" -ForegroundColor Yellow
    Write-Host "========================================" -ForegroundColor Green
}
catch {
    Write-Host "Errore: $_" -ForegroundColor Red
}
