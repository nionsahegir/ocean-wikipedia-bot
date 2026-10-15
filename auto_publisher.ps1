param (
    [string]$Type = "photo",
    [string]$MediaUrl = "",
    [string]$Caption = ""
)

$configPath = Join-Path $PSScriptRoot "config.json"
$config = Get-Content $configPath -Raw | ConvertFrom-Json

$igId = $config.instagram_business_id
$token = $config.page_access_token
$baseUrl = "https://graph.facebook.com/$($config.api_version)"

function Publish-InstagramPhoto([string]$imageUrl, [string]$captionText) {
    Write-Host "[*] Creating photo container on Instagram..." -ForegroundColor Cyan
    $createUrl = "$baseUrl/$igId/media"
    $body = @{
        image_url = $imageUrl
        caption = $captionText
        access_token = $token
    }
    
    $createRes = Invoke-RestMethod -Uri $createUrl -Method Post -Body $body
    $containerId = $createRes.id
    Write-Host "[+] Container created successfully: $containerId" -ForegroundColor Green
    
    # Wait for processing
    Start-Sleep -Seconds 3
    
    Write-Host "[*] Publishing photo to @$($config.instagram_username)..." -ForegroundColor Cyan
    $publishUrl = "$baseUrl/$igId/media_publish"
    $pubBody = @{
        creation_id = $containerId
        access_token = $token
    }
    $pubRes = Invoke-RestMethod -Uri $publishUrl -Method Post -Body $pubBody
    Write-Host "[🎉 SUCCESS] Photo published live! Media ID: $($pubRes.id)" -ForegroundColor Green
    return $pubRes.id
}

function Publish-InstagramReel([string]$videoUrl, [string]$captionText) {
    Write-Host "[*] Creating Reel container on Instagram..." -ForegroundColor Cyan
    $createUrl = "$baseUrl/$igId/media"
    $body = @{
        media_type = "REELS"
        video_url = $videoUrl
        caption = $captionText
        access_token = $token
    }
    
    $createRes = Invoke-RestMethod -Uri $createUrl -Method Post -Body $body
    $containerId = $createRes.id
    Write-Host "[+] Reel Container created: $containerId" -ForegroundColor Green
    
    # Poll container status until FINISHED
    Write-Host "[*] Waiting for Instagram to process video..." -ForegroundColor Yellow
    $statusUrl = "$baseUrl/$containerId`?fields=status_code&access_token=$token"
    
    for ($i = 0; $i -lt 30; $i++) {
        Start-Sleep -Seconds 5
        $statusRes = Invoke-RestMethod -Uri $statusUrl -Method Get
        Write-Host "    Status: $($statusRes.status_code)" -ForegroundColor Gray
        if ($statusRes.status_code -eq "FINISHED") {
            break
        } elseif ($statusRes.status_code -eq "ERROR") {
            throw "Instagram video processing failed."
        }
    }
    
    Write-Host "[*] Publishing Reel to @$($config.instagram_username)..." -ForegroundColor Cyan
    $publishUrl = "$baseUrl/$igId/media_publish"
    $pubBody = @{
        creation_id = $containerId
        access_token = $token
    }
    $pubRes = Invoke-RestMethod -Uri $publishUrl -Method Post -Body $pubBody
    Write-Host "[🎉 SUCCESS] Reel published live! Media ID: $($pubRes.id)" -ForegroundColor Green
    return $pubRes.id
}

