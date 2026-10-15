param (
    [Parameter(Mandatory=$true)]
    [string]$ReelUrl,
    [string]$CustomCredit = "",
    [switch]$PublishNow = $false
)

$configPath = Join-Path $PSScriptRoot "config.json"
$config = Get-Content $configPath -Raw | ConvertFrom-Json

$ytdlp = Join-Path $PSScriptRoot "tools\yt-dlp.exe"
$tempDir = Join-Path $PSScriptRoot "temp"
if (-not (Test-Path $tempDir)) { New-Item -ItemType Directory -Force -Path $tempDir | Out-Null }

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host " Ocean Wikipedia - Viral Reel Ingestion & Transformer" -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "[*] Fetching target Reel: $ReelUrl" -ForegroundColor Yellow

$uniqueId = [System.Guid]::NewGuid().ToString().Substring(0, 8)
$outputTemplate = Join-Path $tempDir "viral_reel_$uniqueId.%(ext)s"

# 1. Download video and json metadata
$metaJsonRaw = & $ytdlp --dump-json $ReelUrl 2>&1
$meta = $metaJsonRaw | ConvertFrom-Json

if (-not $meta) {
    Write-Error "Failed to fetch Reel metadata. Please verify the URL."
    return
}

Write-Host "[+] Extracted Source Reel:" -ForegroundColor Green
Write-Host "    Uploader: @$($meta.uploader)" -ForegroundColor White
$descSnippet = if ($meta.description) { $meta.description.Substring(0, [Math]::Min(80, $meta.description.Length)) } else { "No description" }
Write-Host "    Description snippet: $descSnippet..." -ForegroundColor Gray

# Download actual mp4
& $ytdlp -f "mp4" -o $outputTemplate $ReelUrl

$downloadedFile = Get-ChildItem -Path $tempDir -Filter "viral_reel_$uniqueId*.mp4" | Select-Object -First 1

if (-not $downloadedFile) {
    Write-Error "Failed to download Reel video file."
    return
}

Write-Host "[+] Downloaded video successfully: $($downloadedFile.FullName) ($([Math]::Round($downloadedFile.Length / 1MB, 2)) MB)" -ForegroundColor Green

# 2. Build Redesigned Viral Caption tailored for Saves, Shares, and Comments
$creditHandle = if ($CustomCredit) { $CustomCredit } elseif ($meta.uploader) { "@$($meta.uploader)" } else { "Original Creator" }

$c1 = "Wait until the end... The ocean is far more surreal than any sci-fi movie!`n`n" +
"Here is what makes this moment so extraordinary:`n" +
"* Over 80% of our ocean remains completely unmapped and unexplored.`n" +
"* Deep-sea creatures survive under crushing hydrostatic pressures that would flatten steel.`n" +
"* Every expedition reveals organisms with adaptations found nowhere else on planet Earth.`n`n" +
"Would you ever dare to dive this deep? Tell us in the comments!`n`n" +
"SAVE this to your ocean wonders vault!`n" +
"SHARE with a friend who is fascinated by the mysterious abyss!`n`n" +
"Credit / Video source: $creditHandle`n" +
"Follow @oceanwikipedia for daily oceanic discoveries & deep-sea wonders!`n`n" +
"#OceanWikipedia #DeepSea #MarineLife #OceanExploration #UnderwaterWorld #OceanVibes #SaveOurOceans #MarineBiology #Bioluminescence #NatureLovers #OceanConservation"

$c2 = "Nature's evolutionary artistry in full display. Watch how perfectly adapted this marine life is to the open ocean!`n`n" +
"Key Oceanic Insights:`n" +
"* The open ocean is Earth's largest ecosystem, yet we have only scratched the surface of its biodiversity.`n" +
"* Species like this play a vital role in balancing marine food webs and oceanic carbon cycles.`n" +
"* Preserving these pristine waters ensures the survival of thousands of interdependent species.`n`n" +
"Have you ever witnessed something like this in person? Share your experience below!`n`n" +
"SAVE this post to keep marine wonder on your feed!`n" +
"SHARE with fellow ocean enthusiasts!`n`n" +
"Credit / Original Creator: $creditHandle`n" +
"Follow @oceanwikipedia for daily authentic marine discoveries!`n`n" +
"#OceanWikipedia #MarineBiology #OceanLife #WildlifePhotography #OceanCreatures #SeaLife #DeepOcean #UnderwaterPhotography #OceanLovers #OceanLoversCommunity"

$selectedCaption = Get-Random -InputObject @($c1, $c2)

Write-Host "`n[REDESIGNED VIRAL CAPTION]:" -ForegroundColor Cyan
Write-Host $selectedCaption -ForegroundColor White

if ($PublishNow) {
    Write-Host "`n[*] Uploading video to direct host for Instagram Graph API..." -ForegroundColor Yellow
    $uploadRes = curl.exe -s -F "reqtype=fileupload" -F "time=24h" -F "fileToUpload=@$($downloadedFile.FullName)" https://litterbox.catbox.moe/resources/internals/api.php
    $publicVideoUrl = $uploadRes.Trim()
    
    Write-Host "[+] Direct Video URL: $publicVideoUrl" -ForegroundColor Green
    
    . (Join-Path $PSScriptRoot "auto_publisher.ps1")
    $publishedId = Publish-InstagramReel -videoUrl $publicVideoUrl -captionText $selectedCaption
    Write-Host "[SUCCESS] Viral Reel published live! Media ID: $publishedId" -ForegroundColor Green
    return $publishedId
} else {
    Write-Host ""
    Write-Host "[TIP] Video is downloaded and ready in temp folder. Run with -PublishNow to immediately post to Instagram." -ForegroundColor Yellow
}
