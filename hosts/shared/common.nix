# ~/NixOS/hosts/shared/common.nix
{
  pkgs,
  lib,
  inputs,
  systemVersion,
  ...
}: {
  # Common configuration shared between all hosts

  # Override gnome-session to fix Wayland wrapper bug
  nixpkgs.overlays = [
    (final: prev: {
      gnome-session = prev.gnome-session.overrideAttrs (oldAttrs: {
        postInstall = (oldAttrs.postInstall or "") + ''
          # Fix the Wayland session wrapper to properly handle the -l flag
          substitute $out/bin/gnome-session $out/bin/gnome-session.tmp \
            --replace "'exec \$0 -l \$*'" "'exec \$0 \$*'"
          mv $out/bin/gnome-session.tmp $out/bin/gnome-session
          chmod +x $out/bin/gnome-session
        '';
      });
    })
  ];

  # Enable shared packages module with common categories
  modules.packages = {
    enable = true;
    browsers.enable = true;
    development.enable = true;
    media.enable = true;
    utilities.enable = true;
    audioVideo.enable = true;
    python = {
      enable = true;
      withGTK = true; # Enable GTK support by default
    };
  };

  # Common core module configuration
  modules.core = {
    enable = true;
    stateVersion = systemVersion;
    timeZone = "America/Recife";
    defaultLocale = "en_US.UTF-8";
    extraSystemPackages = with pkgs; [
      # Bluetooth GUI manager
      blueman

      # System information tools
      pciutils
      usbutils

      # Additional Tools
      speechd
    ];
  };

  # Desktop environment configuration with GDM and GNOME
  modules.desktop = {
    enable = true;
    environment = "gnome";

    # Re-enable Wayland with custom gnome-session wrapper fix
    displayManager = {
      wayland = true;
      autoSuspend = true;
    };

    # Enhanced theming
    theming = {
      preferDark = true;
      accentColor = "blue";
    };

    # Hardware integration
    hardware = {
      enableTouchpad = true;
      enableBluetooth = true;
      enablePrinting = true;
      enableScanning = false; # Keep disabled for now
    };

    autoLogin = {
      enable = false;
      user = "notroot";
    };
    fonts = {
      enable = true;
      packages = with pkgs; [
        nerd-fonts.jetbrains-mono
      ];
      defaultFonts = {
        monospace = ["JetBrainsMono Nerd Font" "FiraCode Nerd Font Mono" "Fira Code"];
      };
    };
  };

  # Use the GNOME Wayland session with fixed wrapper
  services.displayManager.defaultSession = lib.mkForce "gnome";

  # Common networking configuration
  modules.networking = {
    enable = true;
    hostName = lib.mkDefault "nixos"; # Can be overridden per host
    optimizeTCP = true;
    enableNetworkManager = true;
    dns = {
      enableSystemdResolved = true;
      enableDNSOverTLS = true;
      primaryProvider = "cloudflare";
    };
    firewall = {
      enable = true;
      allowPing = true;
      openPorts = [22]; # SSH by default, can be extended per host
      trustedInterfaces = [];
    };
  };

  # Common home configuration
  modules.home = {
    enable = true;
    username = "notroot";
    hostName = lib.mkDefault "default"; # Can be overridden per host
    # extraPackages will be defined per host
  };

  # Common locale settings
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "pt_BR.UTF-8";
    LC_IDENTIFICATION = "pt_BR.UTF-8";
    LC_MEASUREMENT = "pt_BR.UTF-8";
    LC_MONETARY = "pt_BR.UTF-8";
    LC_NAME = "pt_BR.UTF-8";
    LC_NUMERIC = "pt_BR.UTF-8";
    LC_PAPER = "pt_BR.UTF-8";
    LC_TELEPHONE = "pt_BR.UTF-8";
    LC_TIME = "pt_BR.UTF-8";
  };

  # Common user configuration
  users = {
    defaultUserShell = pkgs.zsh;
    users.notroot = {
      isNormalUser = true;
      description = "Pedro Balbino";
      extraGroups = [
        "networkmanager"
        "wheel"
        "audio"
        "video"
        "disk"
        "input"
        "bluetooth"
        "docker"
        "render"
        "kvm"
        "pipewire"
      ];
    };
  };

  # Common hardware configuration
  hardware = {
    enableRedistributableFirmware = true;
    bluetooth = {
      enable = true;
      powerOnBoot = true;
      disabledPlugins = ["sap"];
      settings = {
        General = {
          AutoEnable = "true";
          ControllerMode = "dual";
          Experimental = "true";
        };
      };
    };
    graphics = {
      enable = true;
      enable32Bit = true;
    };
  };

  # Common services
  services = {
    pipewire.enable = true;
    pulseaudio.enable = lib.mkForce false;

    syncthing = {
      enable = true;
      user = "notroot";
      dataDir = "/home/notroot/Sync";
      configDir = "/home/notroot/.config/syncthing";
      overrideDevices = true;
      overrideFolders = true;
    };

    openssh = {
      enable = true;
      settings = {
        PermitRootLogin = "no";
        PasswordAuthentication = true;
        KbdInteractiveAuthentication = false;
      };
    };

    fstrim.enable = true;
    thermald.enable = true;
  };

  # Common programs
  programs = {
    fish.enable = true;
    zsh.enable = true;
    nix-ld.enable = true;
    dconf.enable = true;
    thunderbird.enable = true;
  };

  # Common security configuration
  security = {
    sudo.wheelNeedsPassword = true;
    polkit.enable = true;
    rtkit.enable = true;
  };

  # Common console settings
  console.keyMap = "br-abnt2";
}
