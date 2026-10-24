# Quick Wi-Fi Mobile Server for HarmonyHub
$port = 8080
$folder = $PSScriptRoot

# Get Local IP Address
$localIp = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object { 
    $_.InterfaceAlias -notlike "*Loopback*" -and $_.IPAddress -notlike "169.254*" 
} | Select-Object -First 1).IPAddress

if (-not $localIp) {
    $localIp = "localhost"
}

Write-Host "==========================================================" -ForegroundColor Green
Write-Host "  HarmonyHub Mobile & Tablet Wi-Fi Server Running!" -ForegroundColor Yellow
Write-Host "==========================================================" -ForegroundColor Green
Write-Host ""
Write-Host "Open this URL on Adeline's Handphone (HP) or Tablet/iPad:" -ForegroundColor Cyan
Write-Host "    http://${localIp}:${port}" -ForegroundColor White -BackgroundColor DarkGreen
Write-Host ""
Write-Host "Local browser access on this PC:" -ForegroundColor Gray
Write-Host "    http://localhost:${port}" -ForegroundColor Gray
Write-Host ""
Write-Host "Press Ctrl+C in this window anytime to stop the server." -ForegroundColor Yellow
Write-Host "==========================================================" -ForegroundColor Green

$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://*:${port}/")

try {
    $listener.Start()
} catch {
    # Fallback to localhost prefix if wildcard requires admin
    $listener = New-Object System.Net.HttpListener
    $listener.Prefixes.Add("http://localhost:${port}/")
    $listener.Start()
    Write-Host "Note: Started in localhost mode. To share across Wi-Fi, run PowerShell as Administrator once." -ForegroundColor Yellow
}

while ($listener.IsListening) {
    $context = $listener.GetContext()
    $request = $context.Request
    $response = $context.Response

    $urlPath = $request.Url.LocalPath
    if ($urlPath -eq "/" -or [string]::IsNullOrWhiteSpace($urlPath)) {
        $urlPath = "/index.html"
    }

    $filePath = Join-Path $folder $urlPath.TrimStart('/')

    if (Test-Path $filePath -PathType Leaf) {
        $bytes = [System.IO.File]::ReadAllBytes($filePath)
        
        if ($filePath.EndsWith(".html")) {
            $response.ContentType = "text/html; charset=utf-8"
        } elseif ($filePath.EndsWith(".js")) {
            $response.ContentType = "application/javascript"
        } elseif ($filePath.EndsWith(".css")) {
            $response.ContentType = "text/css"
        } elseif ($filePath.EndsWith(".json")) {
            $response.ContentType = "application/json"
        } else {
            $response.ContentType = "application/octet-stream"
        }

        $response.ContentLength64 = $bytes.Length
        $response.OutputStream.Write($bytes, 0, $bytes.Length)
    } else {
        $response.StatusCode = 404
        $notFoundMsg = [System.Text.Encoding]::UTF8.GetBytes("404 File Not Found")
        $response.ContentLength64 = $notFoundMsg.Length
        $response.OutputStream.Write($notFoundMsg, 0, $notFoundMsg.Length)
    }

    $response.OutputStream.Close()
}
