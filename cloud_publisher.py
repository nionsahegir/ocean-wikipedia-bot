import os
import json
import time
import random
import requests
import subprocess
from pathlib import Path

IG_BUSINESS_ID = "17841449823313081"
IG_USERNAME = "oceanwikipedia"
PAGE_ACCESS_TOKEN = os.getenv("IG_ACCESS_TOKEN", "").strip()

if not PAGE_ACCESS_TOKEN:
    PAGE_ACCESS_TOKEN = "EAAUKXPLCKhMBSt9KDG1mnbbqJg5PD2U1YpXa9W2iGFhRiyMLFOyMRw2HmZCSEWFeZA0KesZADzYSPVdZA6Ko4ZCUgjWa9CSZBd0QRpyt75oV8WyBU3pfMNmSm3GtS72pyFya2VlPJut1q6jLkH5ZAgi7pteNxuh8ZBAQWIEL0ZCFtKZAKB4nGfVLgCT3vOMW1gXZCnZAeANA659gQx65gxZCiZCTsZD"

TARGET_ACCOUNTS = ["oceanstatement", "ocean.autograph", "ocean_content", "oceana"]
BASE_URL = "https://graph.facebook.com/v19.0"

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
                        except Exception:
                            pass

def upload_to_host(file_path):
    print(f"[*] Uploading video file to public host: {file_path}")
    headers = {"User-Agent": "Mozilla/5.0"}
    
    # Provider 1: tmpfiles.org
    try:
        with open(file_path, "rb") as f:
            res = requests.post("https://tmpfiles.org/api/v1/upload", files={"file": f}, headers=headers, timeout=120)
        if res.status_code == 200:
            data = res.json()
            if "data" in data and "url" in data["data"]:
                dl_url = data["data"]["url"].replace("tmpfiles.org/", "tmpfiles.org/dl/")
                print(f"[+] Hosted on tmpfiles: {dl_url}")
                return dl_url
    except Exception as e:
        print(f"[!] tmpfiles error: {e}")

    # Provider 2: litterbox
    try:
        with open(file_path, "rb") as f:
            res = requests.post(
                "https://litterbox.catbox.moe/resources/internals/api.php",
                data={"reqtype": "fileupload", "time": "24h"},
                files={"fileToUpload": f},
                headers=headers,
                timeout=120
            )
        if res.status_code == 200 and res.text.strip().startswith("http"):
            url = res.text.strip()
            print(f"[+] Hosted on litterbox: {url}")
            return url
    except Exception as e:
        print(f"[!] litterbox error: {e}")

    raise Exception("All hosting upload providers failed.")

def publish_reel(video_url, caption):
    print(f"[*] Creating Reel container for IG ID {IG_BUSINESS_ID}...")
    url = f"{BASE_URL}/{IG_BUSINESS_ID}/media"
    res = requests.post(url, data={
        "media_type": "REELS",
        "video_url": video_url,
        "caption": caption,
        "access_token": PAGE_ACCESS_TOKEN
    }).json()
    
    if "id" not in res:
        raise Exception(f"Failed to create Reel container: {res}")
    
    container_id = res["id"]
    print(f"[+] Reel Container ID: {container_id}")
    
    status_url = f"{BASE_URL}/{container_id}?fields=status_code&access_token={PAGE_ACCESS_TOKEN}"
    for _ in range(50):
        time.sleep(6)
        st = requests.get(status_url).json()
        code = st.get("status_code")
        print(f"    Status: {code}")
        if code == "FINISHED":
            break
        elif code == "ERROR":
            raise Exception("Instagram video processing failed. Please check video format.")
            
    print(f"[*] Publishing Reel live to @{IG_USERNAME}...")
    pub_url = f"{BASE_URL}/{IG_BUSINESS_ID}/media_publish"
    pub_res = requests.post(pub_url, data={
        "creation_id": container_id,
        "access_token": PAGE_ACCESS_TOKEN
    }).json()
    
    if "id" in pub_res:
        print(f"[🎉 SUCCESS] Reel published live! Media ID: {pub_res['id']}")
        return pub_res["id"]
    raise Exception(f"Publish failed: {pub_res}")

