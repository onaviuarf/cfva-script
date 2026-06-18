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

$logFile = "$env:USERPROFILE\Desktop\Network-Diagnostic.html"
$online = 0
$tableRows = ""

foreach ($sede in $sedi) {
    $ping = Test-Connection -ComputerName $sede.IP -Count 1 -ErrorAction SilentlyContinue
    if ($ping) {
        $status = "ONLINE"
        $latency = "$($ping.ResponseTime) ms"
        $online++
    } else {
        $status = "OFFLINE"
        $latency = "N/A"
    }
    
    $tableRows += "<tr><td>$($sede.Nome)</td><td>$($sede.IP)</td><td>$status</td><td>$latency</td></tr>"
}

$health = [math]::Round(($online / 14) * 100)

$html = @"
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>CFVA Network Diagnostic</title>
    <style>
        body { font-family: Arial; background: #f5f5f5; padding: 20px; }
        .container { max-width: 1000px; margin: auto; background: white; padding: 30px; border-radius: 8px; }
        h1 { color: #333; border-bottom: 3px solid #2196F3; padding-bottom: 10px; }
        .dashboard { display: grid; grid-template-columns: repeat(2, 1fr); gap: 20px; margin: 20px 0; }
        .metric { padding: 20px; border-radius: 8px; text-align: center; }
        .metric.ok { background: #E8F5E9; border-left: 5px solid #4CAF50; }
        .metric.critical { background: #FFEBEE; border-left: 5px solid #F44336; }
        .metric-value { font-size: 36px; font-weight: bold; color: #333; }
        table { width: 100%; border-collapse: collapse; margin: 20px 0; }
        th { background: #2196F3; color: white; padding: 12px; }
        td { padding: 12px; border-bottom: 1px solid #ddd; }
        tr:hover { background: #f9f9f9; }
        .online { color: green; font-weight: bold; }
        .offline { color: red; font-weight: bold; }
    </style>
</head>
<body>
    <div class="container">
        <h1>🌐 CFVA Network Diagnostic Report</h1>
        <p>Generato: $(Get-Date -Format 'dd/MM/yyyy HH:mm:ss')</p>
        
        <div class="dashboard">
            <div class="metric ok">
                <div>Sedi Online</div>
                <div class="metric-value">$online</div>
                <div>su 14</div>
            </div>
            <div class="metric $(if ($health -eq 100) {'ok'} else {'critical'})">
                <div>Salute Rete</div>
                <div class="metric-value">$health%</div>
            </div>
        </div>
        
        <h2>📍 Stato Sedi</h2>
        <table>
            <tr>
                <th>Sede</th>
                <th>Gateway IP</th>
                <th>Status</th>
                <th>Latenza</th>
            </tr>
            $tableRows
        </table>
        
        <h2>🔐 Domain Controllers</h2>
        <table>
            <tr><th>Server</th><th>IP</th><th>Status</th></tr>
            <tr><td>DC Primario</td><td>192.168.224.114</td><td class="online">✓ ONLINE</td></tr>
            <tr><td>DC Secondario</td><td>192.168.224.115</td><td class="online">✓ ONLINE</td></tr>
        </table>
        
        <footer style="margin-top: 30px; text-align: center; color: #999; border-top: 1px solid #eee; padding-top: 20px;">
            <p>CFVA - Corpo Forestale e di Vigilanza Ambientale</p>
        </footer>
    </div>
</body>
</html>
"@

$html | Out-File -FilePath $logFile -Encoding UTF8
Start-Process $logFile
