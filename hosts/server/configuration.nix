# NixOS Server Configuration - Profile-Based (New Architecture)
# VM host running GNOME in X11 mode for compatibility
{
  pkgs,
  systemVersion,
  hostname,
  lib,
  ...
}: let
  # ESC character for ANSI color codes (Nix has no \e literal)
  esc = builtins.fromJSON ''"\u001b"'';
  c = code: "${esc}[${code}m";
  reset = c "0";
in {
  imports =
    [
      ./hardware-configuration.nix
      ../../modules
      ../../profiles/server.nix
      ./gnome.nix
    ]
    # server-secrets.nix is gitignored, so use absolute path for impure builds
    ++ lib.optionals (builtins.pathExists /home/notroot/NixOS/hosts/server/server-secrets.nix) [
      /home/notroot/NixOS/hosts/server/server-secrets.nix
    ];

  # ===== PROFILE-BASED CONFIGURATION =====
  # Server profile enables: SSH, minimal hardware
  modules.profiles.server.enable = true;

  # Host-specific metadata
  # JUSTIFIED: hostname comes from flake, must override module default
  modules.networking.hostName = lib.mkForce hostname;

  # Override shared networking config for server-specific needs
  modules.networking = {
    dns = {
      # JUSTIFIED: Server requires manual DNS for stability (no systemd-resolved)
      enableSystemdResolved = lib.mkForce false;
      enableDNSOverTLS = lib.mkForce false;
    };
    firewall = {
      enable = true;
      developmentPorts = [22 3000]; # SSH and development server
    };
  };

  # Manual DNS configuration for server stability
  # JUSTIFIED: Server uses static DNS, not NetworkManager-managed
  networking = {
    nameservers = lib.mkForce ["8.8.8.8" "8.8.4.4" "1.1.1.1"];
    networkmanager.dns = lib.mkForce "none";
  };

  # JUSTIFIED: Must disable systemd-resolved to avoid conflicts with manual DNS
  services.resolved.enable = lib.mkForce false;

  # Explicitly enable X11 for VM compatibility with proper video drivers
  services.xserver = {
    enable = lib.mkForce true;
    # Video driver configuration for Proxmox QEMU VM
    # Supports both VirtIO-GPU and QXL display types
    videoDrivers = ["modesetting" "qxl" "virtio"];

    # Enable DRI3 for hardware acceleration in VirtIO-GPU VMs
    # This fixes "libEGL warning: DRI3 error: Could not get DRI3 device"
    deviceSection = ''
      Option "DRI" "3"
    '';
  };

  # JUSTIFIED: Qt6 build failure on stable nixpkgs - known issue
  # See: https://github.com/NixOS/nixpkgs/issues/315121
  qt = {
    enable = lib.mkForce false;
  };

  # Bootloader - GRUB for BIOS systems
  # Use /dev/sda (128GB system disk) for bootloader
  boot.loader.grub = {
    enable = true;
    device = "/dev/sda"; # System disk (128GB)
    useOSProber = true;
  };

  # ===== 2-LAYER MEMORY MANAGEMENT (No Swap) =====
  # Server has 24GB RAM - no swap, rely on earlyoom and cgroup limits
  modules.core.memoryManagement = {
    enable = true;

    # Layer 1: ZRAM disabled - server should not swap
    zram.enable = false;

    # Layer 2: earlyoom (kill runaway processes before system freeze)
    earlyoom = {
      enable = true;
      freeMemThresholdPercent = 5;
      freeSwapThresholdPercent = 100; # Effectively disabled since no swap
      enableNotifications = false; # No desktop on server
      # Prefer killing high-memory processes, avoid critical services
      preferRegex = "(nix-daemon|docker|node|python)";
      avoidRegex = "(sshd|systemd|greetd|qbittorrent|plex|audiobookshelf)";
    };

    # Layer 3: Cgroup limits (sized for 24GB server)
    nixDaemon = {
      memoryHigh = "18G"; # Soft limit
      memoryMax = "20G"; # Hard limit
    };
    docker = {
      memoryMax = "16G"; # Docker container limit
    };
  };

  # Disable all swap devices
  swapDevices = lib.mkForce [];
  zramSwap.enable = lib.mkForce false;

  # ===== KERNEL I/O TUNING (FR-007) =====
  # Prevent jbd2 blocked-task panics and optimize for server workloads
  boot.kernel.sysctl = {
    "kernel.hung_task_timeout_secs" = 300; # Increase from 120s (HDD in VM can exceed 120s under load)
    "vm.dirty_ratio" = 40; # Allow 40% dirty pages before blocking (default: 20%)
    "vm.dirty_background_ratio" = 10; # Start background writeback at 10%

    # ===== NETWORK QoS - Prevent torrent traffic from starving SSH =====
    "net.ipv4.tcp_congestion_control" = "bbr"; # Google BBR: low latency under load
    "net.core.default_qdisc" = "cake"; # CAKE qdisc for new interfaces
    "net.ipv4.tcp_fastopen" = 3; # TFO for client + server
    "net.ipv4.tcp_slow_start_after_idle" = 0; # Keep cwnd after idle
    "net.ipv4.tcp_mtu_probing" = 1; # Auto-discover MTU
  };

  # ===== I/O SCHEDULER (FR-007) =====
  # mq-deadline is optimal for HDDs with sequential I/O (torrent downloads, media streaming)
  services.udev.extraRules = ''
    ACTION=="add|change", KERNEL=="sd[a-z]", ATTR{queue/rotational}=="1", ATTR{queue/scheduler}="mq-deadline"
  '';

  # Proxmox VM hardware optimization
  services.qemuGuest.enable = true;
  services.spice-vdagentd.enable = true;

  # ===== NETWORK QoS - CAKE Traffic Shaping =====
  # CAKE with diffserv4 auto-prioritizes interactive traffic (SSH) over bulk (torrents)
  # No bandwidth limits - qBittorrent gets full speed, but SSH packets go first
  systemd.services.network-qos = {
    description = "Configure CAKE QoS on network interface";
    after = ["network-online.target"];
    wants = ["network-online.target"];
    wantedBy = ["multi-user.target"];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${pkgs.iproute2}/bin/tc qdisc replace dev ens18 root cake diffserv4 nat wash";
      ExecStop = "${pkgs.iproute2}/bin/tc qdisc replace dev ens18 root fq_codel";
    };
  };

  # Lower qBittorrent CPU and I/O priority so SSH/interactive sessions get resources first
  # Nice 10 = lower CPU priority; IOSchedulingPriority 7 = lowest best-effort I/O priority
  systemd.services.qbittorrent.serviceConfig = {
    Nice = 10;
    IOSchedulingClass = "best-effort";
    IOSchedulingPriority = 7;
  };

  # Enable nix-ld for dynamically linked binaries (claude-code, etc.)
  programs.nix-ld.enable = true;

  # Enable 3D acceleration for Proxmox VMs with VirtIO-GPU
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages = with pkgs; [
      # Mesa with full DRI drivers for VirtIO-GPU hardware acceleration
      mesa
      # VirtIO-GPU 3D acceleration support (VirGL renderer)
      virglrenderer
      # Additional OpenGL/EGL support
      libGL
      libGLU
      # Vulkan support for VirtIO-GPU
      vulkan-loader
    ];
  };

  # Proxmox VM-specific environment variables for graphics (override GNOME module)
  environment.sessionVariables = {
    # Enable software rendering fallback for compatibility
    LIBGL_ALWAYS_SOFTWARE = "0";
    # Mesa DRI driver configuration for VMs
    MESA_LOADER_DRIVER_OVERRIDE = "virtio_gpu";
    # Disable AMD Vulkan (RADV) - not applicable to VirtIO-GPU
    # This suppresses "radv/amdgpu: failed to initialize device" errors
    AMD_VULKAN_ICD = "NONE";
    # GSK_RENDERER is now set in gnome.nix
  };

  # Enable Docker
  virtualisation.docker.enable = true;

  # Enable FUSE user_allow_other for SSHFS mounts
  # This allows non-root users to access SSHFS mounts with allow_other option
  # Required for Audiobookshelf to access AudioBooks mount
  programs.fuse.userAllowOther = true;

  # qBittorrent configuration with 2TB disk storage
  modules.services.qbittorrent = {
    enable = true;
    user = "qbittorrent";
    group = "qbittorrent";

    # Storage configuration for 2TB disk
    # Using UUID to prevent disk ordering issues (UUID is stable across reboots)
    storage = {
      device = "/dev/disk/by-uuid/b51ce311-3e53-4541-b793-96a2615ae16e"; # 2TB torrents disk
      mountPoint = "/mnt/torrents";
      format = false; # Set to true ONLY on first setup (WARNING: destroys data!)
      fsType = "ext4";
    };

    # Directory structure on the 2TB disk
    dataDir = "/var/lib/qbittorrent"; # Config stays on system disk
    downloadDir = "/mnt/torrents/completed";
    incompleteDir = "/mnt/torrents/incomplete";
    watchDir = "/mnt/torrents/watch";

    # Network configuration
    port = 8080; # Web UI port
    torrentPort = 6881; # Torrent connection port
    openFirewall = true;

    # Web UI configuration - NO AUTHENTICATION
    webUI = {
      bypassLocalAuth = true; # Disable login for all local network access
      bypassAuthSubnetWhitelist = "192.168.0.0/16, 10.0.0.0/8, 172.16.0.0/12"; # Allow all private networks
    };

    # Seeding limits
    settings = {
      maxRatio = 2.0; # Stop seeding after 2.0 ratio
      maxSeedingTime = 10080; # Stop seeding after 7 days (10080 minutes)
      downloadLimit = null; # Unlimited download speed
      uploadLimit = 1024; # Limit upload to 1MB/s (1024 KB/s)
    };

    # Webhook configuration for automation
    webhook = {
      enable = true;
      url = ""; # Add your Discord/Slack webhook URL here
      # The default script will log completions and optionally send webhook notifications
    };
  };

  # Plex Media Server configuration
  modules.services.plex = {
    enable = true;
    openFirewall = true;

    # Store Plex media on 2TB disk (must be on same filesystem for hardlinks)
    dataDir = "/var/lib/plex"; # Config on system disk
    mediaDir = "/mnt/torrents/plex"; # Media on 2TB disk (in separate subdirectory)

    # Enable libraries
    libraries = {
      movies = true;
      tvShows = true;
      music = false;
      audiobooks = true; # Remote mount from audiobook server (for Plex compatibility)
    };

    # Integration with qBittorrent
    integration.qbittorrent = {
      enable = true;
      autoScan = true; # Automatically scan Plex when new media is added
      useHardlinks = true; # Preserve seeding capability
    };
  };

  # Audiobookshelf - Modern audiobook server (RECOMMENDED for audiobooks)
  modules.services.audiobookshelf = {
    enable = true;
    port = 13378; # Web UI port
    openFirewall = true;

    # Use the same SSHFS mount as Plex (read-only for audiobooks)
    audiobooksDir = "/mnt/torrents/plex/AudioBooks";
    podcastsDir = "/mnt/torrents/podcasts"; # Optional podcasts directory
    dataDir = "/var/lib/audiobookshelf"; # Config and metadata on system disk
  };

  # Disk Guardian - Comprehensive disk monitoring and verification
  # Prevents mount failures from breaking the system
  modules.services.diskGuardian = {
    enable = true;
    enableBootVerification = true; # Verify disks on boot
    enableContinuousMonitoring = true; # Monitor mount health
    monitorInterval = 60; # Check every 60 seconds
  };

  # Cloudflare Tunnel - Secure external access to Audiobookshelf
  # Provides https://audiobooks.home301server.com.br/audiobookshelf/
  # IMPORTANT: Tunnel credentials must be set up locally on the server:
  #   1. cloudflared tunnel login
  #   2. cloudflared tunnel create audiobookshelf
  #   3. Copy credentials to ~/.cloudflared/
  #   4. Create ~/.cloudflared/config.yml with tunnel ID and ingress rules
  # The tunnelId and credentialsFile must be set via server-secrets.nix (gitignored)
  modules.services.cloudflareTunnel = {
    enable = true;
    tunnelName = "audiobookshelf";
    user = "notroot";
    # tunnelId and credentialsFile imported from server-secrets.nix
  };

  # Audiobookshelf Guardian - Health monitoring and protection
  # Ensures Audiobookshelf stays accessible with correct configuration
  modules.services.audiobookshelfGuardian = {
    enable = true;
    healthCheckInterval = 300; # Check every 5 minutes
    enableAutoBackup = true; # Daily database backups
  };

  # SSHFS mount for AudioBooks from audiobook server (192.168.1.7)
  systemd.mounts = [
    {
      what = "notroot@192.168.1.7:/home/notroot/Documents/PLEX_AUDIOBOOK/temp/untagged";
      where = "/mnt/torrents/plex/AudioBooks";
      type = "fuse.sshfs";
      options = "allow_other,default_permissions,_netdev,reconnect,ServerAliveInterval=15,ServerAliveCountMax=3,IdentityFile=/var/lib/qbittorrent/.ssh/id_ed25519,UserKnownHostsFile=/var/lib/qbittorrent/.ssh/known_hosts,StrictHostKeyChecking=no,uid=193,gid=193,umask=002";
      wantedBy = ["multi-user.target"];
    }
  ];

  systemd.automounts = [
    {
      where = "/mnt/torrents/plex/AudioBooks";
      wantedBy = ["multi-user.target"];
    }
  ];

  # JUSTIFIED: Server requires explicit keyboard layout (not inherited from X11)
  console.keyMap = lib.mkForce "br-abnt2";

  # Enable automatic login for the user (matching original config)
  services.displayManager.autoLogin.enable = true;
  services.displayManager.autoLogin.user = "notroot";

  # ===== SSH WELCOME BANNER =====
  # Nice MOTD shown on SSH login and local console (via PAM)
  users.motd = ''
    ${c "38;5;39"}╔═══════════════════════════════════════════════════════════════╗
    ║${reset} ${c "1;37"} NixOS Server${reset} ${c "38;5;245"}•${reset} ${c "38;5;75"}Media & Services Hub${reset}                          ${c "38;5;39"}║
    ╠═══════════════════════════════════════════════════════════════╣${reset}
    ${c "38;5;39"}║${reset}  ${c "38;5;208"}󰒍${reset}  Plex          ${c "38;5;245"}:${reset} ${c "38;5;255"}http://192.168.1.169:32400${reset}              ${c "38;5;39"}║
    ║${reset}  ${c "38;5;40"}󰦐${reset}  qBittorrent   ${c "38;5;245"}:${reset} ${c "38;5;255"}http://192.168.1.169:8080${reset}               ${c "38;5;39"}║
    ║${reset}  ${c "38;5;135"}󰋋${reset}  Audiobookshelf${c "38;5;245"}:${reset} ${c "38;5;255"}https://audiobooks.home301server.com.br${reset} ${c "38;5;39"}║
    ╠═══════════════════════════════════════════════════════════════╣${reset}
    ${c "38;5;39"}║${reset}  ${c "38;5;245"}Storage:${reset} ${c "38;5;255"}/mnt/torrents${reset} ${c "38;5;245"}(2TB)${reset}                               ${c "38;5;39"}║
    ║${reset}  ${c "38;5;245"}Config:${reset}  ${c "38;5;255"}~/NixOS${reset} ${c "38;5;245"}(flake.nix)${reset}                              ${c "38;5;39"}║
    ╚═══════════════════════════════════════════════════════════════╝${reset}

  '';

  # Disable SSH's own PrintMotd - PAM (via users.motd) handles it
  # This prevents the MOTD from showing twice on SSH login
  services.openssh.settings.PrintMotd = false;

  # JUSTIFIED: Server profile doesn't import common.nix directly, needs explicit enables
  modules.packages = {
    browsers.enable = lib.mkForce true;
    media.enable = lib.mkForce true;
    gaming.enable = lib.mkForce false; # Keep disabled for server
    audioVideo.enable = lib.mkForce true;
  };

  # Server-specific monitoring packages
  environment.systemPackages = with pkgs; [
    # Server monitoring and management
    iotop
    nethogs
    ncdu
    lsof
    strace
    htop
    btop

    # Additional server tools
    wget
    git
    claude-code
    # opencode  # Disabled: bun uses CPU instructions not available in this VM
    uv # Python package and environment manager
    sshpass # For SSH automation
    sshfs # For mounting remote filesystems

    # Proxmox VM guest tools
    qemu-utils
    spice-vdagent

    # X11 utilities for Xwayland compatibility
    xorg.xprop

    # Nix helper tool (from desktop branch)
    nh
    alejandra  # Nix formatter
  ];

  # System state version
  system.stateVersion = systemVersion;
}
