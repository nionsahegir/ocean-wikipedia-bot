. "$PSScriptRoot\auto_publisher.ps1"

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host " 🚀 Executing Full Test Batch: Reel + Photo + Carousel" -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan

# ----------------------------------------------------
# 1. PUBLISH VIRAL REEL (Gulper Eel with Original Sound)
# ----------------------------------------------------
Write-Host "`n--- [1/3] Uploading & Publishing Viral Reel ---" -ForegroundColor Yellow
$reelPath = Join-Path $PSScriptRoot "temp\gulper_eel_reel.mp4"

if (Test-Path $reelPath) {
    Write-Host "[*] Uploading Gulper Eel Reel to direct host..." -ForegroundColor Gray
    $uploadRes = curl.exe -s -F "reqtype=fileupload" -F "time=24h" -F "fileToUpload=@$reelPath" https://litterbox.catbox.moe/resources/internals/api.php
    $reelPublicUrl = $uploadRes.Trim()
    Write-Host "[+] Public Video URL: $reelPublicUrl" -ForegroundColor Green

    $reelCaption = @'
Wait until you see how big its mouth gets! 🎈🌊

Deep in the Papahānaumokuākea Marine National Monument, ocean explorers with Nautilus Live encountered this juvenile Pelican / Gulper Eel (Eurypharynx pelecanoides) inflating its massive jaws.

Why does it do this?
🔹 Balloon Jaws: Its lower jaw is loosely hinged and can expand like a giant pouch, allowing it to engulf prey much larger than itself.
🔹 Sparse Deep Sea: In the midnight zone where meals are extremely rare, being able to consume whatever crosses your path is the ultimate survival tool.
🔹 Bioluminescent Lure: At the very tip of its long whip-like tail, it carries a glowing photophore to attract curious prey in total darkness.

Would you ever dare to dive into the deep abyss? Share your thoughts below! 👇

💾 SAVE this to your ocean wonders collection!
↗️ SHARE with a friend who is fascinated by deep-sea mysteries!

Footage: Ocean Exploration Trust / Nautilus Live (CC)
Follow @oceanwikipedia for daily authentic marine discoveries! 🐋

#OceanWikipedia #GulperEel #DeepSea #NautilusLive #MarineBiology #DeepOcean #UnderwaterExploration #OceanCreatures #SeaLife #OceanVibes #SaveOurOceans
'@

    $publishedReelId = Publish-InstagramReel -videoUrl $reelPublicUrl -captionText $reelCaption
    Write-Host "[🎉 SUCCESS] Viral Reel published live! ID: $publishedReelId" -ForegroundColor Green
} else {
    Write-Host "[!] Gulper Eel video file not found in temp." -ForegroundColor Red
}

Start-Sleep -Seconds 5

# ----------------------------------------------------
# 2. PUBLISH HIGH-RES PHOTO (Prehistoric Sea Turtle)
# ----------------------------------------------------
Write-Host "`n--- [2/3] Publishing High-Res Ocean Photo ---" -ForegroundColor Yellow
$photoUrl = "https://images.unsplash.com/photo-1544551763-46a013bb70d5?fm=jpg&w=1080&h=1080&fit=crop"

$photoCaption = @'
Gliding through sunlit tropical reefs with effortless grace... 🐢🌊

Sea turtles have been navigating our planet's oceans for over 100 million years — having successfully survived the catastrophic asteroid event that wiped out the dinosaurs!

Key Marine Insights:
🔹 Internal GPS: They use Earth's geomagnetic field to navigate across thousands of miles of open ocean.
🔹 Natal Homing: Decades after leaving their hatching beach, female turtles return to the exact same stretch of sand to lay their own eggs.
🔹 Ocean Health: Green sea turtles act as vital ocean gardeners, grazing on seagrass beds and keeping shallow ecosystems healthy.

Have you ever spotted a sea turtle swimming in the wild? Tell us your story in the comments! 💬

💾 SAVE this to your ocean inspiration vault!
↗️ SHARE with fellow ocean lovers!

Photo: Marine Wildlife Photography Archive (Royalty-Free)
Follow @oceanwikipedia for daily oceanic wonders & conservation stories! 💙

#OceanWikipedia #SeaTurtle #MarineLife #OceanConservation #CoralReef #UnderwaterPhotography #MarineBiology #OceanLovers #OceanVibes #SaveOurOceans
'@

$publishedPhotoId = Publish-InstagramPhoto -imageUrl $photoUrl -captionText $photoCaption
Write-Host "[🎉 SUCCESS] Ocean Photo published live! ID: $publishedPhotoId" -ForegroundColor Green

Start-Sleep -Seconds 5

# ----------------------------------------------------
# 3. PUBLISH 3-SLIDE CAROUSEL
# ----------------------------------------------------
Write-Host "`n--- [3/3] Publishing 3-Slide Ocean Carousel ---" -ForegroundColor Yellow
$carouselUrls = @(
    "https://images.unsplash.com/photo-1568430462989-44163eb1752f?fm=jpg&w=1080&h=1080&fit=crop",
    "https://images.unsplash.com/photo-1582967788606-a171c1080cb0?fm=jpg&w=1080&h=1080&fit=crop",
    "https://images.unsplash.com/photo-1544551763-77ef2d0cfc6c?fm=jpg&w=1080&h=1080&fit=crop"
)

$carouselCaption = @'
Swipe through 3 awe-inspiring wonders of our blue planet! 👉🌊

Slide 1: The Humpback Whale (Megaptera novaeangliae) — Launching 40 tons of sheer leviathan power above the surface in a thunderous breach.
Slide 2: Living Coral Metropolis — Though covering under 1% of the seafloor, healthy coral reefs support over 25% of all marine life on Earth.
Slide 3: Synchronized Jack Vortex — Thousands of fish schooling in a rotating defensive cyclone that confuses apex ocean predators.

Which slide took your breath away the most? (1, 2, or 3?) Vote below! 👇

💾 SAVE this carousel to keep ocean wonders on your feed!
↗️ SHARE with a friend who needs to see this!

Credits: Todd Cravens / Francesco Ungaro / Marine Wildlife Archive
Follow @oceanwikipedia for daily ocean exploration & marine education! 🐋

#OceanWikipedia #HumpbackWhale #CoralReef #MarineLife #UnderwaterPhotography #OceanExploration #DeepSea #OceanConservation #NatureLovers #OceanLovers
'@

$publishedCarouselId = Publish-InstagramCarousel -imageUrls $carouselUrls -captionText $carouselCaption
Write-Host "[🎉 SUCCESS] Ocean Carousel published live! ID: $publishedCarouselId" -ForegroundColor Green

Start-Sleep -Seconds 3

# ----------------------------------------------------
# 4. RUN COMMENT REPLY ENGINE
# ----------------------------------------------------
Write-Host "`n--- [4/4] Scanning & Replying to All Comments ---" -ForegroundColor Yellow
. "$PSScriptRoot\check_and_reply_all.ps1" -Live

Write-Host "`n==========================================================" -ForegroundColor Cyan
Write-Host " 🏁 Full Batch Completed Successfully!" -ForegroundColor Green
Write-Host "==========================================================" -ForegroundColor Cyan
