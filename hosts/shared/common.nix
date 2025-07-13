# ~/NixOS/hosts/shared/common.nix
# This configuration is now primarily for desktop hosts
# The laptop has its own integrated configuration
{
  pkgs,
  lib,
  inputs,
  systemVersion,
  ...
}: {
  # Common configuration shared between desktop hosts (not laptop)

  # Override gnome-session to fix Wayland wrapper bug
  nixpkgs.overlays = [
    (final: prev: {
      gnome-session = prev.gnome-session.overrideAttrs (oldAttrs: {
        postInstall =
          (oldAttrs.postInstall or "")
          + ''
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
    terminal.enable = true; # Enable terminal tools (migrated from home-manager)
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

    # Use X11 for now to troubleshoot graphics issues
    displayManager = {
      wayland = false;
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
  };

  # Use the GNOME X11 session since Wayland is disabled
  services.displayManager.defaultSession = lib.mkForce "gnome-xorg";

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

  # Console keymap configuration
  console = {
    font = "Lat2-Terminus16";
    useXkbConfig = true; # Use X keyboard configuration in console
  };

  # X11/Wayland keyboard configuration
  services.xserver.xkb = {
    layout = "us,br";
    variant = ",abnt2";
    options = "grp:alt_shift_toggle,compose:ralt"; # Alt+Shift to switch, Right Alt as compose key
  };

  # Input method configuration
  i18n.inputMethod = {
    enable = true;
    type = "ibus";
  };

  # GNOME-specific keyboard integration fixes
  services.gnome.gnome-settings-daemon.enable = lib.mkForce true;

  # 🚨 CRITICAL: Configure dconf/gsettings for GNOME keyboard integration
  services.xserver.desktopManager.gnome.extraGSettingsOverrides = ''
    # Input Sources Configuration
    [org.gnome.desktop.input-sources]
    sources=[('xkb', 'us'), ('xkb', 'br+abnt2')]
    xkb-options=['grp:alt_shift_toggle', 'compose:ralt']

    # Ensure consistent keyboard settings
    [org.gnome.desktop.peripherals.keyboard]
    numlock-state=true
    remember-numlock-state=true

    # Interface consistency
    [org.gnome.desktop.interface]
    show-battery-percentage=true
  '';

  services.xserver.desktopManager.gnome.extraGSettingsOverridePackages = [
    pkgs.gsettings-desktop-schemas
    pkgs.gnome-settings-daemon
  ];

  # Enhanced locale settings with keyboard integration
  i18n = {
    defaultLocale = "en_US.UTF-8";
    extraLocaleSettings = {
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
  };

  # Enhanced boot configuration to fix early keyboard issues
  boot.kernelParams = [
    "consoleblank=0"  # Prevent console blanking
    "rd.systemd.show_status=true"  # Show systemd status during boot
  ];

  # System-level environment variables (migrated from home-manager)
  environment.variables = {
    EDITOR = "nvim";
    SHELL = "${pkgs.zsh}/bin/zsh";
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

  # Keyboard configuration is now handled by the core module
}