function Publish-InstagramCarousel([string[]]$imageUrls, [string]$captionText) {
    Write-Host "[*] Creating carousel items on Instagram..." -ForegroundColor Cyan
    $childrenIds = @()
    foreach ($url in $imageUrls) {
        $createUrl = "$baseUrl/$igId/media"
        $body = @{
            image_url = $url
            is_carousel_item = $true
            access_token = $token
        }
        $itemRes = Invoke-RestMethod -Uri $createUrl -Method Post -Body $body
        $childrenIds += $itemRes.id
        Write-Host "  -> Created carousel item: $($itemRes.id)" -ForegroundColor Gray
    }
    
    Write-Host "[*] Creating Carousel container..." -ForegroundColor Cyan
    $carUrl = "$baseUrl/$igId/media"
    $carBody = @{
        media_type = "CAROUSEL"
        children = ($childrenIds -join ",")
        caption = $captionText
        access_token = $token
    }
    $carRes = Invoke-RestMethod -Uri $carUrl -Method Post -Body $carBody
    $containerId = $carRes.id
    Write-Host "[+] Carousel container created: $containerId" -ForegroundColor Green
    
    Start-Sleep -Seconds 3
    
    Write-Host "[*] Publishing Carousel to @$($config.instagram_username)..." -ForegroundColor Cyan
    $pubUrl = "$baseUrl/$igId/media_publish"
    $pubBody = @{
        creation_id = $containerId
        access_token = $token
    }
    $pubRes = Invoke-RestMethod -Uri $pubUrl -Method Post -Body $pubBody
    Write-Host "[🎉 SUCCESS] Carousel published live! Media ID: $($pubRes.id)" -ForegroundColor Green
    return $pubRes.id
}

function Publish-InstagramStory([string]$mediaUrl, [string]$storyType = "IMAGE") {
    Write-Host "[*] Creating Instagram Story container ($storyType)..." -ForegroundColor Cyan
    $createUrl = "$baseUrl/$igId/media"
    $body = @{
        media_type = "STORIES"
        access_token = $token
    }
    if ($storyType -eq "VIDEO") {
        $body.video_url = $mediaUrl
    } else {
        $body.image_url = $mediaUrl
    }
    
    $createRes = Invoke-RestMethod -Uri $createUrl -Method Post -Body $body
    $containerId = $createRes.id
    Write-Host "[+] Story Container created: $containerId" -ForegroundColor Green
    
    # Poll if video or small wait if image
    if ($storyType -eq "VIDEO") {
        Write-Host "[*] Waiting for Instagram to process Story video..." -ForegroundColor Yellow
        $statusUrl = "$baseUrl/$containerId`?fields=status_code&access_token=$token"
        for ($i = 0; $i -lt 30; $i++) {
            Start-Sleep -Seconds 5
            $statusRes = Invoke-RestMethod -Uri $statusUrl -Method Get
            Write-Host "    Status: $($statusRes.status_code)" -ForegroundColor Gray
            if ($statusRes.status_code -eq "FINISHED") {
                break
            } elseif ($statusRes.status_code -eq "ERROR") {
                throw "Instagram Story video processing failed."
            }
        }
    } else {
        Start-Sleep -Seconds 4
    }
    
    Write-Host "[*] Publishing Story to @$($config.instagram_username)..." -ForegroundColor Cyan
    $publishUrl = "$baseUrl/$igId/media_publish"
    $pubBody = @{
        creation_id = $containerId
        access_token = $token
    }
    $pubRes = Invoke-RestMethod -Uri $publishUrl -Method Post -Body $pubBody
    Write-Host "[🎉 SUCCESS] Story published live! Media ID: $($pubRes.id)" -ForegroundColor Green
    return $pubRes.id
}

function Clean-OldFiles([int]$daysToKeep = 2) {
    $cutoff = (Get-Date).AddDays(-$daysToKeep)
    $dirs = @(
        (Join-Path $PSScriptRoot "temp"),
        (Join-Path $PSScriptRoot "content")
    )
    $protectedExtensions = @(".ps1", ".py", ".json", ".md", ".txt")
    
    foreach ($d in $dirs) {
        if (Test-Path $d) {
            $files = Get-ChildItem -Path $d -Recurse -File | Where-Object { 
                $_.LastWriteTime -lt $cutoff -and 
                $protectedExtensions -notcontains $_.Extension.ToLower()
            }
            foreach ($f in $files) {
                Remove-Item $f.FullName -Force -ErrorAction SilentlyContinue
                Write-Host "[Storage Cleanup] Pruned 2+ day old temporary media: $($f.Name)" -ForegroundColor DarkGray
            }
        }
    }
}

Clean-OldFiles -daysToKeep 2

