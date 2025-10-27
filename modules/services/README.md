# Services Module

Server services and daemon configurations for NixOS.

## Available Services

### qBittorrent

Headless torrent client with web UI, automation, and webhook support.

**Features:**
- Dedicated 2TB storage disk configuration
- Automatic filesystem mounting and formatting (optional)
- Webhook notifications on torrent completion
- Configurable seeding limits (ratio and time)
- Bandwidth limits
- Security hardening with systemd
- Firewall configuration

**Quick Start:**

```nix
modules.services.qbittorrent = {
  enable = true;

  # Storage on 2TB disk
  storage = {
    device = "/dev/sda";
    mountPoint = "/mnt/torrents";
    format = false; # Set to true ONLY on first setup
    fsType = "ext4";
  };

  # Directories
  downloadDir = "/mnt/torrents/completed";
  incompleteDir = "/mnt/torrents/incomplete";
  watchDir = "/mnt/torrents/watch";

  # Network
  port = 8080; # Web UI
  torrentPort = 6881;
  openFirewall = true;

  # Seeding limits
  settings = {
    maxRatio = 2.0; # Stop seeding after 2.0 ratio
    maxSeedingTime = 10080; # 7 days in minutes
    uploadLimit = 1024; # 1MB/s
  };

  # Webhooks (optional)
  webhook = {
    enable = true;
    url = "https://discord.com/api/webhooks/YOUR_WEBHOOK";
  };
};
```

**Initial Setup:**

1. **First Time Setup - Format the 2TB Disk:**
   ```nix
   modules.services.qbittorrent.storage.format = true;
   ```
   Apply configuration: `sudo nixos-rebuild switch --flake .#nixos-server`

2. **After First Boot - Disable Format:**
   ```nix
   modules.services.qbittorrent.storage.format = false;
   ```
   Apply configuration again.

3. **Access Web UI:**
   - URL: `http://server-ip:8080`
   - Default username: `admin`
   - Default password: `adminadmin` (change this immediately!)

4. **Configure qBittorrent:**
   - Go to Tools → Options → Downloads
   - Set "Default Save Path": `/mnt/torrents/completed`
   - Enable "Keep incomplete torrents in": `/mnt/torrents/incomplete`
   - Enable "Run external program on torrent completion" (see automation section)

**Webhook Automation:**

The module includes a default webhook script that:
- Logs all torrent completions
- Sends Discord/Slack notifications (if URL provided)
- Supports custom parameters from qBittorrent

To use the advanced completion handler:

1. Copy the script to your server:
   ```bash
   sudo cp modules/services/qbittorrent-scripts/completion-handler.sh /usr/local/bin/
   sudo chmod +x /usr/local/bin/completion-handler.sh
   ```

2. In qBittorrent Web UI → Tools → Options → Downloads:
   - Enable "Run external program on torrent completion"
   - Command: `/usr/local/bin/completion-handler.sh "%N" "%L" "%D" "%F" "%Z" "%I"`

3. Configure environment variables (optional):
   ```nix
   systemd.services.qbittorrent.environment = {
     QBITTORRENT_WEBHOOK_URL = "https://your-webhook-url";
     QBITTORRENT_HARDLINKS = "true"; # Enable hard link organization
     QBITTORRENT_NOTIFICATIONS = "true"; # Enable webhook notifications
   };
   ```

**Advanced Features:**

### File Organization with Hard Links

The completion handler can automatically organize downloads using hard links:
- Preserves seeding capability (files stay in original location)
- No extra disk space used
- Organized by category in `/mnt/torrents/organized/`

### Category-Based Processing

Set up categories in qBittorrent and the script will:
- Auto-organize files by category
- Apply category-specific post-processing
- Send category-specific notifications

Example categories:
- `movies` - For movie torrents
- `tvshows` - For TV series
- `music` - For music albums
- `books` - For ebooks/audiobooks

### Integration Examples

