# ~/NixOS/modules/core/default.nix
#
# Module: Core System (Orchestrator)
# Purpose: Main orchestrator for core system configuration
# Part of: 001-module-optimization (T030-T034 - split into base/ directory)
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
    # Base system configuration
    ./base/options.nix
    ./base/system.nix

    # Feature modules
    ./fonts.nix
    ./java.nix
    ./docker-dns.nix
    ./memory-management.nix
    ./pipewire.nix
    ./monitor-audio.nix
    ./document-tools
    ../hardware/amd-gpu.nix
  ];

  config = lib.mkIf cfg.enable {
    # Enable fonts module
    modules.core.fonts = {
      enable = true;
      packages = with pkgs; [
        nerd-fonts.jetbrains-mono
        nerd-fonts.fira-code
        noto-fonts
        noto-fonts-cjk-sans
        noto-fonts-color-emoji
        liberation_ttf
        cantarell-fonts
      ];
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
      typst = {
        enable = lib.mkDefault true;
        lsp = lib.mkDefault true; # Enable tinymist LSP by default
      };
      markdown = {
        enable = lib.mkDefault true;
        lsp = lib.mkDefault true;
        linting = {
          enable = lib.mkDefault true;
          markdownlint = lib.mkDefault true;
          vale = {
            enable = lib.mkDefault false; # Disabled by default to save space
            styles = lib.mkDefault [];
          };
          linkCheck = lib.mkDefault false; # Disabled by default to save space
        };
        formatting = {
          enable = lib.mkDefault true;
          mdformat = lib.mkDefault true;
          prettier = lib.mkDefault false;
        };
        preview = {
          enable = lib.mkDefault true;
          glow = lib.mkDefault true;
          grip = lib.mkDefault false;
        };
        utilities = {
          enable = lib.mkDefault false; # Disabled by default to save space
          doctoc = lib.mkDefault false;
          mdbook = lib.mkDefault false;
          mermaid = lib.mkDefault false;
        };
      };
    };

    # AMD GPU optimizations - DISABLED by default, enable in host-specific config
    # modules.hardware.amdgpu = {
    #   enable = true;
    #   model = "navi10"; # RX 5700 XT uses Navi 10
    #   powerManagement = true;
    # };

    # Enable proper time synchronization for time-sensitive tokens
    services.timesyncd.enable = true;

    # System version
    system.stateVersion = cfg.stateVersion;

    # Basic system configuration
    time.timeZone = cfg.timeZone;
    i18n.defaultLocale = cfg.defaultLocale;

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
        jq
        popsicle
        stablePkgs.awscli2
        rbw
        inputs.firefox-nightly.packages.${system}.firefox-nightly-bin
        codex
        wrangler
        just
        infisical
        httpx

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

        # System Monitoring
        fastfetch
        htop

        # Development Tools
        git
        gh
        gcc
        xclip
        lazygit

        # Remote Desktop
        remmina # Remote desktop client with VNC, RDP, SSH, SPICE support

        # Terminals and Shells
        zellij
        wl-clipboard # Required for Zellij clipboard integration on Wayland
        sshfs

        # Development
        elixir
        nodejs_22
        go
        elixir-ls
        pkgs-unstable.ghostty

        # Nix Tools
        alejandra
        nixd
        nil
        nh

        # Container Tools
        podman-compose
        podman-tui
        dive
      ]
      ++ cfg.extraSystemPackages;

    # Default system-wide shell and programs
    programs = {
      nix-ld.enable = true;
      zsh.enable = true;
      dconf.enable = true;
      # NOTE: programs.adb removed - systemd 258+ handles uaccess rules automatically
      # ADB is now provided via android-tools package in modules/core/java.nix
    };
  };
}
