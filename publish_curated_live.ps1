$reelFile = "C:\Users\Nion\.gemini\antigravity\scratch\ocean-wikipedia\temp\curated_reel_7be717b6.mp4"

Write-Host "Uploading curated reel to direct host..." -ForegroundColor Yellow
$uploadRes = curl.exe -s -F "reqtype=fileupload" -F "time=24h" -F "fileToUpload=@$reelFile" https://litterbox.catbox.moe/resources/internals/api.php
$publicUrl = $uploadRes.Trim()
Write-Host "Public URL: $publicUrl" -ForegroundColor Green

. "$PSScriptRoot\auto_publisher.ps1"

$caption = @'
The Sea Pen may look like a plant rising from the seafloor, but it is actually a colony of tiny marine animals living together and retreating into the sand when danger nears.

Credit: @oceanstatement
Follow @oceanwikipedia for daily marine discoveries.

#oceanlife #marinelife #deepsea #marinebiology #underwater #ocean
'@

$publishedId = Publish-InstagramReel -videoUrl $publicUrl -captionText $caption
Write-Host "PUBLISHED_REEL_ID: $publishedId" -ForegroundColor Green
