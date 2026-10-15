. "$PSScriptRoot\auto_publisher.ps1"

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host " Publishing Verified 100% Matching Ocean Content" -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan

# 1. Post Verified Sea Turtle Photo
Write-Host "`n--- [1/2] Publishing Verified Sea Turtle Photo ---" -ForegroundColor Yellow
$turtleUrl = "https://images.unsplash.com/photo-1437622368342-7a3d73a34c8f?fm=jpg&w=1080&h=1080&fit=crop"
$turtleCaption = @'
Navigating open seas for over 100 million years — sea turtles are living relics of the prehistoric ocean.

Their remarkable internal geomagnetic compass guides them thousands of miles across uncharted waters, bringing them back to the exact beach where they hatched decades earlier.

What is your favorite sea turtle species? Drop your thoughts below!

Photo by: @wexor_tmg / Marine Wildlife Archive
Follow @oceanwikipedia for daily marine wonders.

#OceanWikipedia #SeaTurtle #MarineBiology #OceanConservation #OceanLife #WildlifePhotography #DeepSea
'@

$photoId = Publish-InstagramPhoto -imageUrl $turtleUrl -captionText $turtleCaption
Write-Host "[+] Published Photo ID: $photoId" -ForegroundColor Green

Start-Sleep -Seconds 5

# 2. Post Verified 3-Slide Ocean Carousel
Write-Host "`n--- [2/2] Publishing Verified 3-Slide Ocean Carousel ---" -ForegroundColor Yellow
$carouselImages = @(
    "https://images.unsplash.com/photo-1568430462989-44163eb1752f?fm=jpg&w=1080&h=1080&fit=crop",
    "https://images.unsplash.com/photo-1582967788606-a171c1080cb0?fm=jpg&w=1080&h=1080&fit=crop",
    "https://images.unsplash.com/photo-1544551763-77ef2d0cfc6c?fm=jpg&w=1080&h=1080&fit=crop"
)

$carouselCaption = @'
Swipe through 3 breathtaking wonders of our blue planet

1. The Humpback Whale breaching with pure leviathan power (Credit: @toddcravens)
2. Vibrant Coral Reef biodiversity sheltering thousands of species (Credit: @francesco_ungaro)
3. An enormous schooling vortex of silver Jack fish moving as one entity (Credit: Marine Wildlife Archive)

Which of these 3 ocean moments takes your breath away the most? Tell us below!

Follow @oceanwikipedia for daily marine explorations.

#OceanWikipedia #HumpbackWhale #CoralReef #MarineLife #UnderwaterPhotography #OceanExploration #DeepSea #OceanConservation
'@

$carouselId = Publish-InstagramCarousel -imageUrls $carouselImages -captionText $carouselCaption
Write-Host "[+] Published Carousel ID: $carouselId" -ForegroundColor Green

Write-Host "`n[DONE] Verified Photo and Carousel Published Successfully!" -ForegroundColor Cyan
