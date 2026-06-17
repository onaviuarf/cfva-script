<#
.SYNOPSIS
Raccoglie informazioni complete del PC

.DESCRIPTION
Genera report completo di:
- Hardware (CPU, RAM, Disco)
- Sistema operativo e versione
- Programmi installati
- Network configuration
- Servizi attivi
- Output salvato in file

.EXAMPLE
.\Get-PCInfo.ps1

.NOTES
Author: Ivano Frau - CFVA
Version: 1.0
#>

$pcName = $env:COMPUTERNAME
$reportPath = "$env:USERPROFILE\Desktop\$pcName-Info.txt"

Write-Host "Raccolta informazioni PC in corso..." -ForegroundColor Yellow

$report = @"
========================================
REPORT PC: $pcName
Data: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
========================================

--- HARDWARE ---
CPU: $(Get-WmiObject Win32_Processor | Select-Object -ExpandProperty Name)
RAM: $([math]::Round((Get-WmiObject Win32_ComputerSystem | Select-Object -ExpandProperty TotalPhysicalMemory) / 1GB)) GB
Disco: $(Get-Volume | Where-Object {$_.DriveLetter -eq 'C'} | Select-Object -ExpandProperty Size | ForEach-Object {[math]::Round($_ / 1GB)}) GB

--- SISTEMA OPERATIVO ---
OS: $(Get-WmiObject Win32_OperatingSystem | Select-Object -ExpandProperty Caption)
Versione: $(Get-WmiObject Win32_OperatingSystem | Select-Object -ExpandProperty Version)
Build: $(Get-WmiObject Win32_OperatingSystem | Select-Object -ExpandProperty BuildNumber)

--- PROGRAMMI INSTALLATI ---
$(Get-WmiObject Win32_Product | Select-Object -ExpandProperty Name | Sort-Object | Out-String)

--- RETE ---
$(Get-NetAdapter | Select-Object Name, Status, Speed | Out-String)

--- SERVIZI CRITICO ---
$(Get-Service | Where-Object {$_.Status -eq 'Running'} | Select-Object Name, DisplayName | Sort-Object Name | Out-String)

========================================
"@

$report | Out-File -FilePath $reportPath -Encoding UTF8
Write-Host "Report salvato in: $reportPath" -ForegroundColor Green
Write-Host "Fatto!" -ForegroundColor Green
