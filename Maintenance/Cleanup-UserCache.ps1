<#
.SYNOPSIS
Pulizia cache profili utente

.DESCRIPTION
Pulisce cache e file temporanei dai profili utente:
- AppData\Local\Temp
- AppData\Local\Cache
- AppData\Roaming\Microsoft\Windows\Recent
- Chrome/Firefox cache (se presenti)

.EXAMPLE
.\Cleanup-UserCache.ps1

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
Write-Host "PULIZIA CACHE PROFILI UTENTE" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Yellow

$profilePath = "C:\Users"
$cleanedSize = 0

Get-ChildItem -Path $profilePath -Directory | ForEach-Object {
    $user = $_.Name
    Write-Host "`nPulizia profilo: $user" -ForegroundColor Cyan
    
    # Temp folder
    $tempPath = "$profilePath\$user\AppData\Local\Temp"
    if (Test-Path $tempPath) {
        Remove-Item "$tempPath\*" -Recurse -Force -ErrorAction SilentlyContinue
        Write-Host "  ✓ AppData\Local\Temp pulito"
    }
    
    # Cache folder
    $cachePath = "$profilePath\$user\AppData\Local\Cache"
    if (Test-Path $cachePath) {
        Remove-Item "$cachePath\*" -Recurse -Force -ErrorAction SilentlyContinue
        Write-Host "  ✓ AppData\Local\Cache pulito"
    }
    
    # Roaming cache
    $roamingCachePath = "$profilePath\$user\AppData\Roaming\Cache"
    if (Test-Path $roamingCachePath) {
        Remove-Item "$roamingCachePath\*" -Recurse -Force -ErrorAction SilentlyContinue
        Write-Host "  ✓ AppData\Roaming\Cache pulito"
    }
    
    # Recent files
    $recentPath = "$profilePath\$user\AppData\Roaming\Microsoft\Windows\Recent"
    if (Test-Path $recentPath) {
        Remove-Item "$recentPath\*" -Recurse -Force -ErrorAction SilentlyContinue
        Write-Host "  ✓ Recent files puliti"
    }
    
    # Chrome cache
    $chromeCachePath = "$profilePath\$user\AppData\Local\Google\Chrome\User Data\Default\Cache"
    if (Test-Path $chromeCachePath) {
        Remove-Item "$chromeCachePath\*" -Recurse -Force -ErrorAction SilentlyContinue
        Write-Host "  ✓ Chrome cache pulito"
    }
    
    # Firefox cache
    $firefoxCachePath = "$profilePath\$user\AppData\Local\Mozilla\Firefox\Profiles\*\cache2"
    if (Test-Path $firefoxCachePath) {
        Remove-Item "$firefoxCachePath\*" -Recurse -Force -ErrorAction SilentlyContinue
        Write-Host "  ✓ Firefox cache pulito"
    }
}

Write-Host "`n========================================" -ForegroundColor Green
Write-Host "Pulizia cache completata!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
