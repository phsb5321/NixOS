# ~/NixOS/hosts/modules/core/default.nix
{
  inputs,
  config,
  lib,
  pkgs,
  stablePkgs,
  ...
}: let
  cfg = config.modules.core;
in {
  imports = [
    ./fonts.nix
    ./gaming.nix # Import the gaming module here
    ./java.nix
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

    # System version
    system.stateVersion = cfg.stateVersion;

    # Basic system configuration
    time.timeZone = cfg.timeZone;
    i18n.defaultLocale = cfg.defaultLocale;

    # Nix configuration
    nix = {
      settings = {
        auto-optimise-store = true;
        experimental-features = ["nix-command" "flakes"];
        timeout = 14400; # 4 hours
      };
      gc = {
        automatic = true;
        dates = "weekly";
        options = "--delete-older-than 30d";
      };
    };

    # Security configuration
    security = {
      sudo.wheelNeedsPassword = true;
      auditd.enable = true;
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

    # Boot configuration
    boot.tmp.useTmpfs = lib.mkDefault true;

    # Core system services
    services = {
      fstrim.enable = true;
      thermald.enable = true;
      printing.enable = true;
    };

    # Virtualization configuration
    virtualisation = {
      containers.enable = true;

      docker = {
        enable = true;
        daemon.settings = {
          dns = ["8.8.8.8" "8.8.4.4"];
        };
        rootless = {
          enable = true;
          setSocketVariable = true;
        };
      };

      podman = {
        enable = true;
        # Removed dockerCompat since we're running Docker alongside Podman
        defaultNetwork.settings.dns_enabled = true;
        enableNvidia = false;
      };

      oci-containers = {
        backend = "podman";
        containers = {};
      };
    };

    # Common system packages
    environment.systemPackages = with pkgs;
      [
        # System Utilities
        wget
        vim
        coreutils
        parallel
        zip
        unzip
        tree
        eza
        zoxide
        ripgrep
        fd
        gum
        piper-tts
        jq
        popsicle
        stablePkgs.awscli2
        rbw
        inputs.firefox-nightly.packages.${pkgs.system}.firefox-nightly-bin
        vdhcoapp

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
        nosql-workbench

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
      fish.enable = true;
      dconf.enable = true;
    };
  };
}
