<#
.SYNOPSIS
Ottimizzazione sistema (Defrag, Cleanup temp, DNS cache)

.DESCRIPTION
Esegue ottimizzazioni di performance:
1. Defragmentazione/Ottimizzazione disco
2. Pulizia file temporanei
3. Svuota cache DNS
4. Pulisci Prefetch
5. Pulisci Windows Update cache

.EXAMPLE
.\System-Optimize.ps1

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
Write-Host "OTTIMIZZAZIONE SISTEMA" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Yellow

# 1. Ottimizza disco (Defrag)
Write-Host "`n[1/5] Ottimizzazione disco C:..." -ForegroundColor Cyan
Optimize-Volume -DriveLetter C -Defrag -Verbose:$false
Write-Host "Disco ottimizzato!" -ForegroundColor Green

# 2. Pulizia temp files
Write-Host "`n[2/5] Pulizia file temporanei..." -ForegroundColor Cyan
Remove-Item "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item "C:\Windows\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue
Write-Host "File temporanei puliti!" -ForegroundColor Green

# 3. Svuota cache DNS
Write-Host "`n[3/5] Svuotamento cache DNS..." -ForegroundColor Cyan
ipconfig /flushdns | Out-Null
Write-Host "Cache DNS svuotato!" -ForegroundColor Green

# 4. Pulisci Prefetch
Write-Host "`n[4/5] Pulizia Prefetch..." -ForegroundColor Cyan
Remove-Item "C:\Windows\Prefetch\*" -Recurse -Force -ErrorAction SilentlyContinue
Write-Host "Prefetch pulito!" -ForegroundColor Green

# 5. Pulisci Windows Update cache
Write-Host "`n[5/5] Pulizia Windows Update cache..." -ForegroundColor Cyan
Remove-Item "C:\Windows\SoftwareDistribution\Download\*" -Recurse -Force -ErrorAction SilentlyContinue
Write-Host "Windows Update cache pulito!" -ForegroundColor Green

Write-Host "`n========================================" -ForegroundColor Green
Write-Host "Ottimizzazione completata!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
