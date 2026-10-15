. "$PSScriptRoot\auto_publisher.ps1"

$caption = @"
Humpback whales possess the longest pectoral fins of any marine mammal, spanning up to one-third of their entire body length.

Credit: @ocean.autograph
Follow @oceanwikipedia for daily marine discoveries.

#humpbackwhale #oceanlife #marinelife #deepsea #whale #ocean
"@

$resId = Publish-InstagramReel -videoUrl "https://litter.catbox.moe/sx1unp.mp4" -captionText $caption
Write-Host "Reel Live ID: $resId"
