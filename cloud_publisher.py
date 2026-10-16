import os
import json
import time
import random
import requests
import subprocess
from pathlib import Path

raw_token = os.getenv("IG_ACCESS_TOKEN", "")
clean_token = "".join(raw_token.split())

CONFIG = {
    "instagram_business_id": str(os.getenv("IG_BUSINESS_ID", "17841449823313081")).strip(),
    "page_access_token": clean_token,
    "instagram_username": str(os.getenv("IG_USERNAME", "oceanwikipedia")).strip(),
    "api_version": "v19.0"
}

TARGET_ACCOUNTS = [
    "oceanstatement",
    "ocean.autograph",
    "ocean_content",
    "oceana",
    "paulnicklen",
    "nautiluslive",
    "mission_blue",
    "scubadivingmag"
]

BASE_URL = f"https://graph.facebook.com/{CONFIG['api_version']}"
RECYCLE_COOLDOWN_DAYS = 25  # Re-post eligible after 25 days cooldown

def clean_old_files(days=2):
    cutoff = time.time() - (days * 86400)
    for folder in ["temp", "content"]:
        p = Path(folder)
        if p.exists():
            for f in p.glob("*"):
                if f.is_file() and f.suffix.lower() not in [".py", ".json", ".txt", ".md", ".yml", ".yaml"]:
                    if f.stat().st_mtime < cutoff:
                        try:
                            f.unlink()
                            print(f"[Cleanup] Removed old temporary media: {f.name}")
                        except Exception:
                            pass

def get_verified_instagram_id():
    configured_id = str(CONFIG.get("instagram_business_id", "")).strip()
    token = CONFIG.get("page_access_token", "").strip()
    
    if configured_id == "17841449823313081":
        return configured_id
        
    if configured_id:
        try:
            res = requests.get(
                f"{BASE_URL}/{configured_id}",
                params={"fields": "instagram_business_account", "access_token": token},
                timeout=15
            ).json()
            if "instagram_business_account" in res and "id" in res["instagram_business_account"]:
                resolved_id = res["instagram_business_account"]["id"]
                print(f"[+] Auto-resolved connected Instagram Business Account ID: {resolved_id}")
                return resolved_id
        except Exception as e:
            print(f"[!] Warning resolving IG ID from configured ID: {e}")
            
    return "17841449823313081"

def upload_and_publish_reel_resumable(video_path, caption):
    """
    Direct Resumable Binary Upload to Meta's rupload.facebook.com.
    Zero third-party file host dependency (no catbox, no tmpfiles).
    """
    ig_id = get_verified_instagram_id()
    token = "".join(CONFIG["page_access_token"].split())
    file_size = os.path.getsize(video_path)
    
    print(f"[*] Target Instagram Business ID: {ig_id}")
    print(f"[*] Step 1: Initializing Resumable Upload session for {file_size} bytes...")
    init_url = f"{BASE_URL}/{ig_id}/media"
    init_res = requests.post(init_url, data={
        "media_type": "REELS",
        "upload_type": "resumable",
        "caption": caption,
        "access_token": token
    }).json()
    
    if "id" not in init_res:
        raise Exception(f"Failed to initialize resumable upload session: {init_res}")
        
    container_id = init_res["id"]
    upload_uri = init_res.get("uri", f"https://rupload.facebook.com/ig-api-upload/{CONFIG['api_version']}/{container_id}")
    print(f"[+] Container ID: {container_id}")
    print(f"[+] Direct Meta Upload URI: {upload_uri}")
    
    print(f"[*] Step 2: Streaming video binary directly to Meta servers (rupload.facebook.com)...")
    headers = {
        "Authorization": f"OAuth {token}",
        "offset": "0",
        "file_size": str(file_size),
        "Content-Type": "application/octet-stream"
    }
    
    with open(video_path, "rb") as f:
        upload_res = requests.post(upload_uri, headers=headers, data=f, timeout=300)
        
    if upload_res.status_code not in [200, 201]:
        raise Exception(f"Meta binary upload failed (HTTP {upload_res.status_code}): {upload_res.text}")
    print("[+] Video bytes successfully accepted by Meta servers!")
    
    print("[*] Step 3: Waiting for Meta container processing...")
    status_url = f"{BASE_URL}/{container_id}?fields=status_code,status&access_token={token}"
    for i in range(45):
        time.sleep(5)
        st = requests.get(status_url).json()
        code = st.get("status_code")
        print(f"    Status Check {i+1}: {code}")
        if code == "FINISHED":
            break
        elif code == "ERROR":
            raise Exception(f"Instagram media processing error: {st}")
    else:
        print("[!] Warning: Container timed out waiting for FINISHED, attempting publish anyway...")
        
    print("[*] Step 4: Publishing Reel live to Instagram...")
    pub_url = f"{BASE_URL}/{ig_id}/media_publish"
    pub_res = requests.post(pub_url, data={
        "creation_id": container_id,
        "access_token": token
    }).json()
    
    if "id" in pub_res:
        print(f"[🎉 SUCCESS] Reel published live! Media ID: {pub_res['id']}")
        return pub_res["id"]
    raise Exception(f"Publish failed: {pub_res}")

