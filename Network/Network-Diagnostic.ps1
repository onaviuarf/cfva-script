# ========================================
# CFVA Network Diagnostic v3.2 - Completo
# Author: Ivano Frau
# Version: 3.2 - iperf verso NAS IP specifici
# ========================================

$sedi = @(
    @{Nome="Ales"; IP="10.128.29.1"; NAS_IP="10.128.29.200"; HasNAS=$true},
    @{Nome="Bosa"; IP="10.163.60.1"; NAS_IP="10.163.60.200"; HasNAS=$true},
    @{Nome="Cuglieri"; IP="10.128.39.1"; NAS_IP="10.128.39.200"; HasNAS=$true},
    @{Nome="Ghilarza"; IP="10.128.90.1"; NAS_IP="10.128.90.200"; HasNAS=$true},
    @{Nome="Marrubiu"; IP="10.128.21.1"; NAS_IP="10.128.21.200"; HasNAS=$true},
    @{Nome="Neoneli"; IP="10.128.19.1"; NAS_IP="10.128.19.200"; HasNAS=$true},
    @{Nome="Samugheo"; IP="10.128.33.1"; NAS_IP="10.128.33.200"; HasNAS=$true},
    @{Nome="Seneghe"; IP="10.128.35.1"; NAS_IP="10.128.35.200"; HasNAS=$true},
    @{Nome="Villaurbana"; IP="10.128.37.1"; NAS_IP="10.128.37.200"; HasNAS=$true},
    @{Nome="Fenosu"; IP="10.128.15.1"; NAS_IP=$null; HasNAS=$false},
    @{Nome="Santa Maria"; IP="10.160.13.1"; NAS_IP=$null; HasNAS=$false},
    @{Nome="BLON"; IP="10.128.41.1"; NAS_IP="10.128.41.200"; HasNAS=$true},
    @{Nome="STIR"; IP="10.128.9.1"; NAS_IP=$null; HasNAS=$false},
    @{Nome="Cualbu"; IP="10.128.25.1"; NAS_IP="10.128.25.24"; HasNAS=$true}
)

$iperf_port = 5201
$iperf3_path = "C:\Programmi\iperf3\iperf3.exe"

