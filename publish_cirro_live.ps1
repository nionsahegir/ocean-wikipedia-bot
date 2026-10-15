. "$PSScriptRoot\auto_publisher.ps1"

$caption = @"
The deep-sea Cirroteuthidae octopus drifting gracefully across the abyssal floor, using its webbed arms like an underwater parachute.

Credit: @oceanstatement
Follow @oceanwikipedia for daily marine discoveries.

#deepsea #cirroteuthidae #octopus #marinelife #oceanlife #ocean
"@

$resId = Publish-InstagramReel -videoUrl "https://litter.catbox.moe/jypfo6.mp4" -captionText $caption
Write-Host "Reel Live ID: $resId"
