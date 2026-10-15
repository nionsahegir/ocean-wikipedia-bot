param (
    [string]$Username = "oceanstatement"
)

$chrome = "C:\Program Files\Google\Chrome\Application\chrome.exe"
$port = 9222
$tempData = Join-Path $env:TEMP ("chrome_profile_" + $Username.Replace(".", "_"))

Write-Host "Launching Chrome to inspect @$Username..." -ForegroundColor Cyan
$targetUrl = "https://www.instagram.com/$Username/"
$p = Start-Process -FilePath $chrome -ArgumentList "--remote-debugging-port=$port", "--user-data-dir=$tempData", "--headless=new", $targetUrl -PassThru
Start-Sleep -Seconds 7

try {
    $tabs = Invoke-RestMethod -Uri "http://127.0.0.1:$port/json" -Method Get
    $igTab = $tabs | Where-Object { $_.url -match $Username } | Select-Object -First 1

    if ($igTab) {
        Write-Host "Found Instagram Tab: $($igTab.title)" -ForegroundColor Green
        Write-Host "WebSocket Debugger URL: $($igTab.webSocketDebuggerUrl)" -ForegroundColor Gray
        
        # Connect via WebSocket and evaluate JavaScript
        $ws = New-Object System.Net.WebSockets.ClientWebSocket
        $cts = New-Object System.Threading.CancellationTokenSource
        $uri = New-Object System.Uri($igTab.webSocketDebuggerUrl)
        $connectTask = $ws.ConnectAsync($uri, $cts.Token)
        $connectTask.Wait()

        # Send Runtime.evaluate to get post links
        $jsCode = "Array.from(document.querySelectorAll('a')).map(a => a.href).filter(h => h.includes('/reel/') || h.includes('/p/'))"
        $req = @{
            id = 1
            method = "Runtime.evaluate"
            params = @{
                expression = $jsCode
                returnByValue = $true
            }
        } | ConvertTo-Json -Compress

        $bytes = [System.Text.Encoding]::UTF8.GetBytes($req)
        $segment = New-Object System.ArraySegment[byte](,$bytes)
        $sendTask = $ws.SendAsync($segment, [System.Net.WebSockets.WebSocketMessageType]::Text, $true, $cts.Token)
        $sendTask.Wait()

        # Receive response
        $buf = New-Object byte[] 65536
        $recvSegment = New-Object System.ArraySegment[byte](,$buf)
        $recvTask = $ws.ReceiveAsync($recvSegment, $cts.Token)
        $recvTask.Wait()

        $respJson = [System.Text.Encoding]::UTF8.GetString($buf, 0, $recvTask.Result.Count)
        $resp = $respJson | ConvertFrom-Json

        Write-Host "`nExtracted Links from page DOM:" -ForegroundColor Cyan
        $links = $resp.result.result.value
        Write-Host "Total links found: $($links.Count)"
        foreach ($link in $links | Select-Object -First 10) {
            Write-Host "  -> $link" -ForegroundColor White
        }

        $ws.CloseAsync([System.Net.WebSockets.WebSocketCloseStatus]::NormalClosure, "Done", $cts.Token).Wait()
        return $links
    } else {
        Write-Host "Instagram tab not found." -ForegroundColor Yellow
        return @()
    }
} catch {
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
} finally {
    if ($p -and -not $p.HasExited) {
        Stop-Process -Id $p.Id -Force -ErrorAction SilentlyContinue
    }
}
