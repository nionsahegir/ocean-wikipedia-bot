. "$PSScriptRoot\auto_publisher.ps1"

$caption = @"
The deep-sea Dumbo octopus gracefully navigates the dark abyss using ear-like fins, thriving at depths over 3,000 meters.

Credit: @oceana
Follow @oceanwikipedia for daily marine discoveries.

#dumbooctopus #deepsea #cephalopod #marinelife #oceanlife #ocean
"@

$resId = Publish-InstagramReel -videoUrl "https://litter.catbox.moe/1puray.mp4" -captionText $caption
Write-Host "Reel Live ID: $resId"
