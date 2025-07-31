# ~/NixOS/modules/core/default.nix
{
  inputs,
  config,
  lib,
  pkgs,
  stablePkgs,
  pkgs-unstable,
  system,
  ...
}: let
  cfg = config.modules.core;
in {
  imports = [
    ./fonts.nix
    ./gaming.nix
    ./java.nix
    ./docker-dns.nix
    ./pipewire.nix
    ./monitor-audio.nix
    ./document-tools.nix
    ./version-sync.nix
    ./flatpak.nix
    ./gui-app-deps.nix
  ];

  options.modules.core = with lib; {
    enable = mkEnableOption "Core system configuration module";

    stateVersion = mkOption {
      type = types.str;
      description = "The NixOS state version";
    };

    timeZone = mkOption {
      type = types.str;
      default = "UTC";
      description = "System timezone";
    };

    defaultLocale = mkOption {
      type = types.str;
      default = "en_US.UTF-8";
      description = "Default system locale";
    };

    extraSystemPackages = mkOption {
      type = with types; listOf package;
      default = [];
      description = "Additional system-wide packages to install";
    };

    # 🎯 KEYBOARD LAYOUT: Configuration options for Brazilian layout
    keyboard = {
      enable = mkOption {
        type = types.bool;
        default = false; # Disabled by default to let desktop environments handle it
        description = "Enable explicit keyboard configuration";
      };

      layout = mkOption {
        type = types.str;
        default = "br";
        description = "Keyboard layout";
      };

      variant = mkOption {
        type = types.str;
        default = ""; # Default to standard Brazilian ABNT (no variant)
        description = "Keyboard variant";
      };

      options = mkOption {
        type = types.str;
        default = "grp:alt_shift_toggle,compose:ralt";
        description = "Keyboard options";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    # Enable fonts module
    modules.core.fonts = {
      enable = true;
      packages = with pkgs; [
        nerd-fonts.jetbrains-mono
        nerd-fonts.fira-code
        noto-fonts
        noto-fonts-cjk-sans
        noto-fonts-emoji
        liberation_ttf
      ];
    };

    # Enable gaming module
    modules.core.gaming = {
      enable = true;
    };

    # Enable PipeWire module
    modules.core.pipewire = {
      enable = true;
      highQualityAudio = true;
      bluetooth = {
        enable = true;
        highQualityProfiles = true;
      };
      tools.enable = true;
    };

    # Enable monitor audio module
    modules.core.monitorAudio = {
      enable = true;
      autoSwitch = true;
      preferMonitorAudio = false; # Set to true if you want monitors to be the preferred audio output
    };

    # Enable document tools module with LaTeX support (can be overridden by hosts)
    modules.core.documentTools = {
      enable = true;
      latex = {
        enable = lib.mkDefault true;
        minimal = lib.mkDefault false; # Set to true for minimal installation
      };
    };

    # Enable Flatpak module
    modules.core.flatpak = {
      enable = true;
      packages = [
        # Add any Flatpak packages you want to install system-wide
        # "com.spotify.Client"
        # "org.mozilla.firefox"
        # "com.discordapp.Discord"
      ];
      enablePortals = true;
      enableFontconfig = true;
      enableThemes = true;
    };

    # Enable proper time synchronization for time-sensitive tokens
    services.timesyncd.enable = true;

    # System version
    system.stateVersion = cfg.stateVersion;

    # Basic system configuration
    time.timeZone = cfg.timeZone;
    i18n.defaultLocale = cfg.defaultLocale;

    # Nix configuration with performance optimizations
    nix = {
      settings = {
        auto-optimise-store = true;
        experimental-features = [
          "nix-command"
          "flakes"
        ];
        timeout = 14400; # 4 hours
        # Performance optimizations
        cores = 0; # Use all available cores
        max-jobs = "auto"; # Auto-detect optimal parallel jobs
        # Reliability improvements
        require-sigs = true;
        trusted-users = [
          "root"
          "@wheel"
        ];
        # Optimize builds
        builders-use-substitutes = true;
        # Cache configuration
        substituters = [
          "https://cache.nixos.org/"
          "https://nix-community.cachix.org"
        ];
        trusted-public-keys = [
          "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
          "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        ];
      };
      gc = {
        automatic = true;
        dates = "weekly";
        options = "--delete-older-than 30d";
      };
      # Enable distributed builds for better performance
      distributedBuilds = true;
    };

    # Security configuration
    security = {
      sudo.wheelNeedsPassword = true;
      # Disable auditd to prevent massive log files (162GB issue)
      # auditd.enable = true;
      apparmor = {
        enable = true;
        killUnconfinedConfinables = true;
      };
      polkit.enable = true;
      rtkit.enable = true;
    };

    # SSH configuration
    services.openssh = {
      enable = true;
      settings = {
        PermitRootLogin = "no";
        PasswordAuthentication = true;
        KbdInteractiveAuthentication = false;
      };
    };

    # Boot configuration with performance optimizations
    boot = {
      tmp.useTmpfs = lib.mkDefault true;
      # Performance kernel parameters
      kernel.sysctl = {
        # VM optimizations (can be overridden by host-specific configs)
        "vm.swappiness" = lib.mkDefault 10;
        "vm.dirty_ratio" = 15;
        "vm.dirty_background_ratio" = 5;
        "vm.vfs_cache_pressure" = 50;
        # Network performance (can be overridden by networking module)
        "net.core.rmem_max" = lib.mkDefault 268435456;
        "net.core.wmem_max" = lib.mkDefault 268435456;
        "net.core.netdev_max_backlog" = lib.mkDefault 5000;
        # Security hardening
        "kernel.dmesg_restrict" = 1;
        "kernel.kptr_restrict" = 2;
        "net.ipv4.conf.all.log_martians" = 1;
        "net.ipv4.conf.default.log_martians" = 1;
        "net.ipv4.icmp_echo_ignore_broadcasts" = 1;
        "net.ipv4.conf.all.send_redirects" = 0;
        "net.ipv4.conf.default.send_redirects" = 0;
      };
      # ZRAM removed - causing application compatibility issues
      # kernelModules = ["zram"];  # Disabled
    };

    # Core system services
    services = {
      fstrim.enable = true;
      thermald.enable = true;
      printing.enable = true;
    };

    # 🎯 KEYBOARD LAYOUT: Console keymap will be automatically derived from xserver.xkb configuration

    # Configure X11 keyboard layout if X11 is available and keyboard config is enabled
    services.xserver = lib.mkIf (config.services.xserver.enable && cfg.keyboard.enable) {
      xkb = {
        layout = cfg.keyboard.layout;
        variant = cfg.keyboard.variant;
        options = cfg.keyboard.options;
      };
    };

    # Basic systemd-resolved configuration (Docker DNS will depend on this)
    services.resolved = {
      enable = true;
      fallbackDns = [
        "8.8.8.8"
        "8.8.4.4"
        "1.1.1.1"
      ];
    };

    # Virtualization configuration
    virtualisation = {
      containers.enable = true;
      podman = {
        enable = true;
        defaultNetwork.settings.dns_enabled = true;
      };
      oci-containers = {
        backend = "podman";
        containers = {};
      };
      waydroid.enable = false;
    };

    # Common system packages
    environment.systemPackages = with pkgs;
      [
        # System Utilities
        wget
        vim
        coreutils
        parallel
        cloudflared
        zip
        unzip
        tree
        aria2
        parted
        openssl
        nmap
        gum
        piper-tts
        jq
        popsicle
        stablePkgs.awscli2
        azure-cli
        rbw
        inputs.firefox-nightly.packages.${system}.firefox-nightly-bin
        vdhcoapp
        inkscape
        claude-code
        wrangler
        just
        infisical

        # Rust System Utilities (Modern replacements for Unix tools)
        eza # Modern replacement for ls
        zoxide # Smarter cd command
        ripgrep # Fast grep alternative
        fd # Simple, fast alternative to find
        dust # Intuitive du alternative for disk usage
        dua # Interactive disk usage analyzer
        bat # Cat clone with syntax highlighting
        procs # Modern replacement for ps
        bottom # Cross-platform system monitor (btm command)
        tokei # Count lines of code
        hyperfine # Command-line benchmarking tool
        bandwhich # Terminal bandwidth utilization tool
        broot # New way to see and navigate directory trees
        sd # Intuitive find & replace CLI (sed alternative)
        tealdeer # Fast tldr client (tldr command)
        choose # Human-friendly cut alternative
        dog # Command-line DNS lookup tool (dig alternative)

        # System Monitoring
        neofetch
        htop
        cmatrix

        # Development Tools
        git
        gh
        gcc
        stow
        xclip
        lazygit

        # Remote Desktop & Network Tools
        remmina

        # Terminals and Shells
        kitty
        zellij
        sshfs

        # Development
        elixir
        nodejs_22
        go
        terraform
        elixir-ls
        # nosql-workbench  # Temporarily disabled due to download issues
        deno
        postgresql
        supabase-cli
        pkgs-unstable.zed-editor
        pkgs-unstable.ghostty
        stockfish
        chromium

        # Nix Tools
        alejandra
        nixd
        nil

        # Container Tools
        podman-compose
        podman-tui
        dive
      ]
      ++ cfg.extraSystemPackages;

    # Default system-wide shell
    programs = {
      nix-ld.enable = true;
      zsh.enable = true;
      dconf.enable = true;
    };
  };
}
