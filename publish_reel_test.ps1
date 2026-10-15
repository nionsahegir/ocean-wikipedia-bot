. "$PSScriptRoot\auto_publisher.ps1"

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host " 🐬 Publishing 100% Genuine Dolphins Underwater Reel" -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan

$dolphinUrl = "https://assets.mixkit.co/videos/4133/4133-720.mp4"
$caption = @'
Did you know dolphins are known to recognize themselves in mirrors and call each other by unique signature whistles — essentially individual names?

They travel the world's oceans in tight-knit pods, displaying empathy, cooperation, and acrobatic joy.

Have you ever encountered wild dolphins while out on the water? Tell us in the comments!

Footage: Mixkit Marine Archive (Royalty-Free / CC)
Follow @oceanwikipedia for daily oceanic wonders!

#OceanWikipedia #Dolphins #MarineLife #OceanExploration #MarineBiology #DeepSea #UnderwaterWorld #OceanLovers #OceanConservation
'@

$reelId = Publish-InstagramReel -videoUrl $dolphinUrl -captionText $caption
Write-Host "[🎉 SUCCESS] Genuine Ocean Reel Published! Media ID: $reelId" -ForegroundColor Green
