# Plex AudioBooks Setup Guide

Complete setup instructions for the AudioBooks library in Plex using the Audnexus metadata agent.

## 🎧 Overview

Your AudioBooks are automatically mounted from the audiobook server (192.168.1.7) via SSHFS and accessible in Plex.

**Mount Details:**
- **Remote:** `notroot@192.168.1.7:/home/notroot/Documents/PLEX_AUDIOBOOK/temp/untagged`
- **Local:** `/mnt/torrents/plex/AudioBooks`
- **Size:** ~26 GB
- **Count:** ~60 audiobooks
- **Auto-mount:** Yes (on boot)

## ✅ Pre-Installation Completed

The following has already been configured for you:

✅ **SSH Key Authentication:** Generated and added to audiobook server
✅ **SSHFS Mount:** Automatically mounts on boot
✅ **Audnexus Agent:** Installed in Plex Plug-ins directory
✅ **Directory Created:** `/mnt/torrents/plex/AudioBooks`
✅ **Permissions:** Plex user has full access

---

## 📚 Step-by-Step: Create AudioBooks Library in Plex

### 1. Access Plex Web UI

Open: **http://192.168.1.169:32400/web**

### 2. Create New Library

1. Click the **"+"** button (or "Add Library")
2. Select **"Music"** as the library type
3. Click **"Next"**

### 3. Configure Library Settings

**Name:** `AudioBooks`

**Add Folders:**
- Click "Browse for Media Folder"
- Navigate to: `/mnt/torrents/plex/AudioBooks`
- Click "Add"

### 4. Advanced Settings (IMPORTANT!)

Click "Advanced" to expand settings, then configure:

#### Scanner & Agent

- **Scanner:** Plex Music Scanner (default)
- **Agent:** **Audnexus** (should appear in dropdown after Plex restart)

#### Library Settings

✅ **Check:**
- ✅ Store track progress
- ✅ Use embedded tags
- ✅ Prefer local metadata

❌ **Uncheck:**
- ❌ Prefer local artwork
- ❌ Author bio
- ❌ Popular tracks

#### Album Sorting

- **Album Sorting:** By Name
  - This uses the ALBUMSORT tag for proper series ordering

#### Genres

- **Genres:** None (for cleaner organization)

#### Album Art

- **Album Art:** Local Files Only

### 5. Create Library

Click **"Add Library"**

Plex will begin scanning your 60+ audiobooks!

---

## 🎯 Expected Results

After library creation:

- **~60 audiobooks** will appear in your library
- Each audiobook shows:
  - Author (from ALBUMARTIST tag)
  - Title (from ALBUM tag)
  - Narrator info (from ARTIST tag)
  - Cover art
  - Book description
  - Series information (if applicable)
  - Genres

---

## 📖 Using Your AudioBooks

### From Plex Web:

1. Go to **AudioBooks** library
2. Browse by **Author**, **Recently Added**, or **All**
3. Click an audiobook to start listening
4. **Track Progress:** Plex remembers where you left off!

### From Mobile Apps:

- **Plex Mobile:** Works with audiobooks
- **Plexamp:** Excellent for audiobooks with chapter support
- **Prologue:** Dedicated iOS audiobook player for Plex

---

## 🔧 Troubleshooting

### Agent Not Showing

If "Audnexus" doesn't appear in the agent dropdown:

1. Verify installation:
   ```bash
   sudo ls -la "/var/lib/plex/Plex Media Server/Plug-ins/Audnexus.bundle/"
   ```

2. Restart Plex:
   ```bash
   sudo systemctl restart plex.service
   ```

3. Wait 2-3 minutes for Plex to fully start, then refresh the web page

### AudioBooks Not Found

If Plex can't see the audiobooks folder:

1. Check mount status:
   ```bash
   sudo systemctl status mnt-torrents-plex-AudioBooks.mount
   mount | grep AudioBooks
   ```

2. Verify contents:
   ```bash
   sudo ls /mnt/torrents/plex/AudioBooks/
   ```

3. Check permissions:
   ```bash
   sudo -u plex ls /mnt/torrents/plex/AudioBooks/
   ```

4. Restart mount if needed:
   ```bash
   sudo systemctl restart mnt-torrents-plex-AudioBooks.mount
   ```

### Mount Fails After Reboot

1. Check audiobook server is accessible:
   ```bash
   ping 192.168.1.7
   ```

2. Test SSH connection:
   ```bash
   sudo -u qbittorrent ssh notroot@192.168.1.7 "echo 'Connection OK'"
   ```

3. Manually remount:
   ```bash
   sudo systemctl start mnt-torrents-plex-AudioBooks.mount
   ```

### Poor Metadata

If audiobooks don't have good metadata:

1. The remote audiobooks may need better ID3 tags
2. Audnexus searches Audible's database using:
   - ALBUMARTIST (Author)
   - ALBUM (Book Title)
   - ASIN (Audible ID - most accurate)

3. Consider using Mp3tag on the audiobook server to improve tags

---

## 🔄 Updating Audnexus Agent

To update the Audnexus agent to the latest version:

```bash
sudo -u plex sh -c 'cd "/var/lib/plex/Plex Media Server/Plug-ins/Audnexus.bundle" && git pull'
sudo systemctl restart plex.service
```

---

## 📁 Directory Structure

```
/mnt/torrents/plex/
├── Movies/         # 13 movies (hardlinked, 173 GB)
├── TV Shows/       # Auto-populated
└── AudioBooks/     # SSHFS mount (26 GB, ~60 titles)
    ├── Author Name/
    │   └── Series Name/
    │       └── Year - Book Title/
    │           └── audio files
    └── ...
```

---

## 🎛️ Advanced Configuration

### Custom Agent Priority

After creating the library, you can adjust agent priority:

1. Settings → Agents → Artist/Albums → Audiobooks
2. Drag **Audnexus** to the top
3. Disable other agents you don't need

### Library Optimization

For better performance:

1. Settings → Library → Audiobooks
2. Enable "Empty trash automatically after every scan"
3. Set "Generate video preview thumbnails" to "Never"
4. Set "Generate chapter thumbnails" to "Never"

---

## 📊 What's Automated

✅ **SSHFS Mount:** Auto-mounts on boot
✅ **Auto-Reconnect:** Handles network interruptions
✅ **SSH Authentication:** Key-based, no passwords
✅ **Plex Agent:** Audnexus pre-installed
✅ **Permissions:** Properly configured

---

## 🌐 Access Your Library

- **Plex Web:** http://192.168.1.169:32400/web
- **Library Path:** `/mnt/torrents/plex/AudioBooks`
- **Total AudioBooks:** ~60 titles
- **Total Size:** 26 GB

---

## 📝 References

- **Audnexus Agent:** https://github.com/djdembeck/Audnexus.bundle
- **Plex Audiobook Guide:** https://github.com/seanap/Plex-Audiobook-Guide
- **AudioBook Server:** 192.168.1.7 (notroot@audiobook)

---

**Your AudioBooks library is ready to be added in Plex! Follow the steps above to complete the setup.** 🎧
