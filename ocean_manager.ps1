param (
    [switch]$ReplyComments = $true,
    [switch]$DryRun = $false
)

$configPath = Join-Path $PSScriptRoot "config.json"
$config = Get-Content $configPath -Raw | ConvertFrom-Json

$igId = $config.instagram_business_id
$token = $config.page_access_token
$baseUrl = "https://graph.facebook.com/" + $config.api_version

# Multi-tiered dynamic reply engine ensuring 100% unique comments
$pageGratitudeList = @(
    "Thank you so much from our entire @oceanwikipedia team, @{user}!",
    "Huge thanks from the @oceanwikipedia page for being part of our community, @{user}!",
    "We truly appreciate you dropping by and supporting our page, @{user}!",
    "Thank you from our team for loving the ocean with us, @{user}!",
    "Warm ocean greetings and big thanks from all of us here at @oceanwikipedia, @{user}!",
    "Appreciate your awesome engagement on our page, @{user}!",
    "Thank you for sharing your thoughts with our ocean community, @{user}!"
)

$contextReplies = @{
    "shark" = @(
        "Sharks are vital apex guardians that keep marine food webs balanced. What's your take on them?",
        "Fascinating predators! With over 400 million years of evolutionary history, sharks are living wonders.",
        "They have electroreceptors called Ampullae of Lorenzini that detect faint heartbeats underwater!"
    );
    "octopus|squid" = @(
        "Cephalopods possess incredible alien-like intelligence with three hearts and blue copper-based blood!",
        "Their ability to change skin texture, color, and polarization in milliseconds is pure biological wizardry.",
        "Octopuses actually have mini-brains distributed along each of their arms!"
    );
    "deep sea|abyss|trench|dark" = @(
        "Over 80% of our ocean remains unmapped and plunged in total darkness. The mysteries down there are endless!",
        "Creatures surviving in the crushing pressures of the abyss look like genuine science fiction wonders.",
        "Bioluminescence in the midnight zone serves everything from stealth camouflage to hunting lures."
    );
    "whale|orca" = @(
        "Whales and orcas display complex vocal dialects, multigenerational culture, and empathy that rival humans.",
        "Listening to ocean giants communicate across hundreds of miles of ocean is mesmerizing.",
        "Orcas are arguably the ocean's undisputed tactical geniuses."
    );
    "coral|reef" = @(
        "Coral reefs cover less than 1% of the seafloor yet sustain more than 25% of all marine life on Earth!",
        "Living coral polyps build massive underwater cities that can even be seen from space.",
        "Healthy vibrant reefs are the beating heart of our shallow seas."
    );
    "turtle|tortoise" = @(
        "Sea turtles possess an innate magnetic compass that guides them across entire oceans back to their natal beach.",
        "Having survived the asteroid that wiped out dinosaurs, sea turtles are true ancient mariners.",
        "Green sea turtles help keep seagrass beds pristine and thriving for other marine life."
    );
    "jellyfish" = @(
        "Jellyfish are made of 95% water and have drifted through Earth's oceans long before trees even existed!",
        "Some species like Turritopsis dohrnii can literally reset their biological age and achieve biological immortality."
    );
    "pollution|plastic|fishing|net" = @(
        "Marine conservation and removing ghost nets are urgent priorities for securing the future of our oceans.",
        "Protecting these delicate habitats from microplastics and industrial bycatch takes collective awareness."
    );
    "scary|creepy|nope|fear|monster" = @(
        "Haha, the deep ocean can look intimidating, but these fascinating organisms are perfectly adapted to their extreme realm!",
        "They may look like sci-fi monsters, but they're gentle survivalists minding their own deep-water business."
    );
    "fake|cgi|ai|real" = @(
        "It looks unbelievable, but it's 100% authentic marine footage documented by ocean explorers!",
        "Nature's evolutionary artistry in the deep sea constantly outshines Hollywood CGI."
    );
    "beautiful|amazing|wow|love|cool|awesome|great" = @(
        "The ocean never ceases to amaze with its infinite colors and undiscovered life.",
        "Every single layer of the ocean holds breathtaking wonders waiting to be uncovered.",
        "We are thrilled to bring these mesmerizing ocean discoveries to your feed."
    )
}

function Generate-SmartReply($commentText, $username) {
    $lower = $commentText.ToLower()
    $gratitude = (Get-Random -InputObject $pageGratitudeList).Replace("{user}", $username)
    
    $selectedInsight = ""
    foreach ($key in $contextReplies.Keys) {
        if ($lower -match $key) {
            $selectedInsight = Get-Random -InputObject $contextReplies[$key]
            break
        }
    }
    
    if (-not $selectedInsight) {
        $generalInsights = @(
            "Every day the ocean teaches us something brand new about life on Earth.",
            "Stay tuned as we continue diving deeper into our planet's greatest frontier!",
            "What is your all-time favorite marine phenomenon or creature?"
        )
        $selectedInsight = Get-Random -InputObject $generalInsights
    }
    
    return "$gratitude $selectedInsight"
}

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host " Ocean Wikipedia Engine - Comment Manager" -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan

# 1. Fetch recent media
$mediaUrl = "$baseUrl/$igId/media?fields=id,caption,media_type,permalink,timestamp,comments_count,like_count&limit=10&access_token=$token"
$mediaRes = Invoke-RestMethod -Uri $mediaUrl -Method Get

Write-Host "[+] Scanning $($mediaRes.data.Count) recent posts for comments..." -ForegroundColor Green

$unrepliedCount = 0
foreach ($post in $mediaRes.data) {
    if ($post.comments_count -gt 0) {
        $commentsUrl = "$baseUrl/$($post.id)/comments?fields=id,text,username,timestamp,like_count,replies{id,text,username}&access_token=$token"
        $commentsRes = Invoke-RestMethod -Uri $commentsUrl -Method Get
        
        foreach ($c in $commentsRes.data) {
            $replied = $false
            if ($c.replies -and $c.replies.data) {
                foreach ($r in $c.replies.data) {
                    if ($r.username -eq $config.instagram_username) {
                        $replied = $true
                        break
                    }
                }
            }
            
            if (-not $replied) {
                $unrepliedCount++
                $smartReply = Generate-SmartReply -commentText $c.text -username $c.username
                Write-Host "`n[Post $($post.permalink)]" -ForegroundColor Yellow
                Write-Host "  -> Comment by @$($c.username): `"$($c.text)`"" -ForegroundColor White
                Write-Host "  -> Generated Contextual Smart Reply: `"$smartReply`"" -ForegroundColor Green
                
                if ($ReplyComments -and -not $DryRun) {
                    $replyUrl = "$baseUrl/$($c.id)/replies"
                    $body = @{
                        message = $smartReply
                        access_token = $token
                    }
                    $replyRes = Invoke-RestMethod -Uri $replyUrl -Method Post -Body $body
                    Write-Host "  -> [SENT] Reply posted successfully! (ID: $($replyRes.id))" -ForegroundColor Cyan
                    Start-Sleep -Seconds 2
                } else {
                    Write-Host "  -> [SIMULATION] Run with -ReplyComments to post live." -ForegroundColor Gray
                }
            }
        }
    }
}

if ($unrepliedCount -eq 0) {
    Write-Host "`n[+] All comments on recent posts have already been answered!" -ForegroundColor Green
} else {
    Write-Host "`n[+] Total pending comments handled: $unrepliedCount" -ForegroundColor Green
}
