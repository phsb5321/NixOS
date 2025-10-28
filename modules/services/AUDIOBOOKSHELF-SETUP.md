# Audiobookshelf Setup Guide

Modern, purpose-built audiobook and podcast server with superior metadata and chapter support.

## 🎧 Why Audiobookshelf?

Audiobookshelf is **significantly better than Plex for audiobooks**:

✅ **Purpose-Built** - Designed specifically for audiobooks (not a workaround)
✅ **Superior Metadata** - Scrapes Google Books, Open Library, AND Audible
✅ **Automatic Chapters** - Fetches and edits chapters using Audnexus API
✅ **Native Apps** - Free iOS/Android apps with offline listening
✅ **Better UI** - Interface designed for audiobook listening
✅ **Progress Sync** - Multi-user with cross-device sync
✅ **Non-Destructive** - Never modifies your source files
✅ **Modern & Active** - Actively developed (Oct 2025)

---

## ✅ Pre-Configured

The following is already set up for you:

✅ **Docker Container:** ghcr.io/advplyr/audiobookshelf:latest
✅ **Port:** 13378
✅ **AudioBooks Mount:** Uses existing SSHFS mount from audiobook server
✅ **Auto-Start:** Enabled on boot
✅ **Firewall:** Port 13378 open

---

## 🌐 Access Audiobookshelf

**Web UI:** http://192.168.1.169:13378

---

## 📚 Initial Setup (First Time Only)

### 1. Access Web UI

Open: **http://192.168.1.169:13378**

### 2. Create Admin Account

On first access, you'll be prompted to create an admin account:

- **Username:** Your choice (e.g., `admin`)
- **Password:** Your choice (make it secure!)

Click "Create Account"

### 3. Create Your First Library

After login, you'll see the "Create Your First Library" wizard:

**Library Name:** `AudioBooks`

**Library Type:** Select **"Books"** (for audiobooks)

**Folder Path:** Click "Add Folder"
- Path: `/audiobooks` (this is the mount inside the container)
- Click "Add"

**Click "Create"**

Audiobookshelf will begin scanning your ~57 audiobooks!

---

## 🎯 Features & Configuration

### Metadata Scraping

Audiobookshelf automatically fetches metadata from:
1. **Audible** - Most accurate for audiobooks
2. **Google Books** - Good fallback
3. **Open Library** - Additional source

**To search for metadata:**
1. Click on an audiobook
2. Click "Match" or "Edit"
3. Search by title or ASIN
4. Select the correct match
5. Click "Update"

### Chapter Management

**Automatic Chapter Detection:**
- Audiobookshelf can fetch chapters from Audible
- Click audiobook → Tools → "Lookup Chapters"
- Chapters are automatically embedded

**Chapter Editor:**
- Manually add/edit/remove chapters
- Click audiobook → Tools → "Edit Chapters"

### Collection Management

**Create Collections:**
1. Click "Collections" in sidebar
2. Click "+" to create collection
3. Add books to organize by series, genre, etc.

### User Management

**Add Users:**
1. Settings → Users
2. Click "Add User"
3. Set permissions per user
4. Each user gets their own progress tracking

---

## 📱 Mobile Apps

### iOS App

**App:** Audiobookshelf (Free, Open Source)
- Download from App Store
- Connect to server: http://192.168.1.169:13378
- Login with your account
- Offline listening supported!

### Android App

**App:** Audiobookshelf (Free, Open Source, Beta)
- Download from Google Play or GitHub
- Same features as iOS

---

## 🔧 Configuration

### Server Settings

Access: Settings (gear icon) → Server Settings

**Recommended Settings:**
- **Backups:** Enable automatic backups
- **Scanner:** Adjust scan interval if needed
- **Metadata:** Configure preferred metadata sources
- **Streaming:** Adjust bitrate for mobile

### Library Settings

**Per-Library Settings:**
- Click library → Settings (gear icon)
- Configure folder watching
- Set metadata preferences
- Customize scanning behavior

---

## 📊 What's Available

**Current Setup:**
- **Source:** SSHFS mount from 192.168.1.7
- **Local Path:** `/mnt/torrents/plex/AudioBooks`
- **Container Path:** `/audiobooks` (read-only)
- **Total:** ~57 audiobooks
- **Size:** ~26 GB

**Sample AudioBooks:**
- Good Omens (1990)
- 21 Lessons for the 21st Century
- 2666 (English & Spanish editions)
- American Gods 10th Anniversary
- Catch-22, Blindness, Axiom's End
- And 50+ more classics and modern titles!