def publish_story(media_url, is_video=False):
    ig_id = get_verified_instagram_id()
    token = CONFIG["page_access_token"]
    
    print("[*] Creating Story container...")
    url = f"{BASE_URL}/{ig_id}/media"
    data = {
        "media_type": "STORIES",
        "access_token": token
    }
    if is_video:
        data["video_url"] = media_url
    else:
        data["image_url"] = media_url
        
    res = requests.post(url, data=data).json()
    if "id" not in res:
        raise Exception(f"Failed to create Story container: {res}")
        
    container_id = res["id"]
    print(f"[+] Story Container ID: {container_id}")
    
    if is_video:
        status_url = f"{BASE_URL}/{container_id}?fields=status_code&access_token={token}"
        for _ in range(30):
            time.sleep(5)
            st = requests.get(status_url).json()
            if st.get("status_code") == "FINISHED":
                break
    else:
        time.sleep(4)
        
    pub_url = f"{BASE_URL}/{ig_id}/media_publish"
    pub_res = requests.post(pub_url, data={
        "creation_id": container_id,
        "access_token": token
    }).json()
    
    if "id" in pub_res:
        print(f"[🎉 SUCCESS] Story published live! Media ID: {pub_res['id']}")
        return pub_res["id"]
    raise Exception(f"Publish failed: {pub_res}")

def load_post_history():
    history_file = Path("post_history.json")
    if history_file.exists():
        try:
            with open(history_file, "r", encoding="utf-8-sig") as f:
                data = json.load(f)
                if isinstance(data, dict):
                    return data
                elif isinstance(data, list):
                    now = int(time.time())
                    return {url: now for url in data}
        except Exception:
            return {}
    return {}

def record_posted_url(url):
    history = load_post_history()
    history[url] = int(time.time())
    with open("post_history.json", "w", encoding="utf-8") as f:
        json.dump(history, f, indent=2)

def load_curated_vault():
    vault_file = Path("curated_vault.json")
    if vault_file.exists():
        try:
            with open(vault_file, "r", encoding="utf-8-sig") as f:
                return json.load(f)
        except Exception as e:
            print(f"[!] Warning reading curated_vault.json: {e}")
    return {}

def select_candidate_reel():
    vault = load_curated_vault()
    history = load_post_history()
    current_time = time.time()
    cooldown_seconds = RECYCLE_COOLDOWN_DAYS * 86400
    
    print(f"[*] Post history count: {len(history)} items")
    
    accounts = list(TARGET_ACCOUNTS)
    random.shuffle(accounts)
    
    # Pass 1: Fresh, unposted reels
    for acc in accounts:
        reels = vault.get(acc, [])
        shuffled = list(reels)
        random.shuffle(shuffled)
        for r in shuffled:
            if r not in history:
                print(f"[+] Selected fresh reel from @{acc}: {r}")
                return r, acc
                
    # Pass 2: Cooldown recycling (>= 25 days)
    print(f"[*] All reels in vault have been posted once. Evaluating 25-day cooldown recycling...")
    eligible_recycled = []
    for acc in accounts:
        reels = vault.get(acc, [])
        for r in reels:
            last_posted = history.get(r, 0)
            if (current_time - last_posted) >= cooldown_seconds:
                eligible_recycled.append((r, acc, last_posted))
                
    if eligible_recycled:
        eligible_recycled.sort(key=lambda x: x[2])
        chosen = eligible_recycled[0]
        days_ago = (current_time - chosen[2]) / 86400
        print(f"[+] Recycling top viral reel from @{chosen[1]} (posted {days_ago:.1f} days ago): {chosen[0]}")
        return chosen[0], chosen[1]
        
    # Pass 3: Fallback if cooldown not elapsed yet
    fallback_list = []
    for acc in accounts:
        reels = vault.get(acc, [])
        for r in reels:
            fallback_list.append((r, acc, history.get(r, 0)))
            
    if fallback_list:
        fallback_list.sort(key=lambda x: x[2])
        return fallback_list[0][0], fallback_list[0][1]

    return "https://www.instagram.com/oceanstatement/reel/DehyI9yNW4p/", "oceanstatement"

