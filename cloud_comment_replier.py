import os
import json
import time
import random
import requests

raw_token = os.getenv("IG_ACCESS_TOKEN", "")
clean_token = "".join(raw_token.split())

CONFIG = {
    "instagram_business_id": str(os.getenv("IG_BUSINESS_ID", "17841449823313081")).strip(),
    "page_access_token": clean_token,
    "instagram_username": str(os.getenv("IG_USERNAME", "oceanwikipedia")).strip(),
    "api_version": "v19.0"
}

BASE_URL = f"https://graph.facebook.com/{CONFIG['api_version']}"

PAGE_GRATITUDE_LIST = [
    "Thank you so much from our entire @oceanwikipedia team, @{user}!",
    "Huge thanks from the @oceanwikipedia page for being part of our community, @{user}!",
    "We truly appreciate you dropping by and supporting our page, @{user}!",
    "Thank you from our team for loving the ocean with us, @{user}!",
    "Warm ocean greetings and big thanks from all of us here at @oceanwikipedia, @{user}!",
    "Appreciate your awesome engagement on our page, @{user}!",
    "Thank you for sharing your thoughts with our ocean community, @{user}!"
]

CONTEXT_REPLIES = {
    "shark": [
        "Sharks are vital apex guardians that keep marine food webs balanced. What's your take on them?",
        "Fascinating predators! With over 400 million years of evolutionary history, sharks are living wonders.",
        "They have electroreceptors called Ampullae of Lorenzini that detect faint heartbeats underwater!"
    ],
    "octopus|squid": [
        "Cephalopods possess incredible alien-like intelligence with three hearts and blue copper-based blood!",
        "Their ability to change skin texture, color, and polarization in milliseconds is pure biological wizardry.",
        "Octopuses actually have mini-brains distributed along each of their arms!"
    ],
    "deep sea|abyss|trench|dark": [
        "Over 80% of our ocean remains unmapped and plunged in total darkness. The mysteries down there are endless!",
        "Creatures surviving in the crushing pressures of the abyss look like genuine science fiction wonders.",
        "Bioluminescence in the midnight zone serves everything from stealth camouflage to hunting lures."
    ],
    "whale|orca": [
        "Whales and orcas display complex vocal dialects, multigenerational culture, and empathy that rival humans.",
        "Listening to ocean giants communicate across hundreds of miles of ocean is mesmerizing.",
        "Orcas are arguably the ocean's undisputed tactical geniuses."
    ],
    "coral|reef": [
        "Coral reefs cover less than 1% of the seafloor yet sustain more than 25% of all marine life on Earth!",
        "Living coral polyps build massive underwater cities that can even be seen from space.",
        "Healthy vibrant reefs are the beating heart of our shallow seas."
    ],
    "turtle|tortoise": [
        "Sea turtles possess an innate magnetic compass that guides them across entire oceans back to their natal beach.",
        "Having survived the asteroid that wiped out dinosaurs, sea turtles are true ancient mariners.",
        "Green sea turtles help keep seagrass beds pristine and thriving for other marine life."
    ],
    "beautiful|amazing|wow|love|cool|awesome|great": [
        "The ocean never ceases to amaze with its infinite colors and undiscovered life.",
        "Every single layer of the ocean holds breathtaking wonders waiting to be uncovered.",
        "We are thrilled to bring these mesmerizing ocean discoveries to your feed."
    ]
}

def generate_smart_reply(comment_text, username):
    lower = comment_text.lower()
    gratitude = random.choice(PAGE_GRATITUDE_LIST).replace("{user}", username)
    
    selected_insight = ""
    for keys, insights in CONTEXT_REPLIES.items():
        matched = False
        for k in keys.split("|"):
            if k in lower:
                selected_insight = random.choice(insights)
                matched = True
                break
        if matched:
            break
            
    if not selected_insight:
        general_insights = [
            "Every day the ocean teaches us something brand new about life on Earth.",
            "Stay tuned as we continue diving deeper into our planet's greatest frontier!",
            "What is your all-time favorite marine phenomenon or creature?"
        ]
        selected_insight = random.choice(general_insights)
        
    return f"{gratitude} {selected_insight}"

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

def check_and_reply_all():
    ig_id = get_verified_instagram_id()
    token = CONFIG["page_access_token"]
    my_user = CONFIG["instagram_username"]
    
    print("[*] Fetching recent media posts...")
    res = requests.get(f"{BASE_URL}/{ig_id}/media", params={
        "fields": "id,permalink,comments_count",
        "limit": 20,
        "access_token": token
    }).json()
    
    posts = res.get("data", [])
    print(f"[+] Scanning {len(posts)} posts for comments...")
    
    replied_count = 0
    for p in posts:
        if p.get("comments_count", 0) > 0:
            c_res = requests.get(f"{BASE_URL}/{p['id']}/comments", params={
                "fields": "id,text,username,replies{id,text,username}",
                "access_token": token
            }).json()
            
            comments = c_res.get("data", [])
            for c in comments:
                user = c.get("username", "")
                text = c.get("text", "")
                if user == my_user:
                    continue
                    
                has_our_reply = False
                replies = c.get("replies", {}).get("data", [])
                for r in replies:
                    if r.get("username") == my_user:
                        has_our_reply = True
                        break
                        
                if not has_our_reply:
                    reply_msg = generate_smart_reply(text, user)
                    print(f"  [UNREPLIED] @{user}: \"{text}\"")
                    print(f"  -> Generated: \"{reply_msg}\"")
                    
                    try:
                        reply_res = requests.post(f"{BASE_URL}/{c['id']}/replies", data={
                            "message": reply_msg,
                            "access_token": token
                        }).json()
                        print(f"  [+] Reply sent! ID: {reply_res.get('id')}")
                        replied_count += 1
                        time.sleep(2)
                    except Exception as err:
                        print(f"  [!] Error sending reply: {err}")
                        
    print(f"[Done] Total newly replied comments: {replied_count}")

if __name__ == "__main__":
    check_and_reply_all()
