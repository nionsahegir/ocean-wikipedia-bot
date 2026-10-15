$reelPath = "C:\Users\Nion\.gemini\antigravity\scratch\ocean-wikipedia\temp\glass_octopus_reel.mp4"

Write-Host "Uploading Glass Octopus Reel to direct host..." -ForegroundColor Yellow
$uploadRes = curl.exe -s -F "reqtype=fileupload" -F "time=24h" -F "fileToUpload=@$reelPath" https://litterbox.catbox.moe/resources/internals/api.php
$publicUrl = $uploadRes.Trim()
Write-Host "Direct Video URL: $publicUrl" -ForegroundColor Green

. "$PSScriptRoot\auto_publisher.ps1"

$caption = @'
This is NOT CGI. Meet the elusive Glass Octopus (Vitreledonella richardi), one of the rarest and most ethereal creatures in our oceans!

Captured in pristine 4K by ocean explorers in the central Pacific, this ghost-like cephalopod has evolved near-total transparency to survive in the twilight and midnight zones.

Here is why its biology is so mind-blowing:
* Invisibility Cloak: Almost its entire body is completely transparent. Only its eyes, optic nerve, and digestive tract are visible.
* Cylindrical Eyes: Its eyes evolved into narrow upright cylinders to minimize casting any silhouette to predators swimming below.
* Deep-Sea Phantom: It drifts weightlessly under thousands of pounds of hydrostatic pressure where sunlight never reaches.

Would you ever dare to dive into the deep abyss? Share your thoughts below!

SAVE this to your deep-sea wonders vault!
SHARE with a friend who is fascinated by ocean mysteries!

Credit: Schmidt Ocean Institute (FK210605 Expedition)
Follow @oceanwikipedia for daily oceanic discoveries & marine wonders!

#OceanWikipedia #GlassOctopus #DeepSea #MarineBiology #DeepOcean #UnderwaterExploration #OceanCreatures #SeaLife #OceanVibes #SaveOurOceans #NatureLovers
'@

Write-Host "Publishing Glass Octopus Reel to Instagram..." -ForegroundColor Cyan
$publishedId = Publish-InstagramReel -videoUrl $publicUrl -captionText $caption
Write-Host "PUBLISHED_REEL_ID: $publishedId" -ForegroundColor Green