---

## 🎛️ Advanced Features

### Collections & Series

- Automatically groups books by series
- Manual collections for custom organization
- Series progress tracking

### Playback Features

- **Variable Speed:** 0.5x to 3x playback speed
- **Sleep Timer:** Auto-stop after set time
- **Bookmarks:** Mark important sections
- **Progress Sync:** Resume on any device

### RSS Feeds

- Generate RSS feeds for audiobooks
- Use with any podcast app
- Per-collection or per-audiobook feeds

### Statistics

- Listening time tracking
- Books completed
- Reading streaks
- Per-user stats

---

## 🔄 Service Management

**Check Status:**
```bash
sudo systemctl status audiobookshelf
sudo docker ps | grep audiobookshelf
```

**View Logs:**
```bash
sudo docker logs audiobookshelf
sudo docker logs -f audiobookshelf  # Follow logs
```

**Restart Service:**
```bash
sudo systemctl restart audiobookshelf
```

**Update to Latest Version:**
```bash
# Pull new image and restart
sudo systemctl restart audiobookshelf
# The service automatically pulls the latest image on restart
```

---

## 🆚 Audiobookshelf vs Plex

| Feature | Audiobookshelf | Plex + Audnexus |
|---------|---------------|-----------------|
| Metadata Sources | 3 (Audible, Google, Open Library) | 1 (Audible only) |
| Chapter Support | ✅ Auto + Editor | ⚠️ Limited |
| Mobile Apps | ✅ Dedicated | ⚠️ Generic |
| Purpose-Built | ✅ Yes | ❌ Workaround |
| UI for Audiobooks | ✅ Optimized | ⚠️ Music UI |
| Setup Complexity | ⭐⭐ Easy | ⭐⭐⭐⭐ Complex |
| Future Support | ✅ Active (2025) | ⚠️ Plugins deprecated |

**Recommendation:** Use Audiobookshelf for audiobooks, keep Plex for movies/TV.

---

## 🐛 Troubleshooting

### No Audiobooks Showing

1. **Check mount:**
   ```bash
   mount | grep AudioBooks
   sudo ls /mnt/torrents/plex/AudioBooks/
   ```

2. **Check container can access:**
   ```bash
   sudo docker exec audiobookshelf ls /audiobooks
   ```

3. **Restart container:**
   ```bash
   sudo systemctl restart audiobookshelf
   ```

### Can't Connect to Web UI

1. **Check container is running:**
   ```bash
   sudo docker ps | grep audiobookshelf
   ```

2. **Check port is listening:**
   ```bash
   ss -tlnp | grep 13378
   ```

3. **Check firewall:**
   ```bash
   sudo firewall-cmd --list-ports  # or check iptables
   ```

### Metadata Not Loading

1. Check internet connection
2. Try different metadata sources (Settings → Metadata)
3. Search by ASIN for most accurate results

### SSHFS Mount Issues

If audiobooks don't appear:

1. **Verify remote mount:**
   ```bash
   sudo systemctl status mnt-torrents-plex-AudioBooks.mount
   ```

2. **Restart mount:**
   ```bash
   sudo systemctl restart mnt-torrents-plex-AudioBooks.mount
   ```

3. **Restart Audiobookshelf after mount:**
   ```bash
   sudo systemctl restart audiobookshelf
   ```

---

## 📖 Documentation

**Official Docs:** https://www.audiobookshelf.org/docs/
**GitHub:** https://github.com/advplyr/audiobookshelf
**Docker Hub:** ghcr.io/advplyr/audiobookshelf

---

## 🎉 Quick Start Summary

1. **Access:** http://192.168.1.169:13378
2. **Create admin account** (first time)
3. **Add library:** Books → `/audiobooks` folder
4. **Let it scan** (~57 audiobooks)
5. **Search metadata** for better info
6. **Download mobile app** for best experience
7. **Start listening!**

---

## 🔐 System Details

**Service:** `audiobookshelf.service`
**Container:** Docker (ghcr.io/advplyr/audiobookshelf:latest)
**Port:** 13378
**Data:** /var/lib/audiobookshelf (config & metadata)
**AudioBooks:** /mnt/torrents/plex/AudioBooks (SSHFS mount, read-only)
**Auto-Start:** ✅ Enabled
**Firewall:** ✅ Port 13378 open

---

**Audiobookshelf is ready! Access it at http://192.168.1.169:13378 and enjoy a superior audiobook experience!** 🎧
