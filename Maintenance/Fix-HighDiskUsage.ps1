<#
.SYNOPSIS
Identifica cosa consuma spazio disco

.DESCRIPTION
Analizza il disco e trova:
- Cartelle più grandi
- File grandi (>100MB)
- Spazio libero disponibile
- Raccomandazioni di pulizia

.EXAMPLE
.\Fix-HighDiskUsage.ps1

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
Write-Host "ANALISI UTILIZZO DISCO" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Yellow

# Spazio totale disco C:
Write-Host "`n--- SPAZIO DISCO C: ---" -ForegroundColor Cyan
$diskInfo = Get-Volume | Where-Object {$_.DriveLetter -eq 'C'}
$totalGB = [math]::Round($diskInfo.Size / 1GB, 2)
$freeGB = [math]::Round($diskInfo.SizeRemaining / 1GB, 2)
$usedGB = $totalGB - $freeGB
$percentUsed = [math]::Round(($usedGB / $totalGB) * 100, 2)

Write-Host "Totale: $totalGB GB"
Write-Host "Usato: $usedGB GB ($percentUsed%)"
Write-Host "Libero: $freeGB GB"

# Cartelle grandi
Write-Host "`n--- CARTELLE PIU' GRANDI ---" -ForegroundColor Cyan
$folders = @(
    "C:\Windows",
    "C:\Program Files",
    "C:\Program Files (x86)",
    "C:\Users",
    "C:\ProgramData"
)

foreach ($folder in $folders) {
    if (Test-Path $folder) {
        $size = (Get-ChildItem -Path $folder -Recurse -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
        $sizeGB = [math]::Round($size / 1GB, 2)
        Write-Host "$folder: $sizeGB GB"
    }
}

# File grandi (>100MB)
Write-Host "`n--- FILE GRANDI (>100MB) ---" -ForegroundColor Cyan
Get-ChildItem -Path "C:\" -Recurse -ErrorAction SilentlyContinue -File | 
    Where-Object {$_.Length -gt 100MB} | 
    Select-Object @{N='Size(MB)';E={[math]::Round($_.Length/1MB,2)}}, FullName | 
    Sort-Object 'Size(MB)' -Descending | 
    Select-Object -First 10 | 
    Format-Table -AutoSize

Write-Host "`n========================================" -ForegroundColor Green
Write-Host "Analisi completata!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
