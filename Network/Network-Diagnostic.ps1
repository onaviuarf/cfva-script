<#
.SYNOPSIS
Diagnostica rete CFVA con dashboard visuale

.DESCRIPTION
Testa rete e genera HTML con:
- Traffic light system (🔴🟡🟢)
- Alert critici evidenziati
- Colli di bottiglia rilevati
- Raccomandazioni
#>

$sedi = @(
    @{Nome="Ales"; IP="10.128.29.1"},
    @{Nome="Bosa"; IP="10.163.60.1"},
    @{Nome="Cuglieri"; IP="10.128.39.1"},
    @{Nome="Ghilarza"; IP="10.128.90.1"},
    @{Nome="Marrubiu"; IP="10.128.21.1"},
    @{Nome="Neoneli"; IP="10.128.19.1"},
    @{Nome="Samugheo"; IP="10.128.33.1"},
    @{Nome="Seneghe"; IP="10.128.35.1"},
    @{Nome="Villaurbana"; IP="10.128.37.1"},
    @{Nome="Fenosu"; IP="10.128.15.1"},
    @{Nome="Santa Maria"; IP="10.160.13.1"},
    @{Nome="BLON"; IP="10.128.41.1"},
    @{Nome="STIR"; IP="10.128.9.1"},
    @{Nome="Cualbu"; IP="10.128.25.1"}
)

$dc = @("192.168.224.114", "192.168.224.115")
$dns = @("192.168.224.114", "192.168.224.115")
$alerts = @()
$sedeResults = @()
$dcResults = @()

Write-Host "Diagnostica in corso..." -ForegroundColor Yellow

# Test sedi
foreach ($sede in $sedi) {
    $ping = Test-Connection -ComputerName $sede.IP -Count 1 -ErrorAction SilentlyContinue
    $smb = Test-NetConnection -ComputerName $sede.IP -Port 445 -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
    
    if ($ping) {
        $status = "ONLINE"
        $latency = $ping.ResponseTime
        $smbStatus = if ($smb.TcpTestSucceeded) { "OK" } else { "FAIL" }
        $severity = if ($latency -gt 100) { "WARNING" } elseif ($latency -gt 200) { "CRITICAL" } else { "OK" }
    } else {
        $status = "OFFLINE"
        $latency = "N/A"
        $smbStatus = "FAIL"
        $severity = "CRITICAL"
        $alerts += "🔴 CRITICO: Sede $($sede.Nome) OFFLINE - Impossibile raggiungere gateway"
    }
    
    if ($latency -gt 100 -and $latency -ne "N/A") {
        $alerts += "⚠️ WARNING: Sede $($sede.Nome) - Latenza alta ($latency ms)"
    }
    
    $sedeResults += [PSCustomObject]@{
        Sede = $sede.Nome
        IP = $sede.IP
        Status = $status
        Latency = $latency
        SMB = $smbStatus
        Severity = $severity
    }
}

# Test DC/DNS
foreach ($dcServer in $dc) {
    $ping = Test-Connection -ComputerName $dcServer -Count 1 -ErrorAction SilentlyContinue
    $ldap = Test-NetConnection -ComputerName $dcServer -Port 389 -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
    
    if ($ping -and $ldap.TcpTestSucceeded) {
        $status = "ONLINE"
        $severity = "OK"
    } else {
        $status = "OFFLINE"
        $severity = "CRITICAL"
        $alerts += "🔴 CRITICO: Domain Controller $dcServer OFFLINE - Login utenti compromesso!"
    }
    
    $dcResults += [PSCustomObject]@{
        Server = $dcServer
        Status = $status
        LDAP = if ($ldap.TcpTestSucceeded) { "✓" } else { "✗" }
        DNS = if ($ping) { "✓" } else { "✗" }
        Severity = $severity
    }
}

# Genera HTML
$onlineCount = ($sedeResults | Where-Object {$_.Status -eq "ONLINE"}).Count
$criticalCount = ($sedeResults | Where-Object {$_.Severity -eq "CRITICAL"}).Count
$warningCount = ($sedeResults | Where-Object {$_.Severity -eq "WARNING"}).Count

$healthPercent = [math]::Round(($onlineCount / $sedi.Count) * 100)
$healthColor = if ($healthPercent -eq 100) { "#4CAF50" } elseif ($healthPercent -ge 80) { "#FFC107" } else { "#F44336" }

