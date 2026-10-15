$config = Get-Content "$PSScriptRoot\config.json" -Raw | ConvertFrom-Json
$token = $config.page_access_token
$pageId = $config.page_id
$baseUrl = "https://graph.facebook.com/" + $config.api_version

Write-Host "Checking Facebook Page Info..." -ForegroundColor Cyan
$pageInfo = Invoke-RestMethod -Uri "$baseUrl/$pageId" -Method Get -Body @{
    fields = "id,name,link,is_published"
    access_token = $token
}
Write-Host "Page Name: $($pageInfo.name)"
Write-Host "Page Link: $($pageInfo.link)"
Write-Host "Is Published: $($pageInfo.is_published)"

Write-Host "`nChecking Facebook Page Feed..." -ForegroundColor Cyan
try {
    $feed = Invoke-RestMethod -Uri "$baseUrl/$pageId/feed" -Method Get -Body @{
        fields = "id,message,created_time"
        limit = 5
        access_token = $token
    }
    Write-Host "Recent Posts on Facebook Page: $($feed.data.Count)"
} catch {
    $stream = $_.Exception.Response.GetResponseStream()
    $reader = New-Object System.IO.StreamReader($stream)
    Write-Host "Error Body: $($reader.ReadToEnd())" -ForegroundColor Red
}
