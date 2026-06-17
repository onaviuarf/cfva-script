<#
.SYNOPSIS
Configura IP statico e blocca DHCP

.DESCRIPTION
Imposta indirizzo IP statico, gateway e DNS, disabilitando completamente DHCP.
Utile per PC Lenovo che forzano DHCP automaticamente.

.PARAMETER IPAddress
Indirizzo IP statico (es: 10.128.9.253)

.PARAMETER Gateway
Gateway della rete (es: 10.128.9.1)

.PARAMETER DNS1
Server DNS primario (es: 192.168.224.114)

.PARAMETER DNS2
Server DNS secondario (es: 192.168.224.115)

.EXAMPLE
.\Set-StaticIP.ps1 -IPAddress "10.128.9.253" -Gateway "10.128.9.1" -DNS1 "192.168.224.114" -DNS2 "192.168.224.115"

.NOTES
Author: Ivano Frau - CFVA
Version: 1.0
Requires: Administrator privileges
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$IPAddress,
    
    [Parameter(Mandatory=$true)]
    [string]$Gateway,
    
    [Parameter(Mandatory=$true)]
    [string]$DNS1,
    
    [Parameter(Mandatory=$true)]
    [string]$DNS2
)

if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "Errore: Esegui come Amministratore!" -ForegroundColor Red
    Exit
}

# Identifica adapter Ethernet
$adapter = (Get-NetAdapter | Where-Object {$_.Status -eq "Up" -and $_.PhysicalMediaType -eq "802.3"}).Name

if (-not $adapter) {
    Write-Host "Errore: Nessun adapter Ethernet trovato!" -ForegroundColor Red
    Exit
}

Write-Host "========================================" -ForegroundColor Yellow
Write-Host "CONFIGURAZIONE IP STATICO" -ForegroundColor Yellow
Write-Host "Adapter: $adapter" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Yellow

# Disabilita servizi Lenovo di rete
Write-Host "`n[1/6] Disabilitazione servizi Lenovo..." -ForegroundColor Cyan
Get-Service | Where-Object {$_.DisplayName -like "*Lenovo*Network*"} | ForEach-Object {
    Stop-Service $_.Name -Force -ErrorAction SilentlyContinue
    Set-Service $_.Name -StartupType Disabled
    Write-Host "  ✓ $($_.Name) disabilitato"
}

# Disabilita risparmio energetico scheda
Write-Host "`n[2/6] Disabilitazione risparmio energetico..." -ForegroundColor Cyan
Set-NetAdapterPowerManagement -Name $adapter -SelectiveSuspend Disabled -DeviceSleepOnDisconnect Disabled -ErrorAction SilentlyContinue
Write-Host "  ✓ Risparmio energetico disabilitato"

# Rimuovi IP esistenti
Write-Host "`n[3/6] Rimozione configurazione DHCP..." -ForegroundColor Cyan
Get-NetIPAddress -InterfaceAlias $adapter -AddressFamily IPv4 -ErrorAction SilentlyContinue | Remove-NetIPAddress -Confirm:$false
Get-NetRoute -InterfaceAlias $adapter -AddressFamily IPv4 -ErrorAction SilentlyContinue | Remove-NetRoute -Confirm:$false
Write-Host "  ✓ Configurazione precedente rimossa"

# Disabilita DHCP servizio
Write-Host "`n[4/6] Disabilitazione servizio DHCP..." -ForegroundColor Cyan
Stop-Service Dhcp -Force -ErrorAction SilentlyContinue
Set-Service Dhcp -StartupType Disabled
Write-Host "  ✓ Servizio DHCP disabilitato"

# Imposta IP statico
Write-Host "`n[5/6] Configurazione IP statico..." -ForegroundColor Cyan
New-NetIPAddress -InterfaceAlias $adapter -IPAddress $IPAddress -PrefixLength 24 -DefaultGateway $Gateway
Set-DnsClientServerAddress -InterfaceAlias $adapter -ServerAddresses $DNS1, $DNS2
Write-Host "  ✓ IP statico: $IPAddress"
Write-Host "  ✓ Gateway: $Gateway"
Write-Host "  ✓ DNS: $DNS1, $DNS2"

# Blocca DHCP nel registro
Write-Host "`n[6/6] Blocco DHCP nel registro..." -ForegroundColor Cyan
$guid = (Get-NetAdapter -Name $adapter).InterfaceGuid
$regPath = "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces\$guid"
Set-ItemProperty -Path $regPath -Name "EnableDHCP" -Value 0 -Type DWord
Write-Host "  ✓ DHCP bloccato nel registro"

Write-Host "`n========================================" -ForegroundColor Green
Write-Host "Configurazione completata!" -ForegroundColor Green
Write-Host "Verifica con: ipconfig /all" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Green
