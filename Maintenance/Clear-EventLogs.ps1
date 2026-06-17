<#
.SYNOPSIS
Pulisce i log di sistema Windows

.DESCRIPTION
Svuota i log di Windows per liberare spazio e velocizzare il sistema:
- System
- Application
- Security
- PowerShell

.EXAMPLE
.\Clear-EventLogs.ps1

.NOTES
Author: Ivano Frau - CFVA
Version: 1.0
Requires: Administrator privileges
#>

if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "Errore: Esegui come Amministratore!" -ForegroundColor Red
    Exit
}

Write-Host "========================================" -ForegroundColor Yellow
Write-Host "PULIZIA LOG SISTEMA" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Yellow

$logNames = @('System', 'Application', 'Security', 'Windows PowerShell')

foreach ($log in $logNames) {
    Write-Host "`nPulizia log: $log" -ForegroundColor Cyan
    try {
        Clear-EventLog -LogName $log -ErrorAction Stop
        Write-Host "  ✓ $log pulito" -ForegroundColor Green
    }
    catch {
        Write-Host "  ✗ Errore pulizia $log : $_" -ForegroundColor Red
    }
}

Write-Host "`n========================================" -ForegroundColor Green
Write-Host "Pulizia log completata!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
