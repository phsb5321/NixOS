# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## ⚠️ CRITICAL: HOST CONFIGURATION WARNING ⚠️

**THIS SYSTEM IS A SERVER HOST - NOT A DESKTOP HOST**

**MANDATORY RULES:**
1. **NEVER** run `nixos-rebuild switch --flake .#default` on this system
2. **NEVER** deploy the default (desktop) host configuration
3. **ALWAYS** use `.#server` for all builds and deployments
4. The `default` host configuration is for desktop machines only
5. The `server` host uses stable nixpkgs and minimal packages

**Sudo password: 123** (for build/deployment commands)

**CORRECT COMMANDS FOR THIS HOST:**
- `sudo nixos-rebuild switch --flake .#nixos-server` ✅
- `sudo nixos-rebuild build --flake .#nixos-server` ✅
- `./user-scripts/nixswitch` ✅ (auto-detects host)

**WRONG COMMANDS (WILL BREAK SYSTEM):**
- `sudo nixos-rebuild switch --flake .#default` ❌
- `sudo nixos-rebuild switch --flake .` ❌ (defaults to .#default)

## Common Development Commands

### NixOS Rebuilds
- `./user-scripts/nixswitch` - Modern TUI-based rebuild script (auto-detects host) (RECOMMENDED)
- `sudo nixos-rebuild switch --flake .#nixos-server` - Manual rebuild for server host (DEFAULT HOST)
- `sudo nixos-rebuild switch --flake .#default` - Manual rebuild for desktop host
- `sudo nixos-rebuild switch --flake .#laptop` - Manual rebuild for laptop host
- `sudo nixos-rebuild test --flake .#nixos-server` - Test server configuration without switching
- `sudo nixos-rebuild build --flake .#nixos-server` - Build server configuration without switching

**NOTE: This system is configured as a SERVER HOST. Always use nixos-server configuration for deployments.**

### Development Environments
- `./user-scripts/nix-shell-selector.sh` - Interactive shell selector with multi-environment support
- `nix-shell shells/JavaScript.nix` - Enter JavaScript development environment
- `nix-shell shells/Python.nix` - Enter Python development environment  
- `nix-shell shells/Rust.nix` - Enter Rust development environment
- Available shells: JavaScript, Python, Golang, ESP, Rust, Elixir

### Flake Operations
- `nix flake update` - Update all flake inputs
- `nix flake check` - Validate flake syntax and configuration
- `nix build .#nixosConfigurations.default.config.system.build.toplevel` - Build system configuration
- `alejandra .` - Format Nix code
- `nixpkgs-fmt .` - Alternative Nix formatter
- `nix develop` - Enter development shell with linting tools (statix, deadnix)

### Dotfiles Management (chezmoi)
- `dotfiles-init` - Initialize dotfiles management
- `dotfiles-status` or `dotfiles` - Check dotfiles status
- `dotfiles-edit` - Edit dotfiles in VS Code/Cursor
- `dotfiles-apply` - Apply dotfiles changes to system
- `dotfiles-add ~/.config/file` - Add new file to dotfiles management
- `dotfiles-sync` - Sync dotfiles with git

## Architecture Overview

### Flake Structure
This is a modular NixOS flake configuration supporting multiple hosts with shared package management:

- **flake.nix**: Main flake entry point with nixpkgs-unstable for latest packages
- **hosts/**: Host-specific configurations (default=desktop, laptop, server)
- **modules/**: Shared system modules with categorical organization
  - `core/` - Base system configuration
  - `packages/` - Categorical package management
  - `desktop/` - Desktop environment (GNOME)
  - `services/` - Server services (qBittorrent, Plex)
  - `networking/` - Network configuration
  - `shell/` - Shell configuration (ZSH, plugins)
  - `dotfiles/` - Dotfiles management
- **shells/**: Development environment shells for different languages
- **user-scripts/**: Custom automation scripts (nixswitch, nix-shell-selector)
- **dotfiles/**: Chezmoi-managed dotfiles stored in project
- **plex-qbittorrent-scripts/**: External GitHub repo for media automation scripts

### Module System
The configuration uses a modular approach with:

#### Core Modules (`modules/core/`)
- **default.nix**: Base system configuration, Nix settings, security, SSH
- **fonts.nix**: System font management  
- **gaming.nix**: Gaming-related system configuration
- **java.nix**: Java runtime and Android development tools
- **pipewire.nix**: Audio system configuration with high-quality profiles
- **document-tools.nix**: LaTeX, Typst, and Markdown tooling
- **docker-dns.nix**: Container DNS resolution fixes
- **monitor-audio.nix**: Audio routing for external monitors

#### Package Management (`modules/packages/`)
Categorical package management with per-host enable/disable:
- **browsers**: Chrome, Firefox, Brave, Zen browser
- **development**: VS Code, language servers, dev tools, compilers
- **media**: Spotify, VLC, OBS, GIMP, Discord
- **utilities**: gparted, syncthing, system tools
- **gaming**: Steam, Lutris, Wine, performance tools
- **audioVideo**: PipeWire, EasyEffects, audio tools
- **terminal**: Shell tools, fonts, terminal applications

#### Services Module (`modules/services/`)
Server services and daemons for media management:

**qBittorrent** (`modules/services/qbittorrent.nix`):
- Headless torrent client with Web UI (port 8080)
- Dedicated 2TB disk storage configuration
- Automatic filesystem mounting and formatting
- Configurable seeding limits (ratio and time-based)
- Bandwidth controls (upload/download limits)
- Security hardening with systemd restrictions
- Firewall integration
- Watch directory for auto-importing .torrent files
- No authentication for LAN access (192.168.0.0/16)
- Web UI: http://server-ip:8080

**Plex Media Server** (`modules/services/plex.nix`):
- Media server with web UI (port 32400)
- Automatic qBittorrent integration via monitor daemon
- Hardlink-based media organization (preserves seeding)
- Automatic library scanning via API
- Support for Movies, TV Shows, Music, and AudioBooks libraries
- Hardware transcoding support (PlexPass optional)
- Shared 2TB disk storage with qBittorrent
- Web UI: http://server-ip:32400/web

**Plex Monitor Daemon** (`modules/services/qbittorrent-scripts/plex-monitor-daemon.py`):
- Python daemon that continuously monitors qBittorrent API
- Auto-detects completed movies and TV shows
- Creates hardlinks in Plex media directories automatically
- Runs as systemd service (polls every 30 seconds)
- Smart detection: year patterns for movies, S##E## patterns for TV shows
- Maintains state to avoid reprocessing
- Supports movies with and without years in filename
- **TV Show Support**: Detects S01E01, s01e01, and 1x01 formats
- **Smart Organization**: Creates proper Plex structure (Show Name/Season XX/)
- **Season Pack Support**: Extracts all episodes from season pack directories
- Automatic Plex library scanning (when token configured)
- Logs to /var/log/plex-monitor.log

**TV Show Detection Examples:**
- `Shameless.S01E01.Pilot.mkv` → `/TV Shows/Shameless/Season 01/`
- `The.Office.US.S02E05.mkv` → `/TV Shows/The Office US/Season 02/`
- `Breaking.Bad.s03e07.mkv` → `/TV Shows/Breaking Bad/Season 03/`
- `Friends.1x05.mkv` → `/TV Shows/Friends/Season 01/`

**Integration Features**:
- Movies automatically appear in Plex after download completes
- No duplicate files (hardlinks use no extra space)
- Original torrents continue seeding in qBittorrent
- Both services auto-start on boot and survive rebuilds

#### Host Configurations
- **server**: Minimal configuration, uses stable nixpkgs for reliability (THIS HOST - DEFAULT)
- **default** (desktop): Gaming enabled, AMD GPU optimization, full development setup, uses nixpkgs-unstable
- **laptop**: Gaming disabled, Intel graphics, minimal package set, Tailscale enabled, uses stable nixpkgs

**IMPORTANT: This system is running as the SERVER host configuration. All rebuilds should target the server configuration.**

### GPU Variants System
The desktop host supports multiple GPU configurations:
- **hardware**: Full AMD GPU acceleration (default)
- **conservative**: Fallback with tear-free settings
- **software**: Emergency software rendering fallback

### Development Environment Strategy
- Language-specific Nix shells in `shells/` directory
- Multi-shell combination support via nix-shell-selector
- Development tools integrated into main package modules
- Language servers pre-configured for Zed editor

### Shell Configuration (`modules/shell/`)
- **Centralized ZSH Management**: All shell configuration is handled by the dedicated shell module
- **PowerLevel10k Theme**: Properly configured with instant prompt support and Nix store paths
- **Plugin System**: Modular plugin configuration (autosuggestions, syntax highlighting, you-should-use)
- **Modern Tools**: Integrated modern CLI replacements (eza, bat, fd, ripgrep, zoxide, etc.)
- **Per-Host Customization**: Shell features can be enabled/disabled per host
- **Clean Dotfiles**: Separated `.zshenv` (environment) from `.zshrc` (interactive configuration)

### Key Design Principles
1. **DRY Configuration**: Shared packages prevent duplication between hosts
2. **Modular Architecture**: Each system area is independently configurable  
3. **Host Flexibility**: Easy to add new hosts that inherit common configuration
4. **Development Focus**: First-class support for multiple programming languages
5. **Modern Tools**: Uses latest packages from nixpkgs-unstable when beneficial

## Special Notes

### Package Management
- Uses both nixpkgs (stable) and nixpkgs-unstable (latest) inputs
- Desktop uses nixpkgs-unstable for latest packages, laptop/server use stable
- Packages are categorized and can be enabled/disabled per host
- Add new categories in `modules/packages/default.nix` following existing patterns
- Host-specific packages go in `extraPackages` array
- Additional inputs: firefox-nightly, zen-browser, flake-utils

### Hardware Configuration  
- Desktop uses AMD GPU with performance optimizations
- Laptop uses Intel graphics with power management
- GPU variant system allows fallback configurations for desktop

### GNOME Desktop Environment (Modular Architecture)

#### Architecture Overview
The GNOME configuration follows a **modular host-specific architecture** to eliminate duplication while allowing complete customization per host.

```
modules/desktop/gnome/
├── base.nix        ← Shared infrastructure (GDM, services, portals, fonts)
├── extensions.nix  ← Extension package installation
└── default.nix     ← Main orchestrator (Wayland/X11, env vars)

hosts/*/gnome.nix   ← Host-specific complete configurations
```

#### Shared Modules (`modules/desktop/gnome/`)

**base.nix** - Core GNOME infrastructure:
- Display manager (GDM)
- Essential services (keyring, settings-daemon, evolution-data-server, etc.)
- XDG desktop portals (file dialogs, screen sharing)
- Base packages (gnome-shell, control-center, nautilus, etc.)
- Fonts (Cantarell, Source Code Pro, Noto fonts)
- Input device management (libinput)

**extensions.nix** - Extension management:
- Granular enable/disable options for each extension
- Package installation when enabled
- Available extensions: appIndicator, dashToDock, userThemes, justPerfection,
  vitals, caffeine, clipboard, gsconnect, workspaceIndicator, soundOutput

**default.nix** - Display protocol & environment:
- Wayland/X11 switching logic
- Session-specific environment variables
- Portal service configuration
- Theme management (icon theme, cursor theme)

#### Host-Specific Configurations

Each host defines its **complete GNOME configuration** in `hosts/<hostname>/gnome.nix`:

**Desktop** (`hosts/default/gnome.nix`):
- Wayland-only (NixOS 25.11+)
- AMD RX 5700 XT optimizations (dynamic triple buffering, rt-scheduler)
- Full extension set (10 extensions)
- Gaming-focused favorite apps (Steam, etc.)
- Performance-oriented settings

**Laptop** (`hosts/laptop/gnome.nix`):
- X11 for Intel GPU compatibility
- Battery-saving settings (no triple buffering, 5min idle, suspend on AC)
- Minimal extension set (9 extensions, no sound-output-device-chooser)
- Power-conscious configuration
- Workspaces only on primary display

**Server** (`hosts/server/gnome.nix`):
- X11 for Proxmox VM compatibility
- VirtIO-GPU optimizations (GSK_RENDERER auto-detect for llvmpipe)
- Minimal extension set (6 extensions, server-focused)
- Always-on power settings (no idle, no sleep, ignore power button)
- Fixed 2 workspaces

#### Key Design Principles

1. **No dconf Merging**: Each host defines one complete `programs.dconf.profiles.user.databases`
   - Prevents GVariant construction errors from merging multiple databases
   - Each host has full control over all dconf settings

2. **Shared Infrastructure**: Base services and packages defined once in `base.nix`
   - DRY principle for common GNOME components
   - Consistent portal and service configuration

3. **Extension Flexibility**: Enable/disable extensions per host
   - Packages installed only when enabled
   - Extension IDs managed in host-specific enabled-extensions list

4. **Environment Isolation**: Host-specific environment variables override shared ones
   - Example: Server uses `GSK_RENDERER = ""` for VM auto-detection
   - Example: Desktop sets AMD GPU hardware acceleration vars

#### GNOME Version Notes
- **NixOS 25.11+**: X11 sessions still available when `wayland.enable = false`
- **Portal Integration**: Comprehensive XDG desktop portal configuration for file dialogs
- **Electron Support**: Proper NIXOS_OZONE_WL and GTK_USE_PORTAL configuration

### Bruno API Client
- Desktop: Wayland mode with enhanced portal configuration for file dialogs
- Laptop: X11 mode for better file picker compatibility
- Portal backend: GTK FileChooser interface for Electron applications

### External Resources

**GitHub Repositories:**
- **Main NixOS Config**: https://github.com/phsb5321/NixOS
- **Plex Integration Scripts**: https://github.com/phsb5321/plex-qbittorrent-scripts
  - plex-monitor-daemon.py - Continuous monitoring daemon
  - plex-integration.sh - qBittorrent completion hook
  - completion-handler.sh - Advanced handler with webhooks

**Documentation:**
- qBittorrent & Plex: `modules/services/README.md`
- AudioBooks Setup: `modules/services/AUDIOBOOKS-SETUP.md`
- GNOME Architecture: `modules/desktop/gnome/README.md`

### Server Service Management

**Quick Status Checks:**
```bash
# Check all media services
sudo systemctl status qbittorrent plex plex-monitor audiobookshelf

# Check mounts
mount | grep -E "(torrents|AudioBooks)"
df -h /mnt/torrents

# View logs
sudo journalctl -u qbittorrent -f
sudo tail -f /var/log/plex-monitor.log

# Restart services
sudo systemctl restart qbittorrent
sudo systemctl restart plex
sudo systemctl restart plex-monitor

# Remount AudioBooks
sudo systemctl restart mnt-torrents-plex-AudioBooks.mount
```

**Access Services:**
- qBittorrent Web UI: http://192.168.1.169:8080
- Plex Web UI: http://192.168.1.169:32400/web
- Audiobookshelf Web UI: https://audiobooks.home301server.com.br/audiobookshelf/ ✅ (RECOMMENDED)
  - **CRITICAL:** Must include `/audiobookshelf/` path in URL!
  - Local: http://192.168.1.169:13378/audiobookshelf/
  - Cloudflare Tunnel: Active with HTTP/1.1 origin
  - **Protected by Audiobookshelf Guardian** (health checks every 5 min, daily backups)

### Disaster Recovery & System Protection

#### Disk Guardian Protection System
The server now includes **Disk Guardian**, a comprehensive monitoring system that prevents disk mounting failures:

**Features:**
- ✅ **Boot-time verification**: Validates disk UUIDs before starting services
- ✅ **Continuous monitoring**: Checks mount health every 60 seconds
- ✅ **Automatic remounting**: Attempts to remount failed mounts
- ✅ **Alert logging**: Records all issues to `/var/log/disk-guardian.log`

**Check Disk Guardian Status:**
```bash
sudo systemctl status disk-guardian-verify  # Boot verification
sudo systemctl status disk-guardian-monitor # Continuous monitoring
sudo tail -f /var/log/disk-guardian.log     # View logs
```

#### Recovery from Disk Ordering Issues (October 2025 Incident)

**What Happened:**
On Oct 28, 2025, the system failed to boot because disk device names swapped:
- `/dev/sda` and `/dev/sdb` switched positions after reboot
- Configuration was trying to mount the wrong disk for torrents storage
- System entered "degraded" state with mount failures
- All data was preserved (no data loss)

**Root Cause:**
Hardware device names (`/dev/sda`, `/dev/sdb`) are **not stable** and can change between reboots based on BIOS/UEFI detection order.

**Permanent Fix Applied:**
1. **UUID-based mounting** for torrents disk: `/dev/disk/by-uuid/b51ce311-3e53-4541-b793-96a2615ae16e`
2. **Disk Guardian service** to verify disks on boot and monitor continuously
3. **Updated GRUB bootloader** to use correct system disk

**If This Happens Again:**

1. **Check system status:**
```bash
systemctl is-system-running              # Should show "running" not "degraded"
journalctl -p err -b --no-pager | tail -50  # Check for errors
lsblk -f                                 # Check disk layout
```

2. **Verify disk assignments:**
```bash
lsblk -o NAME,SIZE,TYPE,MOUNTPOINT,UUID  # Check disk sizes and UUIDs
blkid                                    # List all UUIDs
mount | grep torrents                    # Check if torrents disk is mounted
```

3. **Expected UUIDs:**
   - System disk (128GB): `740d22cb-2333-47fd-bb66-92d573e66605`
   - Torrents disk (2TB): `b51ce311-3e53-4541-b793-96a2615ae16e`

4. **Manual recovery (if needed):**
```bash
# Identify correct disk by size
lsblk -o NAME,SIZE

# Mount torrents disk manually (replace X with correct device)
sudo mount /dev/sdX /mnt/torrents

# Restart services
sudo systemctl restart qbittorrent plex audiobookshelf
```

5. **Verify data integrity:**
```bash
# Check completed downloads
sudo du -sh /mnt/torrents/completed

# Count movies
sudo find /mnt/torrents/plex/Movies -type f -name "*.mkv" -o -name "*.mp4" | wc -l

# Verify hardlinks (should show "Links: 2")
sudo stat /mnt/torrents/completed/[some-movie].mkv
sudo stat /mnt/torrents/plex/Movies/[same-movie].mkv
```

#### System Health Checks

**Daily Health Check Commands:**
```bash
# Overall system status
systemctl is-system-running
uptime

# Disk space
df -h /mnt/torrents
lsblk -o NAME,SIZE,FSUSE%

# Service status
sudo systemctl status qbittorrent plex audiobookshelf disk-guardian-monitor

# Mount verification
mount | grep -E "(torrents|AudioBooks)"
sudo ls /mnt/torrents/completed /mnt/torrents/plex/Movies

# Check for errors
journalctl -p err --since "24 hours ago" --no-pager
sudo tail -50 /var/log/disk-guardian.log
```

**Expected Data (as of Oct 28, 2025):**
- Torrents disk usage: ~260GB / 2TB (13%)
- Movies in library: 14+ films
- AudioBooks: 57+ audiobooks via SSHFS
- Services: All running without errors

### Dotfiles Integration
- Project-local dotfiles using chezmoi stored in `~/NixOS/dotfiles/`
- Independent of NixOS rebuilds for instant configuration changes
- Git-managed with helper scripts for common operations
- Zed Editor configured with Claude Code integration

### Development Workflow
- Use `nixswitch` for system rebuilds (handles validation, cleanup, error recovery)
- Use `nix-shell-selector.sh` for development environments
- Dotfiles changes apply immediately without rebuilds
- Language servers and tools are pre-configured for modern development
- Zed Editor with Claude Code ACP agent integration

## Server-Specific Configuration (THIS HOST)

### Storage Configuration
The server uses a dedicated 2TB disk for media storage:

**IMPORTANT: This system uses UUID-based mounting to prevent disk ordering issues!**

**Disk Layout:**
- 128GB disk - System disk (root filesystem, bootloader)
  - Current device: `/dev/sda` (can change!)
  - UUID: `740d22cb-2333-47fd-bb66-92d573e66605`
- 2TB disk - Media disk (torrents, Plex media)
  - Current device: `/dev/sdb` (can change!)
  - UUID: `b51ce311-3e53-4541-b793-96a2615ae16e` (used in configuration)

**WARNING:** Device names (`/dev/sda`, `/dev/sdb`) are NOT stable and can swap between reboots.
Always use UUIDs in configuration files!
  - Mounted at: `/mnt/torrents`
  - Filesystem: ext4
  - Auto-mounts on boot (configured in fileSystems)

**Directory Structure:**
```
/mnt/torrents/ (2TB disk)
├── completed/         # qBittorrent finished downloads (seeding)
├── incomplete/        # Active downloads
├── watch/             # Drop .torrent files for auto-import
└── plex/              # Plex media libraries
    ├── Movies/        # Hardlinked from completed/ (173 GB, 13+ movies)
    ├── TV Shows/      # Auto-populated when TV shows download
    └── AudioBooks/    # SSHFS mount from audiobook server
```

### qBittorrent Configuration

**Service:** `qbittorrent.service`
- Status: Auto-starts on boot, always running
- User: qbittorrent:qbittorrent
- Data directory: /var/lib/qbittorrent
- Web UI: http://192.168.1.169:8080 (no authentication)

**Configuration:**
```nix
modules.services.qbittorrent = {
  enable = true;
  storage.device = "/dev/sda";  # 2TB disk
  downloadDir = "/mnt/torrents/completed";
  incompleteDir = "/mnt/torrents/incomplete";
  port = 8080;  # Web UI
  torrentPort = 6881;
  openFirewall = true;

  settings = {
    maxRatio = 2.0;
    maxSeedingTime = 10080;  # 7 days
    uploadLimit = 1024;  # 1 MB/s
  };

  webUI.bypassLocalAuth = true;  # No password for LAN
};
```

**Important Files:**
- Config: /var/lib/qbittorrent/qBittorrent/config/qBittorrent.conf
- Logs: Check with `sudo journalctl -u qbittorrent -f`
- SSH Key: /var/lib/qbittorrent/.ssh/id_ed25519 (for AudioBooks mount)

### Plex Media Server Configuration

**Service:** `plex.service`
- Status: Auto-starts on boot, always running
- User: plex:plex
- Data directory: /var/lib/plex
- Media directory: /mnt/torrents/plex
- Web UI: http://192.168.1.169:32400/web

**Configuration:**
```nix
modules.services.plex = {
  enable = true;
  dataDir = "/var/lib/plex";
  mediaDir = "/mnt/torrents/plex";
  openFirewall = true;

  libraries = {
    movies = true;
    tvShows = true;
    audiobooks = true;
  };

  integration.qbittorrent = {
    enable = true;
    autoScan = true;
    useHardlinks = true;
  };
};
```

**Libraries to Configure in Plex Web UI:**
1. **Movies**: `/mnt/torrents/plex/Movies` (13+ movies, 173 GB)
2. **TV Shows**: `/mnt/torrents/plex/TV Shows` (auto-populated)
3. **AudioBooks**: `/mnt/torrents/plex/AudioBooks` (57 audiobooks, 26 GB via SSHFS)

**Important Files:**
- Plex plugins: /var/lib/plex/Plex Media Server/Plug-ins/
- Audnexus agent: /var/lib/plex/Plex Media Server/Plug-ins/Audnexus.bundle/
- Plex token: /etc/plex/token (create this after first Plex setup)

### Plex Monitor Daemon

**Service:** `plex-monitor.service`
- Status: Auto-starts on boot, polls qBittorrent every 30 seconds
- User: qbittorrent:qbittorrent
- Log: /var/log/plex-monitor.log

**How It Works:**
1. Monitors qBittorrent API for completed torrents
2. Detects if content is a movie or TV show
3. Creates hardlinks in `/mnt/torrents/plex/Movies/` or `/mnt/torrents/plex/TV Shows/`
4. Triggers Plex library scan via API
5. Maintains state in /var/lib/qbittorrent/processed_torrents.json

**Monitor Logs:**
```bash
sudo tail -f /var/log/plex-monitor.log
sudo systemctl status plex-monitor
```

### AudioBooks SSHFS Mount

**Remote Server:** 192.168.1.7 (audiobook host)
- Username: notroot
- Password: 123
- Remote path: /home/notroot/Documents/PLEX_AUDIOBOOK/temp/untagged

**Mount Configuration:**
- Local mount: /mnt/torrents/plex/AudioBooks
- Type: SSHFS (fuse.sshfs)
- Authentication: SSH key (/var/lib/qbittorrent/.ssh/id_ed25519)
- Auto-mount: Yes (systemd automount)
- Auto-reconnect: Every 15 seconds if connection lost

**Systemd Units:**
- `mnt-torrents-plex-AudioBooks.mount` - SSHFS mount service
- `mnt-torrents-plex-AudioBooks.automount` - Automatic mounting on access

**Check Mount Status:**
```bash
sudo systemctl status mnt-torrents-plex-AudioBooks.mount
mount | grep AudioBooks
ls /mnt/torrents/plex/AudioBooks/
```

**SSH Key Management:**
- Key location: /var/lib/qbittorrent/.ssh/id_ed25519
- Public key already added to audiobook server
- Passwordless authentication configured

**Plex AudioBooks Setup:**
- Library type: Music
- Agent: Audnexus (installed in Plex Plug-ins)
- Scanner: Plex Music Scanner
- Settings: Store track progress, use embedded tags
- Full guide: `modules/services/AUDIOBOOKS-SETUP.md`

### Audiobookshelf Configuration (RECOMMENDED)

**Service:** `audiobookshelf.service`
- Status: Auto-starts on boot, Docker container
- Port: 13378
- Data directory: /var/lib/audiobookshelf
- Web UI (Local): http://192.168.1.169:13378
- Web UI (External): https://audiobooks.home301server.com.br

**Why Audiobookshelf:**
- ✅ Purpose-built for audiobooks (not a workaround)
- ✅ Superior metadata (Audible + Google Books + Open Library)
- ✅ Automatic chapter detection and editing
- ✅ Dedicated iOS/Android apps with offline listening
- ✅ Better UI designed for audiobooks
- ✅ Multi-user with cross-device progress sync
- ✅ Actively developed (October 2025)

**Configuration:**
```nix
modules.services.audiobookshelf = {
  enable = true;
  port = 13378;
  audiobooksDir = "/mnt/torrents/plex/AudioBooks";  # Same SSHFS mount
  dataDir = "/var/lib/audiobookshelf";
};
```

**Initial Setup:**
1. Access: https://audiobooks.home301server.com.br (or http://192.168.1.169:13378 locally)
2. Create admin account (first time)
3. Add library: Books → `/audiobooks` folder
4. Download mobile app for best experience

**Cloudflare Tunnel Configuration:**
- Tunnel ID: 7d1704a0-512f-4a54-92c4-d9bf0b4561c3
- Public Domain: audiobooks.home301server.com.br
- Config: ~/.cloudflared/config.yml
- Credentials: ~/.cloudflared/7d1704a0-512f-4a54-92c4-d9bf0b4561c3.json
- Status: Running (start with: cloudflared tunnel --config ~/.cloudflared/config.yml run audiobookshelf)
- Connected to: 4 Cloudflare edge locations

**First-Time Setup:**
The "Server is not initialized" message is NORMAL - this is the admin account
creation screen. Access https://audiobooks.home301server.com.br and create
your account to initialize the server.

**Service Management:**
```bash
sudo systemctl status audiobookshelf
sudo docker logs audiobookshelf
sudo systemctl restart audiobookshelf
```

**Full Guide:** `modules/services/AUDIOBOOKSHELF-SETUP.md`
### Audiobookshelf Protection System

**CRITICAL:** Audiobookshelf will ONLY work at https://audiobooks.home301server.com.br/audiobookshelf/

The `/audiobookshelf/` path is **hardcoded** in the Docker image and cannot be changed.

#### Audiobookshelf Guardian (Protection Service)

The Audiobookshelf Guardian service ensures the application stays healthy and accessible:

**Features:**
- ✅ **Health checks every 5 minutes** - Verifies Docker container, local access, JavaScript assets
- ✅ **Daily automatic backups** - Database backed up to `/var/lib/audiobookshelf/backups/` (keeps last 7)
- ✅ **Automatic recovery** - Restarts container if it stops responding
- ✅ **Configuration validation** - Ensures correct ROUTER_BASE_PATH setting
- ✅ **Cloudflare Tunnel monitoring** - Verifies external access is working

**Monitor Guardian:**
```bash
# View health check status
systemctl status audiobookshelf-health-check.timer

# View backup status
systemctl status audiobookshelf-backup.timer

# Check guardian logs
tail -f /var/log/audiobookshelf-guardian.log

# Manual health check
sudo systemctl start audiobookshelf-health-check.service

# View backups
ls -lh /var/lib/audiobookshelf/backups/
```

**Health Check Tests:**
1. ✓ Docker container is running
2. ✓ Local access working (http://localhost:13378/audiobookshelf/)
3. ✓ JavaScript assets accessible (/_nuxt/*.js)
4. ✓ Config directory exists
5. ✓ AudioBooks directory accessible
6. ✓ Cloudflare Tunnel is active
7. ✓ Container ROUTER_BASE_PATH configuration

#### Disk Guardian Integration

The Disk Guardian also monitors Audiobookshelf every 60 seconds:

**Monitors:**
- ✅ Docker container running status
- ✅ HTTP response on port 13378
- ✅ Automatic container restart if stopped
- ✅ Cloudflare Tunnel status
- ✅ Automatic tunnel restart if stopped

**Check monitoring:**
```bash
tail -f /var/log/disk-guardian.log | grep -E "(Audiobookshelf|Cloudflare)"
```

#### What Will NEVER Break Audiobookshelf Again

**1. Wrong URL Path** ❌ PREVENTED
- Guardian validates `/audiobookshelf/` path is working
- Documentation clearly states the correct URL
- Health checks test both HTML and JavaScript assets

**2. Container Stops** ❌ PREVENTED
- Disk Guardian monitors container every 60 seconds
- Automatic restart if container stops
- Both systemd and Docker auto-restart enabled

**3. Data Loss** ❌ PREVENTED
- Daily automatic database backups
- Keeps last 7 backups (rotating cleanup)
- Backups stored in `/var/lib/audiobookshelf/backups/`

**4. Configuration Changes** ❌ PREVENTED
- NixOS module locks configuration
- ROUTER_BASE_PATH removed (uses default)
- Systemd service ensures consistent Docker run command

**5. Cloudflare Tunnel Failure** ❌ PREVENTED
- Disk Guardian monitors tunnel every 60 seconds
- Automatic restart if tunnel stops
- Systemd ensures tunnel starts on boot

**6. AudioBooks Mount Failure** ❌ PREVENTED
- Disk Guardian monitors SSHFS mount
- Automatic remount attempts
- Health check validates directory accessibility

#### Recovery from Complete Failure

If Audiobookshelf completely breaks, here's how to recover:

**1. Check Guardian Status:**
```bash
sudo systemctl status audiobookshelf-health-check.timer
sudo tail -50 /var/log/audiobookshelf-guardian.log
```

**2. Check Service and Container:**
```bash
sudo systemctl status audiobookshelf
sudo docker ps -a | grep audiobookshelf
sudo docker logs audiobookshelf
```

**3. Restart Everything:**
```bash
# Restart Audiobookshelf
sudo systemctl restart audiobookshelf

# Restart Cloudflare Tunnel
sudo systemctl restart cloudflared-tunnel

# Run health check
sudo systemctl start audiobookshelf-health-check.service
```

**4. Restore from Backup (if needed):**
```bash
# Stop service
sudo systemctl stop audiobookshelf

# List backups
ls -lh /var/lib/audiobookshelf/backups/

# Restore database (replace TIMESTAMP with actual backup)
sudo cp /var/lib/audiobookshelf/backups/absdatabase_TIMESTAMP.sqlite \
       /var/lib/audiobookshelf/config/absdatabase.sqlite

# Start service
sudo systemctl start audiobookshelf
```

**5. Complete Reset (nuclear option):**
```bash
# Stop and remove everything
sudo systemctl stop audiobookshelf
sudo docker rm -f audiobookshelf

# Clear data (WARNING: loses all settings!)
sudo rm -rf /var/lib/audiobookshelf/*

# Rebuild
sudo nixos-rebuild switch --flake .#nixos-server
```

#### Correct URL Reference Card

**ALWAYS use these URLs:**

✅ **External:** https://audiobooks.home301server.com.br/audiobookshelf/  
✅ **Local:** http://192.168.1.169:13378/audiobookshelf/

❌ **WRONG (will hang forever):**
- https://audiobooks.home301server.com.br/ (missing /audiobookshelf/)
- http://192.168.1.169:13378/ (missing /audiobookshelf/)

**Why?** The Audiobookshelf Docker image has this path hardcoded. It cannot be changed.