def publish_story(media_url, is_video=False):
    print("[*] Creating Story container...")
    url = f"{BASE_URL}/{IG_BUSINESS_ID}/media"
    data = {"media_type": "STORIES", "access_token": PAGE_ACCESS_TOKEN}
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
        status_url = f"{BASE_URL}/{container_id}?fields=status_code&access_token={PAGE_ACCESS_TOKEN}"
        for _ in range(30):
            time.sleep(5)
            st = requests.get(status_url).json()
            if st.get("status_code") == "FINISHED":
                break
    else:
        time.sleep(4)
        
    pub_url = f"{BASE_URL}/{IG_BUSINESS_ID}/media_publish"
    pub_res = requests.post(pub_url, data={"creation_id": container_id, "access_token": PAGE_ACCESS_TOKEN}).json()
    if "id" in pub_res:
        print(f"[🎉 SUCCESS] Story published live! Media ID: {pub_res['id']}")
        return pub_res["id"]
    raise Exception(f"Publish failed: {pub_res}")

def get_already_posted_urls():
    history_file = Path("post_history.json")
    if history_file.exists():
        try:
            with open(history_file, "r", encoding="utf-8") as f:
                return json.load(f)
        except Exception:
            return []
    return []

def record_posted_url(url):
    history = get_already_posted_urls()
    if url not in history:
        history.append(url)
    with open("post_history.json", "w", encoding="utf-8") as f:
        json.dump(history[-100:], f, indent=2)

def extract_target_reels(username):
    print(f"[*] Extracting media links from @{username} via Playwright...")
    from playwright.sync_api import sync_playwright
    links = []
    with sync_playwright() as p:
        browser = p.chromium.launch(headless=True)
        context = browser.new_context(
            user_agent="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36"
        )
        page = context.new_page()
        page.goto(f"https://www.instagram.com/{username}/", timeout=60000)
        time.sleep(6)
        
        anchors = page.query_selector_all("a")
        for a in anchors:
            href = a.get_attribute("href")
            if href and ("/reel/" in href or "/p/" in href):
                full = f"https://www.instagram.com{href}" if href.startswith("/") else href
                if full not in links:
                    links.append(full)
        browser.close()
    return links

def curate_and_publish_reel():
    clean_old_files()
    posted_urls = get_already_posted_urls()
    
    target_accounts = list(TARGET_ACCOUNTS)
    random.shuffle(target_accounts)
    
    selected_url = None
    target_user = None
    
    for user in target_accounts:
        try:
            links = extract_target_reels(user)
            reel_links = [l for l in links if "/reel/" in l]
            for r in reel_links:
                if r not in posted_urls:
                    selected_url = r
                    target_user = user
                    break
            if selected_url:
                break
        except Exception as e:
            print(f"[Warning] Error extracting from @{user}: {e}")
            continue
            
    if not selected_url:
        print("[!] Picking top available reel...")
        selected_url = links[0] if links else "https://www.instagram.com/oceanstatement/reel/DeWqv0jvnDH/"
        target_user = "oceanstatement"

    print(f"\n[+] Selected Reel: {selected_url} from @{target_user}")
    
    Path("temp").mkdir(exist_ok=True)
    raw_video = Path("temp/download_raw.mp4")
    ready_video = Path("temp/reel_ready.mp4")
    
    if raw_video.exists(): raw_video.unlink()
    if ready_video.exists(): ready_video.unlink()
    
    desc_cmd = ["yt-dlp", "--dump-json", selected_url]
    desc_res = subprocess.run(desc_cmd, capture_output=True, text=True)
    original_desc = ""
    if desc_res.returncode == 0:
        try:
            meta = json.loads(desc_res.stdout)
            original_desc = meta.get("description", "")
        except Exception:
            pass

    # Download original MP4
    dl_cmd = ["yt-dlp", "-f", "mp4/best", "-o", str(raw_video), selected_url]
    subprocess.run(dl_cmd, check=True)
    
    # 100% Meta Instagram Guaranteed Standard: H.264 + AAC + yuv420p
    ff_cmd = [
        "ffmpeg", "-y", "-i", str(raw_video),
        "-vf", "scale='min(1080,iw)':-2,format=yuv420p",
        "-c:v", "libx264", "-preset", "veryfast", "-crf", "22",
        "-af", "volume=0.85,afade=t=out:st=15:d=2",
        "-c:a", "aac", "-b:a", "128k",
        str(ready_video)
    ]
    subprocess.run(ff_cmd, check=True)
    
    first_line = "Discovering the mesmerizing depths of our living planet."
    if original_desc:
        lines = [l.strip() for l in original_desc.split("\n") if l.strip() and not l.startswith("#")]
        if lines:
            first_line = lines[0]
            
    caption = f"{first_line}\n\nCredit: @{target_user}\nFollow @{IG_USERNAME} for daily marine discoveries.\n\n#oceanlife #marinelife #deepsea #marinebiology #underwater #ocean"
    
    public_url = upload_to_host(str(ready_video))
    media_id = publish_reel(public_url, caption)
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
