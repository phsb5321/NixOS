# NixOS Desktop Configuration - Role-Based (New Architecture)
# This is the new modular configuration using roles, GPU abstraction, and modular packages
{
  config,
  pkgs,
  lib,
  hostname,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    ../../modules
  ];

  # ===== ROLE-BASED CONFIGURATION =====
  # Desktop role enables: GNOME, gaming, full features, services, dotfiles
  modules.roles.desktop.enable = true;

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
      enable = true;  # Reverted back to Wayland (X11 broke display manager)
      electronSupport = true;
      screenSharing = true;
      variant = "hardware";
    };
  };

  # ===== PACKAGE CONFIGURATION =====
  modules.packages = {
    # Browsers
    browsers = {
      enable = true;
      chrome = true;
      brave = true;
      librewolf = true;
      zen = true;
    };

    # Development tools
    development = {
      enable = true;
      editors = true;
      apiTools = true;
      runtimes = true;
      compilers = true;
      languageServers = true;
      versionControl = true;
      utilities = true;
      database = true;
      containers = true;
      debugging = true;
      networking = true;
    };

    # Media
    media = {
      enable = true;
      vlc = true;
      spotify = true;
      discord = true;
      streaming = true;
      imageEditing = true;
    };

    # Gaming
    gaming = {
      enable = true;
      performance = true;
      launchers = true;
      wine = true;
      gpuControl = true;
      minecraft = false;
    };

    # Utilities
    utilities = {
      enable = true;
      diskManagement = true;
      fileSync = false; # Syncthing handled by role
      compression = true;
      security = true;
      pdfViewer = true;
      messaging = true;
      fonts = true;
    };

    # Audio/Video
    audioVideo = {
      enable = true;
      pipewire = true;
      audioEffects = true;
      audioControl = true;
      webcam = true;
    };

    # Terminal
    terminal = {
      enable = true;
      fonts = true;
      shell = true;
      theme = true;
      modernTools = true;
      plugins = true;
      editor = true;
      applications = true;
    };
  };

  # ===== HOST-SPECIFIC PACKAGES =====
  environment.systemPackages = with pkgs; [
    # AI Development
    claude-code

    # Communication
    telegram-desktop
    slack
    zoom-us

    # Productivity
    notion-app-enhanced

    # Advanced media
    blender
    krita
    kdePackages.kdenlive
    inkscape

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
  ];

  # ===== SERVICES =====
  # Services enabled by desktop role: syncthing, printing, ssh
  # Additional service configuration:
  modules.services.ssh = {
    enable = true;
    permitRootLogin = "no";
    passwordAuthentication = false;
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
    firewall.checkReversePath = "loose";
    nftables.enable = true;
  };

  services.resolved = {
    enable = true;
    dnssec = "allow-downgrade";
    domains = ["~."];
    fallbackDns = ["8.8.8.8" "8.8.4.4" "1.1.1.1" "1.0.0.1"];
    extraConfig = ''
      DNSOverTLS=yes
      DNS=8.8.8.8 8.8.4.4 1.1.1.1 1.0.0.1
      FallbackDNS=8.8.8.8 8.8.4.4
      Domains=~.
      DNSSEC=allow-downgrade
      DNSStubListener=yes
      Cache=yes
      DNSStubListenerExtra=0.0.0.0
    '';
  };

  # ===== CORE MODULES =====
  modules.core = {
    enable = true;
    stateVersion = "25.11";
    timeZone = "America/Recife";
    defaultLocale = "en_US.UTF-8";

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
        extraPackages = with pkgs; [
          biber
          texlive.combined.scheme-context
        ];
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

  # ===== DOTFILES =====
  modules.dotfiles = {
    enable = true;
    enableHelperScripts = true;
  };

  # ===== BOOT CONFIGURATION =====
  boot = {
    tmp.useTmpfs = true;
    kernelPackages = pkgs.linuxPackages_6_6;

    kernelParams = [
      "preempt=full"
      "nohz_full=all"
    ];

    kernel.sysctl = {
      "vm.swappiness" = lib.mkForce 1;
      "vm.vfs_cache_pressure" = lib.mkForce 50;
      "vm.dirty_ratio" = lib.mkForce 10;
      "vm.dirty_background_ratio" = lib.mkForce 1;
      "vm.dirty_expire_centisecs" = 500;
      "vm.dirty_writeback_centisecs" = 100;
      "vm.page-cluster" = 0;
      "kernel.sched_autogroup_enabled" = 1;
      "fs.file-max" = lib.mkForce 4194304;
      "fs.aio-max-nr" = 1048576;
    };

    kernelModules = ["kvm-intel" "amdgpu"];
  };

  # ===== HARDWARE =====
  hardware.cpu.intel.updateMicrocode = true;

  # ===== PROGRAMS =====
  # Steam configuration moved to modules.gaming.steam (see GAMING CONFIGURATION section above)

  programs.zsh.enable = true;
  users.defaultUserShell = pkgs.zsh;

  # ===== HOST-SPECIFIC USER CONFIGURATION =====
  users.groups.plugdev = {};
  users.users.notroot.extraGroups = [
    "dialout"
    "libvirtd"
    "plugdev"
    "input"
  ];

  # ===== POWER MANAGEMENT =====
  powerManagement = {
    cpuFreqGovernor = "performance";
    resumeCommands = ''
      ${pkgs.systemd}/bin/systemctl restart systemd-resolved
      ${pkgs.systemd}/bin/systemctl restart NetworkManager
    '';
  };

  # ===== SECURITY =====
  security = {
    pam.services = {
      gdm.enableGnomeKeyring = true;
      gdm-password.enableGnomeKeyring = true;
    };

    auditd.enable = true;
    audit = {
      enable = true;
      backlogLimit = 8192;
      failureMode = "printk";
      rules = ["-a exit,always -F arch=b64 -S execve"];
    };

    apparmor = {
      enable = true;
      killUnconfinedConfinables = true;
    };
  };

  # ===== SYSTEMD SERVICES =====
  # GNOME login fixes
  systemd.services."getty@tty1".enable = false;
  systemd.services."autovt@tty1".enable = false;

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
  system.stateVersion = lib.mkForce "25.11";
}
