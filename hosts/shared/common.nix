# ~/NixOS/hosts/shared/common.nix
{
  pkgs,
  lib,
  inputs,
  systemVersion,
  ...
}: {
  # Common configuration shared between all hosts

  # Override gnome-session to fix Wayland wrapper bug - Updated for NixOS 25.05
  nixpkgs.overlays = [
    (final: prev: {
      # Fix gnome-session wrapper "-l" flag error
      gnome-session = prev.gnome-session.overrideAttrs (oldAttrs: {
        postInstall =
          (oldAttrs.postInstall or "")
          + ''
            # Remove problematic -l flag from session wrapper
            if [ -f $out/bin/gnome-session ]; then
              sed -i 's/exec "$0" -l "$@"/exec "$0" "$@"/' $out/bin/gnome-session
            fi

            # Ensure gnome-session has proper executable permissions
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

    # Enable version synchronization
    versionSync = {
      enable = true;
      systemChannel = "stable"; # Use stable NixOS 25.05 for system
      packageChannel = "bleeding"; # Use bleeding edge for packages
      forceSystemStable = true; # Force system components to stable
    };

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

    # Enhanced Wayland configuration for NixOS 25.05
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

  # Use explicit GNOME Wayland session
  services.displayManager.defaultSession = lib.mkForce "gnome";

  # Essential Wayland environment variables for NixOS 25.05
  environment.sessionVariables = {
    # Chromium/Electron Wayland support
    NIXOS_OZONE_WL = "1";

    # GTK applications prefer Wayland with X11 fallback
    GDK_BACKEND = "wayland,x11";

    # Qt applications Wayland support
    QT_QPA_PLATFORM = "wayland;xcb";

    # Mozilla applications Wayland support
    MOZ_ENABLE_WAYLAND = "1";

    # SDL applications Wayland support
    SDL_VIDEODRIVER = "wayland";

    # Additional Wayland variables
    XDG_SESSION_TYPE = "wayland";
    CLUTTER_BACKEND = "wayland";
  };

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

  # Enhanced XDG portal configuration for Wayland screen sharing
  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-gnome
      xdg-desktop-portal-gtk
    ];
    config = {
      common = {
        default = ["gtk"];
      };
      gnome = {
        default = ["gnome" "gtk"];
        "org.freedesktop.impl.portal.Secret" = ["gnome-keyring"];
        "org.freedesktop.impl.portal.ScreenCast" = ["gnome"];
        "org.freedesktop.impl.portal.RemoteDesktop" = ["gnome"];
      };
    };
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