def curate_and_publish_reel():
    clean_old_files()
    
    selected_url, target_user = select_candidate_reel()
    print(f"\n[+] Active Target Reel: {selected_url} (Creator: @{target_user})")
    
    Path("temp").mkdir(exist_ok=True)
    raw_video = Path("temp/download_raw.mp4")
    ready_video = Path("temp/reel_ready.mp4")
    
    if raw_video.exists(): raw_video.unlink()
    if ready_video.exists(): ready_video.unlink()
    
    print("[*] Fetching metadata with yt-dlp...")
    desc_cmd = ["yt-dlp", "--dump-json", selected_url]
    desc_res = subprocess.run(desc_cmd, capture_output=True, text=True)
    original_desc = ""
    if desc_res.returncode == 0:
        try:
            meta = json.loads(desc_res.stdout)
            original_desc = meta.get("description", "")
        except Exception:
            pass

    print("[*] Downloading video with yt-dlp...")
    dl_cmd = ["yt-dlp", "-f", "mp4/best", "-o", str(raw_video), selected_url]
    subprocess.run(dl_cmd, check=True)
    
    # 3. Audio & Video Normalization for Meta Graph API compliance:
    print("[*] Processing video with FFmpeg (+faststart, H.264/AAC, 90s cap)...")
    ff_cmd = [
        "ffmpeg", "-y", "-i", str(raw_video),
        "-t", "90",
        "-c:v", "libx264", "-preset", "fast", "-crf", "23", "-pix_fmt", "yuv420p",
        "-c:a", "aac", "-b:a", "128k",
        "-af", "volume=0.85",
        "-movflags", "+faststart",
        str(ready_video)
    ]
    subprocess.run(ff_cmd, check=True)
    
    # 4. Generate clean, short, natural caption
    first_line = "Discovering the mesmerizing depths of our living planet."
    if original_desc:
        lines = [l.strip() for l in original_desc.split("\n") if l.strip() and not l.startswith("#") and not l.lower().startswith("follow") and not l.lower().startswith("credit")]
        if lines:
            first_line = lines[0]
            
    caption = f"{first_line}\n\nCredit: @{target_user}\nFollow @{CONFIG['instagram_username']} for daily ocean wonders.\n\n#oceanlife #marinelife #deepsea #marinebiology #underwater #ocean"
    
    # 5. Direct Meta Resumable Binary Upload
    media_id = upload_and_publish_reel_resumable(str(ready_video), caption)
    record_posted_url(selected_url)
    print(f"[Done] Reel publication finished successfully! Live Media ID: {media_id}")
    return media_id

def curate_and_publish_story():
    clean_old_files()
    ocean_story_images = [
        "https://images.unsplash.com/photo-1544551763-46a013bb70d5?auto=format&fit=crop&w=1080&h=1920&q=80",
        "https://images.unsplash.com/photo-1682687220063-4742bd7fd538?auto=format&fit=crop&w=1080&h=1920&q=80",
        "https://images.unsplash.com/photo-1518709268805-4e9042af9f23?auto=format&fit=crop&w=1080&h=1920&q=80"
    ]
    img = random.choice(ocean_story_images)
    print(f"[*] Publishing ocean daily story...")
    return publish_story(img, is_video=False)

if __name__ == "__main__":
    import sys
    action = sys.argv[1] if len(sys.argv) > 1 else "reel"
    if action == "story":
        curate_and_publish_story()
    else:
        curate_and_publish_reel()
