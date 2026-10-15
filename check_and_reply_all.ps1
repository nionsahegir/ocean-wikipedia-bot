param (
    [switch]$Live = $true
)

$configPath = Join-Path $PSScriptRoot "config.json"
$config = Get-Content $configPath -Raw | ConvertFrom-Json

$igId = $config.instagram_business_id
$token = $config.page_access_token
$baseUrl = "https://graph.facebook.com/" + $config.api_version
$myUser = $config.instagram_username

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host " Checking & Replying to ALL Comments across all posts" -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan

# Load helper functions from ocean_manager.ps1
. "$PSScriptRoot\ocean_manager.ps1" -DryRun

$mediaRes = Invoke-RestMethod -Uri "$baseUrl/$igId/media" -Method Get -Body @{
    fields = "id,permalink,caption,comments_count,like_count"
    limit = "50"
    access_token = $token
}

Write-Host "[+] Fetched $($mediaRes.data.Count) total posts/reels from @$myUser." -ForegroundColor Green

$repliedCount = 0

foreach ($post in $mediaRes.data) {
    if ($post.comments_count -gt 0) {
        Write-Host "`nScanning Post: $($post.permalink) (Comments: $($post.comments_count))" -ForegroundColor Yellow
        $commentsRes = Invoke-RestMethod -Uri "$baseUrl/$($post.id)/comments" -Method Get -Body @{
            fields = "id,text,username,timestamp,replies{id,text,username}"
            access_token = $token
        }
        
        foreach ($c in $commentsRes.data) {
            $hasOurReply = $false
            if ($c.replies -and $c.replies.data) {
                foreach ($r in $c.replies.data) {
                    if ($r.username -eq $myUser) {
                        $hasOurReply = $true
                        break
                    }
                }
            }
            
            # Also ignore if comment is made by the account itself
            if ($c.username -eq $myUser) {
                $hasOurReply = $true
            }

            if (-not $hasOurReply) {
                $replyMsg = Generate-SmartReply -commentText $c.text -username $c.username
                Write-Host "  [UNREPLIED] @$($c.username): `"$($c.text)`"" -ForegroundColor White
                Write-Host "  -> Generated: `"$replyMsg`"" -ForegroundColor Cyan
                
                if ($Live) {
                    try {
                        $replyRes = Invoke-RestMethod -Uri "$baseUrl/$($c.id)/replies" -Method Post -Body @{
                            message = $replyMsg
                            access_token = $token
                        }
                        Write-Host "  -> [SENT LIVE!] Reply ID: $($replyRes.id)" -ForegroundColor Green
                        $repliedCount++
                        Start-Sleep -Seconds 2
                    } catch {
                        Write-Host "  -> [ERROR SENDING] $($_.Exception.Message)" -ForegroundColor Red
                    }
                }
            } else {
                Write-Host "  [ALREADY REPLIED] @$($c.username): `"$($c.text)`"" -ForegroundColor DarkGray
            }
        }
    }
}

Write-Host "`n==========================================================" -ForegroundColor Cyan
Write-Host " Done! Total newly replied comments: $repliedCount" -ForegroundColor Green
Write-Host "==========================================================" -ForegroundColor Cyan