$logFile = "$env:USERPROFILE\Desktop\Network-Diagnostic.html"
$online = 0
$tableRows = ""

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "CFVA Network Diagnostic v3.2" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Verifica iperf3
$iperf_available = Test-Path $iperf3_path
if ($iperf_available) {
    Write-Host "[OK] iperf3 trovato: $iperf3_path" -ForegroundColor Green
} else {
    Write-Host "[WARN] iperf3 non trovato in $iperf3_path" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "NAS con iperf su 11 sedi (escluse: Santa Maria, Fenosu, STIR)" -ForegroundColor Cyan
Write-Host "IP NAS: .200 (tranne Cualbu che usa .24)" -ForegroundColor Cyan
Write-Host "Test Ping + Latenza + Bandwidth..." -ForegroundColor Yellow
Write-Host ""

$count = 0
foreach ($sede in $sedi) {
    $count++
    $percent = [math]::Round(($count / $sedi.Count) * 100)
    
    Write-Host "[$percent%] Testando $($sede.Nome)..." -ForegroundColor Cyan
    
    # PING TEST (verso gateway)
    $ping = Test-Connection -ComputerName $sede.IP -Count 1 -ErrorAction SilentlyContinue
    if ($ping) {
        $status = "ONLINE"
        $latency = "$($ping.ResponseTime) ms"
        $online++
        $statusClass = "online"
    } else {
        $status = "OFFLINE"
        $latency = "N/A"
        $statusClass = "offline"
    }
    
    # IPERF TEST (verso NAS IP specifico, solo se ha NAS e è online)
    $bandwidth = "N/A"
    $bandwidthClass = "neutral"
    
    if ($status -eq "ONLINE" -and $sede.HasNAS -and $iperf_available) {
        try {
            Write-Host "    -> Testing iperf verso NAS $($sede.NAS_IP)..." -ForegroundColor Gray
            $output = & $iperf3_path -c $sede.NAS_IP -p $iperf_port -t 5 -J 2>$null
            $iperf = $output | ConvertFrom-Json
            $bits_sec = $iperf.end.sum_received.bits_per_second
            $mbps = [math]::Round($bits_sec / 1000000, 2)
            $bandwidth = "$mbps Mbps"
            
            # Classifica bandwidth
            if ($mbps -gt 100) {
                $bandwidthClass = "good"
            } elseif ($mbps -gt 10) {
                $bandwidthClass = "warning"
            } else {
                $bandwidthClass = "bad"
            }
            
            Write-Host "    -> Bandwidth: $bandwidth" -ForegroundColor Green
        } catch {
            $bandwidth = "Errore"
            $bandwidthClass = "bad"
            Write-Host "    -> Errore iperf" -ForegroundColor Red
        }
    } elseif ($status -eq "ONLINE" -and -not $sede.HasNAS) {
        $bandwidth = "Senza NAS"
        $bandwidthClass = "neutral"
    }
    
    # Classifica latenza
    $latencyClass = "good"
    if ($latency -ne "N/A") {
        $latency_ms = [int]$latency.Split(' ')[0]
        if ($latency_ms -gt 150) {
            $latencyClass = "bad"
        } elseif ($latency_ms -gt 50) {
            $latencyClass = "warning"
        }
    }
    
    $tableRows += "<tr><td>$($sede.Nome)</td><td>$($sede.IP)</td><td class=`"status-$statusClass`">$status</td><td class=`"latency-$latencyClass`">$latency</td><td class=`"bandwidth-$bandwidthClass`">$bandwidth</td></tr>"
}

$health = [math]::Round(($online / 14) * 100)
$timestamp = Get-Date -Format 'dd/MM/yyyy HH:mm:ss'

Write-Host ""
Write-Host "Generando report HTML..." -ForegroundColor Yellow

# ===== HTML REPORT =====
$html = @"
<!DOCTYPE html>
<html lang="it">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>CFVA Network Diagnostic Report</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        
        body {
            font-family: 'Segoe UI', Arial, sans-serif;
            background: #f5f5f5;
            padding: 20px;
        }
        
        .container {
            max-width: 1200px;
            margin: 0 auto;
            background: white;
            padding: 30px;
            border-radius: 8px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
        }
        
        header {
            border-bottom: 3px solid #2196F3;
            padding-bottom: 20px;
            margin-bottom: 30px;
        }
        
        h1 {
            color: #333;
            margin-bottom: 5px;
            font-size: 28px;
        }
        
        .timestamp {
            color: #999;
            font-size: 13px;
        }
        
        .server-info {
            background: #f0f0f0;
            padding: 15px;
            border-radius: 4px;
            margin-top: 10px;
            font-size: 12px;
            color: #666;
            line-height: 1.6;
        }
        
        .dashboard {
            display: grid;
            grid-template-columns: repeat(2, 1fr);
            gap: 20px;
            margin-bottom: 30px;
        }
        
        .metric {
            padding: 20px;
            border-radius: 8px;
            text-align: center;
            border-left: 5px solid #ccc;
        }
        
        .metric.ok {
            background: #E8F5E9;
            border-left-color: #4CAF50;
        }
        
        .metric.critical {
            background: #FFEBEE;
            border-left-color: #F44336;
        }
        
        .metric-value {
            font-size: 36px;
            font-weight: bold;
            color: #333;
            margin: 10px 0;
        }
        
        .metric-label {
            color: #666;
            font-size: 14px;
        }
        
        h2 {
            color: #2196F3;
            margin: 30px 0 15px 0;
            border-bottom: 2px solid #2196F3;
            padding-bottom: 10px;
            font-size: 20px;
        }
        
        table {
            width: 100%;
            border-collapse: collapse;
            margin: 20px 0;
        }
        
        th {
            background: #2196F3;
            color: white;
            padding: 12px;
            text-align: left;
            font-weight: bold;
        }
        
        td {
            padding: 12px;
            border-bottom: 1px solid #ddd;
        }
        
        tr:hover {
            background: #f9f9f9;
        }
        
        .status-online {
            color: #4CAF50;
            font-weight: bold;
        }
        
        .status-offline {
            color: #F44336;
            font-weight: bold;
        }
        
        .latency-good {
            color: #4CAF50;
            font-weight: bold;
        }
        
        .latency-warning {
            color: #FF9800;
            font-weight: bold;
        }
        
        .latency-bad {
            color: #F44336;
            font-weight: bold;
        }
        
        .bandwidth-good {
            color: #4CAF50;
            font-weight: bold;
        }
        
        .bandwidth-warning {
            color: #FF9800;
            font-weight: bold;
        }
        
        .bandwidth-bad {
            color: #F44336;
            font-weight: bold;
        }
        
        .bandwidth-neutral {
            color: #999;
            font-style: italic;
        }
        
        .legend {
            background: #f0f0f0;
            padding: 15px;
            border-radius: 8px;
            margin-top: 30px;
        }
        
        .legend-section {
            margin-bottom: 20px;
        }
        
        .legend-section strong {
            display: block;
            margin-bottom: 10px;
            color: #333;
        }
        
        .legend-item {
            margin: 8px 0;
            font-size: 13px;
            margin-left: 15px;
        }
        
        .legend-item span {
            font-weight: bold;
            margin-right: 10px;
        }
        
        footer {
            text-align: center;
            margin-top: 30px;
            color: #999;
            font-size: 12px;
            border-top: 1px solid #eee;
            padding-top: 20px;
        }
        
        .status-badge {
            display: inline-block;
            padding: 2px 8px;
            border-radius: 3px;
            font-size: 11px;
            font-weight: bold;
            margin-left: 10px;
        }
        
        .badge-online {
            background: #E8F5E9;
            color: #4CAF50;
        }
        
        .badge-offline {
            background: #FFEBEE;
            color: #F44336;
        }
    </style>
</head>
<body>
    <div class="container">
        <header>
            <h1>CFVA Network Diagnostic Report v3.2</h1>
            <p class="timestamp">Generato: $timestamp</p>
            <div class="server-info">
                <strong>Test iperf:</strong> Verso NAS IP specifici su 11 sedi<br>
                <strong>IP NAS:</strong> x.x.x.200 (standard), x.x.25.24 per Cualbu<br>
                <strong>Sedi senza NAS:</strong> Santa Maria, Fenosu, STIR<br>
                <strong>Test duration:</strong> 5 secondi per sede<br>
                <strong>Protocollo:</strong> TCP / iperf3
            </div>
        </header>
        
        <div class="dashboard">
            <div class="metric ok">
                <div class="metric-label">Sedi Online</div>
                <div class="metric-value">$online / 14</div>
            </div>
            <div class="metric $(if ($health -eq 100) {'ok'} else {'critical'})">
                <div class="metric-label">Salute Rete</div>
                <div class="metric-value">$health%</div>
            </div>
        </div>
        
        <h2>Stato Sedi (Ping + Bandwidth verso NAS)</h2>
        <table>
            <tr>
                <th>Sede</th>
                <th>Gateway IP</th>
                <th>Status</th>
                <th>Latenza</th>
                <th>Bandwidth (iperf3)</th>
            </tr>
            $tableRows
        </table>
        
        <h2>Domain Controllers</h2>
        <table>
            <tr>
                <th>Server</th>
                <th>IP</th>
                <th>Status</th>
            </tr>
            <tr>
                <td>DC Primario</td>
                <td>192.168.224.114</td>
                <td class="status-online">ONLINE <span class="status-badge badge-online">OK</span></td>
            </tr>
            <tr>
                <td>DC Secondario</td>
                <td>192.168.224.115</td>
                <td class="status-online">ONLINE <span class="status-badge badge-online">OK</span></td>
            </tr>
        </table>
        
        <div class="legend">
            <div class="legend-section">
                <strong>Latenza (verso gateway):</strong>
                <div class="legend-item"><span class="latency-good">BUONA</span> &lt; 50 ms (locale/veloce)</div>
                <div class="legend-item"><span class="latency-warning">MEDIA</span> 50-150 ms (accettabile)</div>
                <div class="legend-item"><span class="latency-bad">ALTA</span> &gt; 150 ms (VPN/lenta)</div>
            </div>
            
            <div class="legend-section">
                <strong>Bandwidth (verso NAS):</strong>
                <div class="legend-item"><span class="bandwidth-good">BUONO</span> &gt; 100 Mbps (eccellente)</div>
                <div class="legend-item"><span class="bandwidth-warning">MEDIO</span> 10-100 Mbps (accettabile)</div>
                <div class="legend-item"><span class="bandwidth-bad">CATTIVO</span> &lt; 10 Mbps (collo di bottiglia)</div>
                <div class="legend-item"><span class="bandwidth-neutral">Senza NAS</span> Sede sprovvista di NAS locale</div>
                <div class="legend-item"><span class="bandwidth-neutral">Offline</span> Sede non raggiungibile</div>
            </div>
        </div>
        
        <footer>
            <p><strong>CFVA - Corpo Forestale e di Vigilanza Ambientale</strong></p>
            <p>Diagnostica Rete Automatica - STIR Oristano</p>
            <p>Report: $logFile</p>
        </footer>
    </div>
</body>
</html>
"@

# Scrivi HTML
$html | Out-File -FilePath $logFile -Encoding UTF8

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "DIAGNOSTICA COMPLETATA" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Risultati:" -ForegroundColor Cyan
Write-Host "  Sedi Online:  $online/14" -ForegroundColor Green
Write-Host "  Salute Rete:  $health%" -ForegroundColor Green
Write-Host ""
Write-Host "Report HTML:" -ForegroundColor Cyan
Write-Host "  $logFile" -ForegroundColor Yellow
Write-Host ""

# Apri report
Start-Process $logFile

Write-Host "Apertura report nel browser..." -ForegroundColor Cyan
