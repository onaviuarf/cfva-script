<#
.SYNOPSIS
Reset completo configurazione di rete

.DESCRIPTION
Resetta completamente la rete a stato base:
- Rilascia/rinnova IP DHCP
- Svuota cache DNS
- Reset stack TCP/IP
- Reset Winsock
- Ripulisce ARP cache
- Reset NetBIOS
- Abilita DHCP da zero

Soluzione nucleare per problemi persistenti di rete.

.EXAMPLE
.\Reset-Network.ps1

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

Write-Host "========================================" -ForegroundColor Red
Write-Host "RESET COMPLETO RETE" -ForegroundColor Red
Write-Host "Questo ripristinerà la rete a stato base!" -ForegroundColor Red
Write-Host "========================================" -ForegroundColor Red

$confirm = Read-Host "`nSei sicuro? Digita 'si' per continuare"
if ($confirm -ne "si") {
    Write-Host "Operazione annullata." -ForegroundColor Yellow
    Exit
}

Write-Host "`nReset in corso..." -ForegroundColor Yellow

# 1. Rilascia e rinnova IP
Write-Host "`n[1/8] Rilascio/Rinnovo IP..." -ForegroundColor Cyan
ipconfig /release
Start-Sleep -Seconds 2
ipconfig /renew
Write-Host "  ✓ IP rilasciato e rinnovato"

# 2. Flush DNS
Write-Host "`n[2/8] Svuotamento cache DNS..." -ForegroundColor Cyan
ipconfig /flushdns
Write-Host "  ✓ Cache DNS svuotato"

# 3. Reset Winsock
Write-Host "`n[3/8] Reset Winsock..." -ForegroundColor Cyan
netsh winsock reset
Write-Host "  ✓ Winsock resettato"

# 4. Reset TCP/IP stack
Write-Host "`n[4/8] Reset stack TCP/IP..." -ForegroundColor Cyan
netsh int ip reset
Write-Host "  ✓ TCP/IP resettato"

# 5. Reset IPv6
Write-Host "`n[5/8] Reset IPv6..." -ForegroundColor Cyan
netsh int ipv6 reset
Write-Host "  ✓ IPv6 resettato"

# 6. Pulisci ARP cache
Write-Host "`n[6/8] Pulizia ARP cache..." -ForegroundColor Cyan
arp -d *
Write-Host "  ✓ ARP cache pulito"

# 7. Reset NetBIOS
Write-Host "`n[7/8] Reset NetBIOS..." -ForegroundColor Cyan
nbtstat -R
nbtstat -RR
Write-Host "  ✓ NetBIOS resettato"

# 8. Abilita DHCP
Write-Host "`n[8/8] Abilitazione DHCP..." -ForegroundColor Cyan
Start-Service Dhcp -ErrorAction SilentlyContinue
Set-Service Dhcp -StartupType Automatic
Write-Host "  ✓ DHCP abilitato"

Write-Host "`n========================================" -ForegroundColor Green
Write-Host "Reset completato!" -ForegroundColor Green
Write-Host "Il PC si riavvierà tra 30 secondi..." -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Green

Start-Sleep -Seconds 30
Restart-Computer -Force
