# NixOS Desktop Configuration - Profile-Based (New Architecture)
# This is the new modular configuration using profiles, GPU abstraction, and modular packages
{
  pkgs,
  lib,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    ../../modules
    ../../profiles/desktop.nix
    ./gnome.nix
  ];

  # ===== PROFILE-BASED CONFIGURATION =====
  # Desktop profile enables: GNOME, gaming, full features, services, dotfiles
  modules.profiles.desktop.enable = true;

  # ===== GPU CONFIGURATION =====
  # AMD RX 5700 XT (Navi 10) with gaming optimizations
  modules.gpu.amd = {
    enable = true;
    model = "navi10";
    powerManagement = true;
    gaming = true; # Enable 32-bit support and performance tweaks
  };

  # ===== GAMING CONFIGURATION =====
  # Steam with Proton and runtime library support
  modules.gaming.steam = {
    enable = true;
    protontricks.enable = true;
    geProton.enable = true;
    remotePlay.enable = false;
    # gamescopeSession defaults to false
  };

  modules.gaming.protontricks = {
    enable = true;
    helperScripts = true; # Provides install-vcrun2019, install-vcrun2022, list-steam-games, fix-frostpunk
  };

  # Shader compilation optimization (003-gaming-optimization - Phase 3: US1)
  modules.gaming.shaderCache = {
    enable = true;
    enableRADVGPL = true; # Graphics Pipeline Library for compile-time shader processing
    enableNGGC = true; # Next-Gen Geometry Culling for AMD GPUs
    enableSteamPreCache = true; # Steam's built-in Vulkan shader pre-caching
  };

  # CPU optimization for gaming (003-gaming-optimization - Phase 5: US3)
  modules.gaming.gamemode = {
    enable = true;
    enableRenice = true; # Increase game process priority
    renice = 10; # Nice value adjustment (higher = more aggressive priority boost)
    softRealtime = "auto"; # Soft real-time scheduling
    inhibitScreensaver = true; # Prevent screensaver during gaming
  };

  # Performance monitoring (003-gaming-optimization - Phase 6: US4)
  modules.gaming.mangohud.enable = true;

  # ===== GNOME DESKTOP =====
  modules.desktop.gnome = {
    enable = true;

    # Base configuration
    displayManager = true;
    coreServices = true;
    coreApplications = true;
    themes = true;
    portal = true;
    powerManagement = true;

    # Extensions
    extensions = {
      enable = true;
      appIndicator = true;
      dashToDock = true;
      userThemes = true;
      justPerfection = true;
      vitals = true;
      caffeine = true;
      clipboard = true;
      gsconnect = true;
      workspaceIndicator = true;
      soundOutputChooser = false;
      productivity = false;
    };

    # Settings
    settings = {
      enable = true;
      darkMode = true;
      animations = true;
      hotCorners = false;
      batteryPercentage = true;
      weekday = true;
    };

    # Wayland configuration
    wayland = {
      enable = true; # Reverted back to Wayland (X11 broke display manager)
      electronSupport = true;
      screenSharing = true;
      variant = "hardware";
    };
  };

  # ===== PACKAGE CONFIGURATION =====
  # Most defaults come from profiles/common.nix and profiles/desktop.nix
  # Only host-specific overrides needed here
  # (Currently all defaults from profiles are correct for desktop)

  # ===== HOST-SPECIFIC PACKAGES =====
  environment.systemPackages = with pkgs; [
    # AI Development
    claude-code
    opencode

    # Communication
    telegram-desktop
    slack
    zoom-us
    hexchat
    polari
    halloy
    element-desktop

    # Productivity
    libreoffice

    # Advanced media
    blender
    krita
    # kdePackages.kdenlive  # Broken in nixpkgs-unstable (shaderc linking issue)
    # inkscape provided by modules/core/document-tools/latex.nix

    # System monitoring
    iotop
    atop
    smem
    numactl
    stress-ng
    memtester
    mission-center # GTK4 Task Manager for GNOME (CPU/GPU/RAM/disk/network)
    amdgpu_top # AMD GPU monitor — replaces abandoned radeontop
    # turbostat available via: sudo ${config.boot.kernelPackages.turbostat}/bin/turbostat

    # Log analysis & Nix store
    lnav # Interactive log viewer with SQL queries on journalctl
    nix-tree # Interactive Nix store dependency size browser
    nix-output-monitor # Pretty build output (use `nom build` instead of `nix build`)

    # Memory analysis
    heaptrack
    # massif-visualizer # Temporarily disabled: broken CMake compatibility in nixpkgs-unstable

    # Disk utilities
    ncdu
    duf

    # Development
    git-crypt
    gnupg

    # Waydroid custom desktop entry (visible in GNOME, overrides default)
    (pkgs.makeDesktopItem {
      name = "waydroid";
      desktopName = "Waydroid";
      exec = "waydroid show-full-ui";
      icon = "waydroid";
      categories = ["System" "Emulator"];
      comment = "Android container";
    })
  ];

  # ===== SERVICES =====
  # Services enabled by desktop role: syncthing, printing, ssh
  # Additional service configuration:
  modules.services.ssh = {
    enable = true;
    permitRootLogin = "no";
    passwordAuthentication = true;
  };

  # ===== SYNCTHING - Sync with Laptop over Tailscale =====
  # SETUP INSTRUCTIONS:
  # 1. Get device IDs: syncthing --device-id (on each device)
  # 2. Get Tailscale IPs: tailscale ip -4 (on each device)
  # 3. Replace PLACEHOLDER-ID below with laptop's actual device ID
  # 4. Uncomment tailscaleIP and set desktop's Tailscale IP
  # 5. Update laptop addresses with laptop's Tailscale IP
  # 6. Rebuild: sudo nixos-rebuild switch --flake .#desktop
  modules.services.syncthing = {
    enable = true;
    tailscaleOnly = true;
    tailscaleIP = "100.84.167.121"; # Desktop's Tailscale IP

    devices = {
      laptop = {
        id = "CJXGF4Y-4OJV2AQ-A2PIR34-TQPKFIX-2ZP6UPS-AGAAJJC-2ESGAAU-3KYQIQK";
        addresses = ["tcp://100.71.57.6:22000"]; # Laptop's Tailscale IP
      };
    };

    folders = {
      # Code projects - bidirectional sync
      code = {
        path = "/home/notroot/Documents/Code";
        devices = ["laptop"];
        ignorePerms = true;
        versioning = {
          type = "staggered";
          params = {
            cleanInterval = "3600";
            maxAge = "2592000"; # 30 days
          };
        };
        ignorePatterns = [
          "**/postgres_data"
          "**/mongo_data"
          "**/mysql_data"
          "**/redis_data"
          "**/tmp_data"
          "**/node_modules"
          "**/.direnv"
          "**/__pycache__"
          "**/.venv"
          "**/venv"
          "**/target"
          "**/.next"
          "**/dist"
          "**/.gradle"
          "**/build"
        ];
      };

      # SSH keys and config (send only - desktop is source of truth)
      ssh-config = {
        path = "/home/notroot/.ssh";
        devices = ["laptop"];
        type = "sendonly";
        ignorePerms = false;
      };

      # Dotfiles/chezmoi
      dotfiles = {
        path = "/home/notroot/.local/share/chezmoi";
        devices = ["laptop"];
        ignorePerms = true;
      };
    };
  };

  # ===== AUTOMATED BACKUPS TO S3 =====
  # Cost-optimized: zstd max compression, bandwidth cap, tight retention
  # One-time setup required:
  #   1. aws s3 mb s3://nixos-desktop-backups --region us-east-1
  #   2. sudo mkdir -p /etc/restic
  #   3. echo "YOUR-STRONG-PASSWORD" | sudo tee /etc/restic/password && sudo chmod 600 /etc/restic/password
  #   4. sudo tee /etc/restic/aws-env <<< $'AWS_ACCESS_KEY_ID=YOUR_KEY\nAWS_SECRET_ACCESS_KEY=YOUR_SECRET\nAWS_DEFAULT_REGION=us-east-1' && sudo chmod 600 /etc/restic/aws-env
  #   5. After rebuild: sudo restic -r s3:s3.us-east-1.amazonaws.com/nixos-desktop-backups init
  modules.services.backup = {
    enable = true;
    s3Bucket = "nixos-desktop-backups";
    s3Region = "us-east-1";
    paths = [
      "/home/notroot/Documents"
      "/home/notroot/.ssh"
      "/home/notroot/.config"
    ];
    exclude = [
      # Browser data (large, not worth backing up — re-login is fine)
      "/home/notroot/.config/chromium"
      "/home/notroot/.config/google-chrome"
      "/home/notroot/.config/BraveSoftware"
      # Electron app caches
      "/home/notroot/.config/Code/CachedData"
      "/home/notroot/.config/Code/CachedExtensions"
      "/home/notroot/.config/Code/Cache"
      "/home/notroot/.config/discord/Cache"
      "/home/notroot/.config/Slack/Cache"
      "/home/notroot/.config/spotify/Users"
      # Large binary/media (not code, not config)
      "/home/notroot/Documents/**/*.iso"
      "/home/notroot/Documents/**/*.img"
      "/home/notroot/Documents/**/*.qcow2"
    ];
    # Cost control: ~17 snapshots max at any time
    retention = {
      keepDaily = 7;
      keepWeekly = 4;
      keepMonthly = 6;
    };
    bandwidthLimit = 51200; # 50 MiB/s in KiB/s — cap upload to control S3 transfer costs
  };

  # ===== SAMBA MOUNTS =====
  # Credentials file must be created manually (NOT in git):
  #   sudo mkdir -p /etc/samba/credentials
  #   echo -e 'username=notroot\npassword=YOUR_PASSWORD_HERE' | sudo tee /etc/samba/credentials/dokku-storage
  #   sudo chmod 600 /etc/samba/credentials/dokku-storage
  modules.services.sambaMounts = {
    enable = true;
    mounts.dokku-storage = {
      remotePath = "//100.99.218.39/dokku-storage";
      mountPoint = "/mnt/dokku";
      credentialsFile = "/etc/samba/credentials/dokku-storage";
    };
  };

  # ===== NETWORKING =====
  modules.networking.tailscale = {
    enable = true;
    useRoutingFeatures = "both";
    extraUpFlags = [
      "--advertise-exit-node"
      "--accept-routes"
    ];
  };

  modules.networking.firewall = {
    enable = true;
    tailscaleCompatible = true;
    developmentPorts = [3000 3001 8080 8000];
  };

  modules.networking.remoteDesktop = {
    enable = true;
    client.enable = true;
    server.enable = false;
  };

  # DNS configuration
  networking = {
    wireless.enable = lib.mkForce false; # Desktop is wired-only, disable WiFi
    dhcpcd.extraConfig = "nohook resolv.conf";
    nameservers = ["8.8.8.8" "8.8.4.4" "1.1.1.1" "1.0.0.1"];
    # Waydroid-specific: trust its interface, allow DHCP/DNS
    firewall.trustedInterfaces = ["waydroid0"];
    firewall.allowedUDPPorts = [53 67];
  };

  # Disable WiFi in NetworkManager - desktop is ethernet-only
  networking.networkmanager.unmanaged = ["interface-name:wlp9s0"];

  services.resolved = {
    enable = true;
    settings.Resolve = {
      DNSSEC = "allow-downgrade"; # Validate DNSSEC when available, fall back gracefully
      DNSOverTLS = "opportunistic"; # Encrypt DNS when resolver supports TLS, fall back to plaintext
      FallbackDNS = ["8.8.8.8" "8.8.4.4"];
      Domains = "~.";
      DNSStubListener = "yes";
      DNSStubListenerExtra = "0.0.0.0";
      Cache = "yes";
    };
  };

  # ===== CORE MODULES =====
  modules.core = {
    enable = true;
    stateVersion = "25.11";
    timeZone = "America/Recife";
    defaultLocale = "en_US.UTF-8";

    # NOTE: Intel AX210 Bluetooth requires internal USB header cable from PCIe adapter
    # to motherboard USB 2.0 header. If BT is missing after boot, verify cable connection.
    # Diagnostic: lsusb | grep -i intel && sudo dmesg | grep -iE 'btusb|bluetooth'
    pipewire = {
      enable = true;
      highQualityAudio = true;
      bluetooth.enable = true;
      bluetooth.highQualityProfiles = true;
      lowLatency = false;
      tools.enable = true;
    };

    java = {
      enable = true;
      androidTools.enable = true;
    };

    documentTools = {
      enable = true;
      latex = {
        enable = true;
        minimal = false;
      };
      markdown = {
        enable = true;
        lsp = true;
        linting = {
          enable = true;
          markdownlint = true;
          vale = {
            enable = true;
            styles = ["google" "write-good"];
          };
          linkCheck = true;
        };
        formatting = {
          enable = true;
          mdformat = true;
          prettier = false;
        };
        preview = {
          enable = true;
          glow = true;
          grip = false;
        };
        utilities = {
          enable = true;
          doctoc = true;
          mdbook = true;
          mermaid = true;
        };
      };
    };
  };

  # ===== NIX DAEMON SCHEDULING =====
  # Lower CPU/IO priority so desktop stays responsive during builds
  nix.daemonCPUSchedPolicy = "batch"; # Non-interactive CPU scheduling
  nix.daemonIOSchedClass = "idle"; # I/O only when desktop doesn't need it
  nix.daemonIOSchedPriority = 7; # Lowest within class
  # Route large nix builds to disk-backed /var/tmp instead of tmpfs (prevents OOM)
  systemd.services.nix-daemon.environment.TMPDIR = "/var/tmp";

  # ===== DOCKER =====
  modules.core.dockerDns.enable = true;
  # Docker log rotation — prevents silent disk bloat from container logs
  virtualisation.docker.daemon.settings = {
    log-driver = "json-file";
    log-opts = {
      max-size = "10m";
      max-file = "3";
    };
    live-restore = true; # Keep containers running during daemon restart
  };

  # ===== MEMORY MANAGEMENT =====
  # 3-layer defense against RAM exhaustion freezes (012-memory-limit-freeze-fix)
  # Layer 1: ZRAM compressed swap (zstd, 50% of 62GB RAM)
  # Layer 2: earlyoom (kills runaway processes before kernel OOM freezes desktop)
  # Layer 3: cgroup limits (lowered to guarantee 20GB+ for desktop apps)
  modules.core.memoryManagement = {
    enable = true;
    nixDaemon.memoryHigh = "32G"; # Was 48G — leaves more for IDE/browser
    nixDaemon.memoryMax = "40G"; # Was 56G
    docker.memoryMax = "24G"; # Was 40G
  };

  # ===== DOTFILES =====
  modules.dotfiles = {
    enable = true;
    enableHelperScripts = true;
  };

  # ===== BOOT CONFIGURATION =====
  boot = {
    # tmp.useTmpfs handled by modules/core/base/system.nix (mkDefault)
    kernelPackages = pkgs.linuxPackages_6_12;

    kernelParams = [
      "preempt=full" # Full preemption for desktop responsiveness
      "split_lock_detect=off" # Small perf win in some games (avoids #AC exception overhead)
      "transparent_hugepage=madvise" # Apps opt-in to THP (Proton/Wine use this)
    ];

    kernel.sysctl = {
      # IPv4 forwarding for Waydroid NAT (custom nftables rules handle masquerade)
      "net.ipv4.conf.all.forwarding" = 1;
      "net.ipv4.conf.default.forwarding" = 1;
      # Desktop I/O tuning (vm.swappiness and vm.page-cluster managed by memoryManagement module)
      "vm.dirty_ratio" = 15;
      "vm.dirty_background_ratio" = 5;
      "vm.dirty_expire_centisecs" = 500;
      "vm.dirty_writeback_centisecs" = 100;
      "kernel.sched_autogroup_enabled" = 1;
      # JUSTIFIED: Gaming requires higher file descriptor limit than base default
      "fs.file-max" = 4194304;
      "fs.aio-max-nr" = 1048576;
      # Network performance — TCP BBR + tuning
      "net.core.default_qdisc" = "fq";
      "net.ipv4.tcp_congestion_control" = "bbr";
      "net.ipv4.tcp_fastopen" = 3;
      "net.ipv4.tcp_slow_start_after_idle" = 0;
      "net.ipv4.tcp_mtu_probing" = 1;
      "net.ipv4.tcp_rmem" = "4096 131072 16777216";
      "net.ipv4.tcp_wmem" = "4096 65536 16777216";
      "net.core.rmem_max" = 16777216;
      "net.core.wmem_max" = 16777216;
      "net.core.netdev_max_backlog" = 16384;
      "net.core.somaxconn" = 8192;
      "net.ipv4.tcp_fin_timeout" = 15;
      "net.ipv4.tcp_keepalive_time" = 300;
      "net.ipv4.tcp_keepalive_intvl" = 30;
      "net.ipv4.tcp_keepalive_probes" = 5;
      # Reduce bufferbloat for interactive apps (Google recommendation)
      "net.ipv4.tcp_notsent_lowat" = 16384;
    };

    kernelModules = ["kvm-intel" "amdgpu" "tcp_bbr"];
  };

  # ===== HARDWARE =====
  hardware.cpu.intel.updateMicrocode = true;

  # ===== PROGRAMS =====
  # Steam configuration moved to modules.gaming.steam (see GAMING CONFIGURATION section above)
  # zsh and defaultUserShell are set in profiles/common.nix

  # Package discovery — replaces broken command-not-found on flakes
  programs.command-not-found.enable = false; # Disable channel-based command-not-found
  programs.nix-index = {
    enable = true;
    enableZshIntegration = true; # Auto-suggest packages for missing commands
  };
  programs.nix-index-database.comma.enable = true; # , cowsay = instant-run any package

  # Auto-activate dev shells on cd into project directories
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true; # Persistent caching — re-entering is instant
    silent = true; # Suppress noisy output
  };

  # NH module with automatic garbage collection
  programs.nh = {
    enable = true;
    clean = {
      enable = true;
      extraArgs = "--keep-since 7d --keep 5";
    };
    flake = "/home/notroot/NixOS";
  };

  # Compiler cache for C/C++ source builds
  programs.ccache.enable = true;
  programs.ccache.cacheDir = "/var/cache/ccache";

  # Gamescope — micro-compositor for better frame pacing, VRR, and FSR
  programs.gamescope = {
    enable = true;
    capSysNice = true; # Allow priority boost for gamescope
  };

  # ===== HOST-SPECIFIC USER CONFIGURATION =====
  users.groups.plugdev = {};
  users.users.notroot.extraGroups = lib.mkAfter [
    "wheel"
    "networkmanager"
    "dialout"
    "plugdev"
  ];

  # ===== POWER MANAGEMENT =====
  powerManagement = {
    cpuFreqGovernor = "schedutil"; # Scales with CPU demand; GameMode still switches to performance
    resumeCommands = ''
      ${pkgs.systemd}/bin/systemctl restart systemd-resolved
      ${pkgs.systemd}/bin/systemctl restart NetworkManager
    '';
  };

  # Kernel memory tuning — MGLRU and THP optimization
  systemd.tmpfiles.rules = [
    "w /sys/kernel/mm/lru_gen/min_ttl_ms - - - - 1000" # MGLRU: prevent working set eviction during gaming load spikes
    "w /sys/kernel/mm/transparent_hugepage/defrag - - - - defer+madvise" # THP: sync defrag for madvise (games), async for background
    "w /sys/kernel/mm/transparent_hugepage/khugepaged/defrag - - - - 1" # THP: enable khugepaged background defrag
  ];

  # Disable hibernate/hybrid-sleep but allow suspend
  systemd.targets.hibernate.enable = false;
  systemd.targets.hybrid-sleep.enable = false;

  # ===== SECURITY =====
  # PAM/GDM and AppArmor handled by modules/desktop/gnome/settings.nix and modules/core/base/system.nix
  security = {
    # auditd disabled — execve rule generated 162GB logs on desktop
  };

  # ===== HEALTH MONITORING =====
  # SMART disk health monitoring with desktop notifications
  services.smartd = {
    enable = true;
    autodetect = true;
    notifications = {
      wall.enable = true;
      systembus-notify.enable = true;
    };
  };
  services.systembus-notify.enable = true;

  # Network traffic tracking
  services.vnstat.enable = true;

  # Desktop notification on systemd service failure
  systemd.services."notify-failure@" = {
    description = "Desktop notification on service failure for %i";
    serviceConfig = {
      Type = "oneshot";
      User = "notroot";
      Environment = [
        "DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus"
      ];
    };
    script = ''
      ${pkgs.libnotify}/bin/notify-send \
        --urgency=critical \
        --app-name="systemd" \
        "Service Failed: $1" \
        "$(${pkgs.systemd}/bin/journalctl -u "$1" -n 3 --no-pager -o cat)"
    '';
    scriptArgs = "%i";
  };

  # Attach failure notifications to critical services
  systemd.services.restic-backups-s3-daily.unitConfig.OnFailure = "notify-failure@%n.service";
  systemd.services.docker.unitConfig.OnFailure = "notify-failure@%n.service";
  systemd.services.tailscaled.unitConfig.OnFailure = "notify-failure@%n.service";
  systemd.services.syncthing.unitConfig.OnFailure = "notify-failure@%n.service";

  # ===== VIRTUALIZATION =====
  # QEMU/KVM + virt-manager with SPICE display and Windows 11 support
  modules.virtualization.libvirt = {
    enable = true;
    windowsSupport = true;
  };

  # Waydroid - Android container for Linux (priority feature)
  # Default waydroid 1.5.4+ already has LXC_USE_NFT="true" for nftables
  # Base module defaults to false, so simple enable works
  virtualisation.waydroid.enable = true;

  # nftables NAT rules for Waydroid (interface-agnostic, no hardcoded names)
  networking.nftables.tables.waydroid-nat = {
    family = "ip";
    content = ''
      chain postrouting {
        type nat hook postrouting priority srcnat; policy accept;
        ip saddr 192.168.240.0/24 oifname != "waydroid0" masquerade
      }
      chain forward {
        type filter hook forward priority filter; policy accept;
        iifname "waydroid0" oifname != "waydroid0" accept
        iifname != "waydroid0" oifname "waydroid0" ct state related,established accept
      }
    '';
  };

  # System-level Waydroid desktop entry (visible in GNOME, can't be overwritten by Waydroid)
  environment.etc."xdg/autostart/waydroid-fix.desktop".enable = false; # Don't autostart

  # Waydroid desktop entry hygiene - hide per-app launchers from GNOME
  # Replaces .desktop files with /dev/null symlinks to prevent clutter
  modules.services.waydroid-desktop-hygiene.enable = true;

  # ===== SYSTEMD SERVICES =====
  # GNOME login fixes (getty/autovt) are in modules/desktop/gnome/settings.nix

  # AMD GPU optimization
  systemd.services.amd-gpu-optimization = {
    description = "AMD GPU Performance Optimization";
    after = ["graphical-session.target"];
    wantedBy = ["multi-user.target"];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = pkgs.writeShellScript "amd-gpu-optimization" ''
        echo "auto" > /sys/class/drm/card0/device/power_dpm_force_performance_level 2>/dev/null || true
        echo "1" > /sys/class/drm/card0/device/power_dpm_state 2>/dev/null || true
      '';
      # Hardening: partial sandbox (needs /sys write access for GPU tuning)
      ProtectHome = true;
      PrivateTmp = true;
      PrivateDevices = false; # Needs device access for GPU
      NoNewPrivileges = true;
      ProtectKernelModules = true;
      ProtectKernelLogs = true;
      ProtectControlGroups = true;
      ProtectClock = true;
      ProtectHostname = true;
      RestrictSUIDSGID = true;
      RestrictRealtime = true;
      LockPersonality = true;
      UMask = "0077";
    };
  };

  # DNS health check
  systemd.timers.dns-health-check = {
    wantedBy = ["timers.target"];
    partOf = ["dns-health-check.service"];
    timerConfig = {
      OnCalendar = "*:0/5";
      Persistent = true;
    };
  };

  systemd.services.dns-health-check = {
    serviceConfig = {
      Type = "oneshot";
      ExecStart = pkgs.writeShellScript "dns-health-check" ''
        if ! ${pkgs.systemd}/bin/resolvectl query google.com >/dev/null 2>&1; then
          ${pkgs.systemd}/bin/systemctl restart systemd-resolved
          sleep 2
          ${pkgs.systemd}/bin/systemctl restart NetworkManager
        fi
      '';
      # Hardening: heavy sandbox (lightweight network check, no root needed for resolvectl)
      ProtectSystem = "strict";
      ProtectHome = true;
      PrivateTmp = true;
      PrivateDevices = true;
      NoNewPrivileges = true;
      ProtectKernelTunables = true;
      ProtectKernelModules = true;
      ProtectKernelLogs = true;
      ProtectControlGroups = true;
      ProtectClock = true;
      ProtectHostname = true;
      RestrictNamespaces = true;
      RestrictSUIDSGID = true;
      RestrictRealtime = true;
      LockPersonality = true;
      MemoryDenyWriteExecute = true;
      SystemCallArchitectures = "native";
      UMask = "0077";
    };
  };

  # ===== SYSTEM STATE VERSION =====
  # Canonical source: modules.core.stateVersion (line 294)
}
