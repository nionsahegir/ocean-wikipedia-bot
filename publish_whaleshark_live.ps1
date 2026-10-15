. "$PSScriptRoot\auto_publisher.ps1"

$caption = @"
Whale sharks are the gentle giants of the open sea, growing up to 40 feet while feeding entirely on tiny plankton.

Credit: @oceanstatement
Follow @oceanwikipedia for daily marine discoveries.

#whaleshark #ningaloo #marinelife #oceanlife #deepsea #ocean
"@

$resId = Publish-InstagramReel -videoUrl "https://litter.catbox.moe/l18gsl.mp4" -captionText $caption
Write-Host "Reel Live ID: $resId"
