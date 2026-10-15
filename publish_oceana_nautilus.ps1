$ytdlp = "$PSScriptRoot\tools\yt-dlp.exe"
$tempDir = "$PSScriptRoot\temp"
if (-not (Test-Path $tempDir)) { New-Item -ItemType Directory -Force -Path $tempDir | Out-Null }

$url = "https://www.instagram.com/oceana/reel/DeSymQ6CWNn/"
$videoPath = "$tempDir\nautilus_curated.mp4"
if (Test-Path $videoPath) { Remove-Item $videoPath -Force }

Write-Host "Downloading Chambered Nautilus Reel from @oceana..." -ForegroundColor Cyan
& $ytdlp -f "mp4/best" -o $videoPath $url

if (-not (Test-Path $videoPath)) {
    Write-Error "Failed to download reel."
    return
}
Write-Host "Downloaded successfully: $((Get-Item $videoPath).Length) bytes" -ForegroundColor Green

Write-Host "Uploading to direct host for Meta Graph API..." -ForegroundColor Yellow
$uploadRes = curl.exe -s -F "reqtype=fileupload" -F "time=24h" -F "fileToUpload=@$videoPath" https://litterbox.catbox.moe/resources/internals/api.php
$publicUrl = $uploadRes.Trim()
Write-Host "Public URL: $publicUrl" -ForegroundColor Green

. "$PSScriptRoot\auto_publisher.ps1"

$caption = @'
Meet the mesmerizing Chambered Nautilus, an ancient cephalopod that has navigated Earth's oceans for over 500 million years.

It regulates its buoyancy and glides through the deep by adjusting gas and liquid inside the chambers of its spiraled shell.

Credit: @oceana
Follow @oceanwikipedia for daily oceanic discoveries.

#nautilus #oceanlife #marinelife #deepsea #marinebiology #underwater #ancientcreatures
'@

Write-Host "Publishing to @oceanwikipedia..." -ForegroundColor Cyan
$publishedId = Publish-InstagramReel -videoUrl $publicUrl -captionText $caption
Write-Host "PUBLISHED_REEL_ID: $publishedId" -ForegroundColor Green
