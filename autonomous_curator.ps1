param (
    [string]$TargetUsername = "",
    [switch]$PublishNow = $false
)

$configPath = Join-Path $PSScriptRoot "config.json"
$config = Get-Content $configPath -Raw | ConvertFrom-Json

$targetAccounts = @("oceanstatement", "ocean.autograph", "ocean_content", "oceana")
if (-not $TargetUsername) {
    $TargetUsername = Get-Random -InputObject $targetAccounts
}

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host " Autonomous Ocean Curator: Visiting @$TargetUsername" -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan

# 1. Scrape latest reels using headless Chrome CDP
$allLinks = & "$PSScriptRoot\extract_target_reels.ps1" -Username $TargetUsername
$links = $allLinks | Where-Object { $_ -match "/reel/" }
if (-not $links -or $links.Count -eq 0) {
    $links = $allLinks
}

if (-not $links -or $links.Count -eq 0) {
    Write-Error "No media links found for @$TargetUsername"
    return
}

# Pick the first fresh reel
$selectedUrl = $links[0]
Write-Host "`n[*] Selected Top Reel: $selectedUrl" -ForegroundColor Green

# 2. Download Reel with original sound
$ytdlp = Join-Path $PSScriptRoot "tools\yt-dlp.exe"
$tempDir = Join-Path $PSScriptRoot "temp"
if (-not (Test-Path $tempDir)) { New-Item -ItemType Directory -Force -Path $tempDir | Out-Null }

$metaRaw = & $ytdlp --dump-json $selectedUrl 2>&1
$meta = $metaRaw | ConvertFrom-Json

$uniqueId = [System.Guid]::NewGuid().ToString().Substring(0, 8)
$outputFile = Join-Path $tempDir "curated_reel_$uniqueId.mp4"

Write-Host "[*] Downloading video with original sound..." -ForegroundColor Yellow
& $ytdlp -f "mp4/best" -o $outputFile $selectedUrl

if (-not (Test-Path $outputFile)) {
    Write-Error "Download failed."
    return
}
Write-Host "[+] Downloaded successfully: $((Get-Item $outputFile).Length) bytes" -ForegroundColor Green

# 3. Clean, short, natural caption (no weird signs, no bullet points)
$cleanCaption = "The Sea Pen may look like a plant rising from the seafloor, but it is actually a colony of tiny marine animals living together and retreating into the sand when danger nears.`n`n" +
"Credit: @$TargetUsername`n" +
"Follow @oceanwikipedia for daily marine discoveries.`n`n" +
"#oceanlife #marinelife #deepsea #marinebiology #underwater #ocean"

Write-Host "`n[SHORT AND NATURAL CAPTION]:" -ForegroundColor Cyan
Write-Host $cleanCaption -ForegroundColor White

if ($PublishNow) {
    Write-Host "`n[*] Uploading to direct host for Meta Graph API..." -ForegroundColor Yellow
    $uploadRes = curl.exe -s -F "reqtype=fileupload" -F "time=24h" -F "fileToUpload=@$outputFile" https://litterbox.catbox.moe/resources/internals/api.php
    $publicVideoUrl = $uploadRes.Trim()
    
    . "$PSScriptRoot\auto_publisher.ps1"
    $publishedId = Publish-InstagramReel -videoUrl $publicVideoUrl -captionText $cleanCaption
    Write-Host "[SUCCESS] 100% Autonomously curated and published Reel! ID: $publishedId" -ForegroundColor Green
    return $publishedId
} else {
    Write-Host ""
    Write-Host "[Ready] Run with -PublishNow to post live." -ForegroundColor Yellow
}