#### Discord Webhook Setup:
1. Go to Server Settings → Integrations → Webhooks
2. Create a new webhook
3. Copy the webhook URL
4. Add to your configuration:
   ```nix
   webhook.url = "https://discord.com/api/webhooks/...";
   ```

#### Plex/Jellyfin Integration:
Modify the completion handler to trigger library scans:
```bash
# In completion-handler.sh
curl -X POST "http://plex:32400/library/sections/1/refresh?X-Plex-Token=TOKEN"
```

#### Cross-Seed Support:
Add cross-seed API calls to find matching torrents:
```bash
curl -XPOST http://localhost:2468/api/webhook?apikey=YOUR_KEY -d "infoHash=$INFO_HASH"
```

**Security Notes:**

The qBittorrent service runs with:
- Dedicated user/group (`qbittorrent`)
- Limited filesystem access (ReadWritePaths)
- No new privileges
- Restricted address families
- Private `/tmp` directory
- Protected kernel tunables

**Troubleshooting:**

1. **Service won't start:**
   ```bash
   sudo systemctl status qbittorrent
   sudo journalctl -u qbittorrent -f
   ```

2. **Disk not mounting:**
   ```bash
   sudo mount -a
   sudo systemctl daemon-reload
   ```

3. **Webhook not working:**
   - Check permissions: `ls -la /var/log/qbittorrent-webhook.log`
   - Test script manually: `sudo -u qbittorrent /usr/local/bin/completion-handler.sh "Test" "test" "/tmp" "/tmp" "1024" "abc123"`

4. **Web UI not accessible:**
   - Check firewall: `sudo ss -tlnp | grep 8080`
   - Verify service is running: `sudo systemctl status qbittorrent`

**Best Practices:**

1. **Seeding:**
   - Use reasonable ratio limits (1.5-2.0 recommended)
   - Set time limits to free up disk space
   - Use hard links to organize without breaking seeding

2. **Security:**
   - Change default Web UI password immediately
   - Use strong authentication
   - Enable HTTPS if exposing to internet
   - Consider VPN for privacy

3. **Storage:**
   - Monitor disk usage: `df -h /mnt/torrents`
   - Set up alerts for low disk space
   - Clean up old torrents regularly

4. **Performance:**
   - Adjust connection limits based on your bandwidth
   - Use appropriate upload limits to avoid congestion
   - Monitor resource usage: `htop`, `iotop`

**Module Options Reference:**

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `enable` | bool | false | Enable qBittorrent service |
| `user` | string | "qbittorrent" | Service user |
| `group` | string | "qbittorrent" | Service group |
| `dataDir` | path | "/var/lib/qbittorrent" | Configuration directory |
| `downloadDir` | path | "/mnt/torrents/downloads" | Completed downloads |
| `incompleteDir` | path | "/mnt/torrents/incomplete" | Incomplete downloads |
| `watchDir` | path | "/mnt/torrents/watch" | Watch directory for .torrent files |
| `port` | int | 8080 | Web UI port |
| `torrentPort` | int | 6881 | Torrent connection port |
| `openFirewall` | bool | false | Open firewall ports |
| `storage.device` | string | "/dev/sda" | Storage device |
| `storage.mountPoint` | path | "/mnt/torrents" | Mount point |
| `storage.format` | bool | false | Format device (WARNING) |
| `storage.fsType` | string | "ext4" | Filesystem type |
| `webhook.enable` | bool | false | Enable webhooks |
| `webhook.url` | string | "" | Webhook URL |
| `settings.maxRatio` | float? | null | Max seeding ratio |
| `settings.maxSeedingTime` | int? | null | Max seeding time (minutes) |
| `settings.downloadLimit` | int? | null | Download limit (KB/s) |
| `settings.uploadLimit` | int? | null | Upload limit (KB/s) |

See also: [qBittorrent Module Source](./qbittorrent.nix)
