# Ocean Wikipedia Engine — Architecture & Operational Playbook

## 1. System Overview
The **Ocean Wikipedia (@oceanwikipedia)** automation engine runs a 100% autonomous pipeline without manual user input.

```mermaid
graph TD
    A["Target Accounts Inspection<br/>(@oceanstatement, @ocean.autograph, @ocean_content, @oceana)"] --> B["Headless Chrome CDP Engine<br/>extract_target_reels.ps1"]
    B --> C["yt-dlp Media Extractor<br/>(Extracts highest quality MP4)"]
    C --> D["Audio Processing Engine<br/>(100% Original Sound Only, Softened & Normalized)"]
    D --> E["Clean Native Caption Generator<br/>(2-3 lines max, Clean Hashtags, Explicit Credit)"]
    E --> F["Meta Graph API Publisher<br/>auto_publisher.ps1"]
    F --> G["Live Instagram Reels, Posts & Stories"]
    H["Comment Listener Task<br/>OceanWikipediaCommentListener"] --> I["Smart Contextual Reply Engine<br/>(100% Unique Replies thanking user)"]
    J["Storage Protection Routine"] --> K["Auto-prunes temp/content > 2 days<br/>Core Brain & Scripts 100% Protected"]
```

---

## 2. Instagram Stories & Engagement Engine
- **Endpoint:** `POST /{ig-user-id}/media` with `media_type = STORIES`
- **Publish:** `POST /{ig-user-id}/media_publish`
- **Supported Media:** 9:16 vertical images and MP4 videos
- **Verified Live Publication:** Successfully tested and verified live with ID `18067590716789784`.

---

## 3. Strict Operating Rules
1. **Audio Integrity:**
   - Strictly **NO artificial AI voiceovers** (rejected by user as unnatural/underwater sounding).
   - Strictly **NO synthetic surface ocean wave loops**.
   - Always retain the **original authentic video sound**, softened to `volume=0.85` with smooth 2-second audio fade-out.
2. **Caption Formatting:**
   - Short and concise (2-3 natural sentences).
   - 100% native fluent English.
   - Strictly **NO weird signs or bullet emojis** (`🔹`, `💾`, `↗️`).
   - Clean, focused hashtags (5-7 tags).
   - Explicit creator credit line: `Credit: @handle`.
3. **Storage & Safety:**
   - Temporary media in `temp/` and `content/` older than 2 days are cleaned automatically.
   - Core Brain files (`*.ps1`, `*.py`, `*.json`, `*.md`) are permanently protected.
