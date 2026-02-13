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
    passwordAuthentication = false;
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
    dhcpcd.extraConfig = "nohook resolv.conf";
    nameservers = ["8.8.8.8" "8.8.4.4" "1.1.1.1" "1.0.0.1"];
    # Waydroid-specific: trust its interface, allow DHCP/DNS
    firewall.trustedInterfaces = ["waydroid0"];
    firewall.allowedUDPPorts = [53 67];
  };

  services.resolved = {
    enable = true;
    dnssec = "allow-downgrade";
    dnsovertls = "opportunistic";
    fallbackDns = ["8.8.8.8" "8.8.4.4"];
    domains = ["~."];
    settings.Resolve = {
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

  # ===== DOCKER DNS =====
  modules.core.dockerDns.enable = true;

  # ===== MEMORY MANAGEMENT =====
  # 3-layer defense against RAM exhaustion freezes (012-memory-limit-freeze-fix)
  # Layer 1: ZRAM compressed swap (zstd, 50% of 62GB RAM)
  # Layer 2: earlyoom (kills runaway processes before kernel OOM freezes desktop)
  # Layer 3: cgroup limits on nix-daemon and Docker
  modules.core.memoryManagement = {
    enable = true;
    # Defaults are tuned for 62GB desktop: zram 50%, earlyoom 5%/10%, nix-daemon 48G/56G, docker 40G
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
      "preempt=full"
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
    };

    kernelModules = ["kvm-intel" "amdgpu"];
  };

  # ===== HARDWARE =====
  hardware.cpu.intel.updateMicrocode = true;

  # ===== PROGRAMS =====
  # Steam configuration moved to modules.gaming.steam (see GAMING CONFIGURATION section above)
  # zsh and defaultUserShell are set in profiles/common.nix

  # ===== HOST-SPECIFIC USER CONFIGURATION =====
  users.groups.plugdev = {};
  users.users.notroot.extraGroups = lib.mkAfter [
    "wheel"
    "networkmanager"
    "dialout"
    "libvirtd"
    "plugdev"
  ];

  # ===== POWER MANAGEMENT =====
  powerManagement = {
    cpuFreqGovernor = "powersave"; # Let GameMode switch dynamically to performance
    resumeCommands = ''
      ${pkgs.systemd}/bin/systemctl restart systemd-resolved
      ${pkgs.systemd}/bin/systemctl restart NetworkManager
    '';
  };

  # ===== SECURITY =====
  # PAM/GDM and AppArmor handled by modules/desktop/gnome/settings.nix and modules/core/base/system.nix
  security = {
    # auditd disabled — execve rule generated 162GB logs on desktop
  };

  # ===== VIRTUALIZATION =====
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
  xdg.mime.enable = true;

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
    };
  };

  # ===== SYSTEM STATE VERSION =====
  # Canonical source: modules.core.stateVersion (line 294)
}
