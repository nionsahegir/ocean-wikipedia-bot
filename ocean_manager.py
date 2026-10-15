import json
import os
import requests
import time

CONFIG_PATH = os.path.join(os.path.dirname(__file__), "config.json")

def load_config():
    with open(CONFIG_PATH, "r", encoding="utf-8") as f:
        return json.load(f)

class OceanInstagramManager:
    def __init__(self):
        self.config = load_config()
        self.ig_id = self.config["instagram_business_id"]
        self.token = self.config["page_access_token"]
        self.api_version = self.config.get("api_version", "v19.0")
        self.base_url = f"https://graph.facebook.com/{self.api_version}"

    def get_recent_posts(self, limit=10):
        url = f"{self.base_url}/{self.ig_id}/media"
        params = {
            "fields": "id,caption,media_type,permalink,timestamp,comments_count,like_count",
            "limit": limit,
            "access_token": self.token
        }
        res = requests.get(url, params=params)
        res.raise_for_status()
        return res.json().get("data", [])

    def get_comments(self, media_id, limit=20):
        url = f"{self.base_url}/{media_id}/comments"
        params = {
            "fields": "id,text,username,timestamp,like_count,replies{id,text,username}",
            "limit": limit,
            "access_token": self.token
        }
        res = requests.get(url, params=params)
        res.raise_for_status()
        return res.json().get("data", [])

    def reply_to_comment(self, comment_id, message):
        url = f"{self.base_url}/{comment_id}/replies"
        params = {
            "message": message,
            "access_token": self.token
        }
        res = requests.post(url, data=params)
        res.raise_for_status()
        return res.json()

    def generate_smart_reply(self, comment_text, username=""):
        """
        Creates an authentic, highly-contextual response based strictly on what the commenter said.
        Reflects natural UK/US/EU marine-enthusiast tone with an engaging follow-up question.
        """
        lower = comment_text.lower().strip()

        if "fishing" in lower or "plastic" in lower or "net" in lower or "pollution" in lower:
            return (
                f"Spot on @{username}! Abandoned ghost nets and industrial bycatch make up an alarming percentage "
                f"of oceanic plastic debris. It's devastating for non-target species. "
                f"What do you think is the most effective policy change governments should implement?"
            )
        elif "shark" in lower and ("eat" in lower or "poor" in lower or "food" in lower):
            return (
                f"It's fascinating to see apex scavengers at work, @{username}! "
                f"Whale falls provide a lifeline of nutrients that can sustain deep-sea ecosystems for decades. "
                f"Nature truly wastes nothing in the abyss. Do you find sharks fascinating or a bit terrifying?"
            )
        elif "thank" in lower or "thx" in lower or "awesome" in lower:
            return (
                f"Really glad you enjoyed this footage, @{username}! 💙 "
                f"Our mission is to bring the deepest parts of the ocean to light. "
                f"What marine creature would you love to see featured next?"
            )
        elif "circle of life" in lower or "nature" in lower:
            return (
                f"Precisely, @{username}. It can be raw to witness, but it's essential for balance. "
                f"Have you ever encountered wild marine life while out on the water?"
            )
        elif "fake" in lower or "cgi" in lower or "real" in lower:
            return (
                f"It looks completely out of this world, @{username}, but it is 100% real footage captured by marine research submersibles! "
                f"The deep sea has adapted in ways stranger than any sci-fi film. What surprised you the most about it?"
            )
        elif "scary" in lower or "terrifying" in lower or "nope" in lower or "fear" in lower:
            return (
                f"Haha totally understandable @{username}! Pitch-black depths and crushing pressure create some bizarre adaptations. "
                f"Luckily they stay thousands of feet beneath the surface where sunlight never reaches. Would you ever dare dive into the twilight zone?"
            )
        else:
            return (
                f"Thanks for sharing your perspective, @{username}! 🌊 "
                f"The deep ocean never ceases to amaze us. What aspect of marine exploration interests you the most?"
            )

    def scan_and_reply_sprint(self, dry_run=True):
        """
        Runs the 15-minute pre/post posting engagement sprint.
        Scans pending unreplied comments across recent posts.
        """
        posts = self.get_recent_posts(limit=5)
        print(f"[*] Scanning {len(posts)} recent posts for comments...")
        
        actions = []
        for post in posts:
            if post.get("comments_count", 0) == 0:
                continue
            comments = self.get_comments(post["id"])
            for c in comments:
                replies = c.get("replies", {}).get("data", [])
                # Check if oceanwikipedia already replied
                replied_by_me = any(r.get("username") == self.config["instagram_username"] for r in replies)
                if not replied_by_me:
                    reply_msg = self.generate_smart_reply(c.get("text", ""), c.get("username", ""))
                    actions.append({
                        "post_id": post["id"],
                        "comment_id": c["id"],
                        "user": c.get("username", ""),
                        "text": c.get("text", ""),
                        "reply": reply_msg
                    })

        print(f"[*] Found {len(actions)} unreplied comment(s).")
        for act in actions:
            print(f"\n[Comment by @{act['user']}]: {act['text']}")
            print(f" -> [Smart Reply]: {act['reply']}")
            if not dry_run:
                self.reply_to_comment(act["comment_id"], act["reply"])
                print(f" -> [SUCCESS] Posted reply to {act['comment_id']}")
                time.sleep(2) # safety delay
            else:
                print(" -> [DRY RUN] Reply not sent (set dry_run=False to post).")

        return actions

if __name__ == "__main__":
    manager = OceanInstagramManager()
    print("[*] Testing Ocean Wikipedia Instagram Manager Connection...")
    posts = manager.get_recent_posts(limit=3)
    print(f"[+] Successfully connected to @{manager.config['instagram_username']}!")
    print(f"[+] Found {len(posts)} recent posts.")
    print("\n--- Running Engagement Sprint (Simulation / Dry Run) ---")
    manager.scan_and_reply_sprint(dry_run=True)
