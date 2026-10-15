# Outbound Engagement Playbook for @oceanwikipedia
# Purpose: Pre-posting 15-minute engagement sprint on top niche pages

$today = Get-Date -Format "yyyy-MM-dd"

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host " 🌊 Ocean Wikipedia: 15-Min Pre-Posting Outbound Sprint" -ForegroundColor Cyan
Write-Host " Date: $today" -ForegroundColor Yellow
Write-Host " Instructions: Open these 3 pages on your phone 15m before posting," -ForegroundColor White
Write-Host " drop 1 comment below to boost your profile activity authentically!" -ForegroundColor White
Write-Host "==========================================================" -ForegroundColor Cyan

$targets = @(
    @{
        Account = "@noaaocean (NOAA Ocean Exploration)"
        Topic = "Deep sea submersibles / Hydrothermal vents"
        Draft = "The bathymetric data from Okeanos Explorer submersibles continues to rewrite what we thought was possible in extreme environments. Fascinating documentation as always! 🌊🔬"
    },
    @{
        Account = "@bbcearth (BBC Earth)"
        Topic = "Marine wildlife / Whale migrations"
        Draft = "Marine migration corridors are so vital to protect, especially against industrial shipping lanes and acoustic disruption. Majestic capture! 🐋"
    },
    @{
        Account = "@oceana (Oceana Conservation)"
        Topic = "Plastic pollution & Marine Protected Areas (MPAs)"
        Draft = "Expanding Marine Protected Areas (MPAs) is genuinely the single highest-leverage policy we have to reverse biodiversity loss. 100% standing behind this initiative! 💙"
    }
)

foreach ($t in $targets) {
    Write-Host "`n🎯 Target: $($t.Account)" -ForegroundColor Green
    Write-Host "   Topic: $($t.Topic)" -ForegroundColor Gray
    Write-Host "   Ready-to-Paste Comment:" -ForegroundColor White
    Write-Host "   `"$($t.Draft)`"" -ForegroundColor Yellow
}

Write-Host "`n[+] Keep this 15-minute sprint human, authentic, and fast! 🚀" -ForegroundColor Cyan