$htmlReport = @"
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>CFVA Network Diagnostic</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { font-family: 'Segoe UI', Arial; background: #f5f5f5; padding: 20px; }
        .container { max-width: 1400px; margin: 0 auto; background: white; padding: 30px; border-radius: 8px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
        
        header { border-bottom: 3px solid #2196F3; padding-bottom: 20px; margin-bottom: 30px; }
        h1 { color: #333; margin-bottom: 5px; }
        .timestamp { color: #999; font-size: 13px; }
        
        .dashboard { display: grid; grid-template-columns: repeat(3, 1fr); gap: 20px; margin-bottom: 30px; }
        .metric { padding: 20px; border-radius: 8px; text-align: center; }
        .metric.critical { background: #FFEBEE; border-left: 5px solid #F44336; }
        .metric.warning { background: #FFF8E1; border-left: 5px solid #FFC107; }
        .metric.ok { background: #E8F5E9; border-left: 5px solid #4CAF50; }
        .metric-value { font-size: 32px; font-weight: bold; margin: 10px 0; }
        .metric-label { color: #666; font-size: 14px; }
        
        .health-bar { width: 100%; height: 40px; background: #eee; border-radius: 20px; overflow: hidden; margin: 15px 0; }
        .health-fill { height: 100%; background: $healthColor; display: flex; align-items: center; justify-content: center; color: white; font-weight: bold; }
        
        .alerts { background: #FFEBEE; border: 2px solid #F44336; border-radius: 8px; padding: 20px; margin-bottom: 30px; }
        .alerts h3 { color: #F44336; margin-bottom: 15px; }
        .alert-item { padding: 10px; margin: 8px 0; background: white; border-left: 4px solid #F44336; border-radius: 4px; }
        
        table { width: 100%; border-collapse: collapse; margin: 20px 0; }
        th { background: #2196F3; color: white; padding: 12px; text-align: left; }
        td { padding: 12px; border-bottom: 1px solid #ddd; }
        tr:hover { background: #f9f9f9; }
        
        .status-online { color: #4CAF50; font-weight: bold; }
        .status-offline { color: #F44336; font-weight: bold; }
        .status-warning { color: #FFC107; font-weight: bold; }
        
        .icon-ok { color: #4CAF50; font-size: 18px; }
        .icon-fail { color: #F44336; font-size: 18px; }
        .icon-warn { color: #FFC107; font-size: 18px; }
        
        .recommendations { background: #E3F2FD; border-left: 4px solid #2196F3; padding: 20px; border-radius: 8px; margin-top: 30px; }
        .recommendations h3 { color: #1976D2; margin-bottom: 10px; }
        .recommendations ul { margin-left: 20px; }
        .recommendations li { margin: 8px 0; color: #333; }
        
        footer { text-align: center; margin-top: 30px; color: #999; font-size: 12px; border-top: 1px solid #eee; padding-top: 20px; }
    </style>
</head>
<body>
    <div class="container">
        <header>
            <h1>🌐 CFVA Network Diagnostic Report</h1>
            <p class="timestamp">Generato: $(Get-Date -Format 'dd/MM/yyyy HH:mm:ss')</p>
        </header>
        
        <!-- DASHBOARD METRICHE -->
        <div class="dashboard">
            <div class="metric ok">
                <div class="metric-label">Sedi Online</div>
                <div class="metric-value">$onlineCount / 14</div>
            </div>
            <div class="metric $(if ($criticalCount -gt 0) {'critical'} else {'ok'})">
                <div class="metric-label">Nodi Critici</div>
                <div class="metric-value">$criticalCount</div>
            </div>
            <div class="metric $(if ($warningCount -gt 0) {'warning'} else {'ok'})">
                <div class="metric-label">Avvisi</div>
                <div class="metric-value">$warningCount</div>
            </div>
        </div>
        
        <!-- HEALTH BAR -->
        <div style="margin-bottom: 30px;">
            <label style="font-weight: bold; display: block; margin-bottom: 10px;">Salute Rete: $healthPercent%</label>
            <div class="health-bar">
                <div class="health-fill" style="width: $healthPercent%">$healthPercent%</div>
            </div>
        </div>
        
        <!-- ALERT CRITICI -->
"@

if ($alerts.Count -gt 0) {
    $htmlReport += @"
        <div class="alerts">
            <h3>⚠️ PROBLEMI RILEVATI</h3>
"@
    foreach ($alert in $alerts) {
        $htmlReport += "<div class='alert-item'>$alert</div>"
    }
    $htmlReport += "</div>"
}

$htmlReport += @"
        <!-- TABELLA SEDI -->
        <h2>📍 Stato Sedi (14 totali)</h2>
        <table>
            <tr>
                <th>Sede</th>
                <th>Gateway IP</th>
                <th>Status</th>
                <th>Latenza</th>
                <th>SMB</th>
                <th>Severità</th>
            </tr>
"@

foreach ($result in $sedeResults) {
    $statusClass = if ($result.Status -eq "ONLINE") { "status-online" } else { "status-offline" }
    $statusIcon = if ($result.Status -eq "ONLINE") { "✓" } else { "✗" }
    $smbIcon = if ($result.SMB -eq "OK") { "<span class='icon-ok'>✓</span>" } else { "<span class='icon-fail'>✗</span>" }
    $sevIcon = if ($result.Severity -eq "CRITICAL") { "🔴" } elseif ($result.Severity -eq "WARNING") { "⚠️" } else { "🟢" }
    
    $htmlReport += @"
            <tr>
                <td>$($result.Sede)</td>
                <td>$($result.IP)</td>
                <td class="$statusClass">$statusIcon $($result.Status)</td>
                <td>$($result.Latency) ms</td>
                <td>$smbIcon</td>
                <td>$sevIcon $($result.Severity)</td>
            </tr>
"@
}

$htmlReport += @"
        </table>
        
        <!-- TABELLA DC -->
        <h2>🔐 Domain Controllers</h2>
        <table>
            <tr>
                <th>Server</th>
                <th>Status</th>
                <th>LDAP</th>
                <th>DNS</th>
                <th>Severity</th>
            </tr>
"@

foreach ($dc in $dcResults) {
    $statusClass = if ($dc.Status -eq "ONLINE") { "status-online" } else { "status-offline" }
    $ldapIcon = if ($dc.LDAP -eq "✓") { "<span class='icon-ok'>✓</span>" } else { "<span class='icon-fail'>✗</span>" }
    $dnsIcon = if ($dc.DNS -eq "✓") { "<span class='icon-ok'>✓</span>" } else { "<span class='icon-fail'>✗</span>" }
    $sevIcon = if ($dc.Severity -eq "CRITICAL") { "🔴" } else { "🟢" }
    
    $htmlReport += @"
            <tr>
                <td>$($dc.Server)</td>
                <td class="$statusClass">$($dc.Status)</td>
                <td>$ldapIcon</td>
                <td>$dnsIcon</td>
                <td>$sevIcon $($dc.Severity)</td>
            </tr>
"@
}

$htmlReport += @"
        </table>
        
        <!-- RACCOMANDAZIONI -->
        <div class="recommendations">
            <h3>💡 Raccomandazioni</h3>
            <ul>
"@

if ($criticalCount -gt 0) {
    $htmlReport += "<li><strong>URGENTE:</strong> Contattare immediatamente le sedi offline per verificare connettività</li>"
}
if ($warningCount -gt 0) {
    $htmlReport += "<li><strong>ATTENZIONE:</strong> Verificare latenza alta - possibile congestione di rete</li>"
}
if (($sedeResults | Where-Object {$_.SMB -eq "FAIL"}).Count -gt 0) {
    $htmlReport += "<li><strong>FILE SERVER:</strong> Alcune sedi non raggiungono file server (SMB port 445)</li>"
}
if (($dcResults | Where-Object {$_.Status -eq "OFFLINE"}).Count -gt 0) {
    $htmlReport += "<li><strong>CRITICO:</strong> Domain Controller offline - Accesso utenti compromesso!</li>"
}
if ($healthPercent -eq 100) {
    $htmlReport += "<li><strong>✓ OTTIMALE:</strong> Tutte le sedi raggiungibili - Rete funzionante</li>"
}

$htmlReport += @"
            </ul>
        </div>
        
        <footer>
            <p>CFVA - Corpo Forestale e di Vigilanza Ambientale</p>
            <p>Diagnostica Rete Automatica - STIR Oristano</p>
            <p>Report generato automaticamente da Network-Diagnostic.ps1</p>
        </footer>
    </div>
</body>
</html>
"@

# Salva
$reportPath = "$env:USERPROFILE\Desktop\CFVA-Network-Diagnostic_$(Get-Date -Format 'yyyyMMdd_HHmmss').html"
$htmlReport | Out-File -FilePath $reportPath -Encoding UTF8

Write-Host "`n✓ Report HTML salvato: $reportPath" -ForegroundColor Green
Start-Process $reportPath
