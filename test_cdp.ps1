$chrome = "C:\Program Files\Google\Chrome\Application\chrome.exe"
$port = 9222
$tempData = Join-Path $env:TEMP "chrome_bot_profile"

Write-Host "Launching Chrome with remote debugging on port $port..." -ForegroundColor Cyan
$p = Start-Process -FilePath $chrome -ArgumentList "--remote-debugging-port=$port", "--user-data-dir=$tempData", "--headless=new", "https://www.instagram.com/oceanstatement/" -PassThru
Start-Sleep -Seconds 6

try {
    $tabs = Invoke-RestMethod -Uri "http://127.0.0.1:$port/json" -Method Get
    Write-Host "Connected to Chrome CDP!" -ForegroundColor Green
    foreach ($t in $tabs) {
        Write-Host "  -> Tab Title: $($t.title) | URL: $($t.url)"
    }
} catch {
    Write-Host "Failed to connect to CDP: $($_.Exception.Message)" -ForegroundColor Red
} finally {
    if ($p -and -not $p.HasExited) {
        Stop-Process -Id $p.Id -Force -ErrorAction SilentlyContinue
    }
}
