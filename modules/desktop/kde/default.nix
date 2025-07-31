# ~/NixOS/hosts/modules/desktop/kde/default.nix
{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.modules.desktop;
  # Common packages for both Plasma 5 and 6
  commonPackages = with pkgs; [
    # Power management
    power-profiles-daemon
    acpi
    acpid
    powertop

    # Core applications - all KDE applications updated to use proper namespaces
    kdePackages.dolphin
    kdePackages.konsole
    kdePackages.kate
    kdePackages.ark
    kdePackages.spectacle
    kdePackages.okular
    ffmpegthumbnailer
    kdePackages.kio-gdrive

    # Additional utilities
    xdg-utils
    shared-mime-info
  ];

  # Plasma 5 specific packages
  plasma5Packages = with pkgs; let
    plasma5 = pkgs.plasma5Packages;
  in [
    # Core KDE packages
    plasma5.plasma-workspace
    plasma5.plasma-desktop
    plasma5.plasma-framework
    plasma5.kactivities
    plasma5.kactivities-stats

    # System settings and info
    plasma5.plasma-systemmonitor
    kdePackages.kinfocenter
    plasma5.ksystemstats
    plasma5.kgamma5
    plasma5.sddm-kcm
    plasma5.polkit-kde-agent

    # Plasma addons and integration
    plasma5.plasma-browser-integration
    plasma5.kdeplasma-addons
    plasma5.kscreen
    plasma5.plasma-nm
    plasma5.plasma-vault
    plasma5.plasma-pa
    plasma5.kdeconnect-kde

    # Theming
    plasma5.breeze-gtk
    plasma5.breeze-icons
  ];

  # Plasma 6 specific packages
  plasma6Packages = with pkgs; [
    kdePackages.plasma-workspace
    kdePackages.plasma-desktop
    kdePackages.plasma-nm
    kdePackages.plasma-pa
    kdePackages.powerdevil
    kdePackages.plasma-browser-integration
    kdePackages.plasma-systemmonitor
    kdePackages.kscreen
    kdePackages.sddm-kcm
    kdePackages.polkit-kde-agent-1
    kdePackages.kinfocenter
    kdePackages.plasma-activities
  ];

  # Select the right set of packages based on the KDE version
  selectedPackages =
    if cfg.kde.version == "plasma5"
    then plasma5Packages
    else plasma6Packages;
in {
  options.modules.desktop = {
    kde = {
      version = mkOption {
        type = types.enum ["plasma5" "plasma6"];
        default = "plasma6";
        description = ''
          The KDE Plasma version to use.
          plasma5 - KDE Plasma 5.x series
          plasma6 - KDE Plasma 6.x series
        '';
      };
    };
  };

  config = mkIf (cfg.enable && cfg.environment == "kde") {
    # Configure Display Manager
    services.displayManager = {
      defaultSession =
        if cfg.displayManager.wayland
        then "plasma"
        else "plasmax11";
      autoLogin = mkIf cfg.autoLogin.enable {
        enable = true;
        user = cfg.autoLogin.user;
      };
      sddm = {
        enable = true;
        wayland.enable = cfg.displayManager.wayland;
        settings = {
          Theme = {
            CursorTheme = "breeze_cursors";
            Font = "Noto Sans";
          };
          General = {
            InputMethod = "";
            Numlock = "on";
          };
        };
      };
    };

    # Enable services.xserver for Plasma 5
    services.xserver.enable = mkIf (cfg.kde.version == "plasma5") true;

    # Configure Plasma 5 under services.xserver.desktopManager
    services.xserver.desktopManager = mkIf (cfg.kde.version == "plasma5") {
      plasma5.enable = true;
    };

    # Configure Plasma 6 under services.desktopManager
    services.desktopManager = mkIf (cfg.kde.version == "plasma6") {
      plasma6.enable = true;
    };

    # Session variables for Plasma - force X11 for troubleshooting
    environment.sessionVariables = mkMerge [
      (mkIf (!cfg.displayManager.wayland) {
        XDG_SESSION_TYPE = "x11";
        XDG_CURRENT_DESKTOP = "KDE";
        XDG_SESSION_DESKTOP =
          if cfg.kde.version == "plasma5"
          then "KDE"
          else "plasma";
        KDE_FULL_SESSION = "true";
      })
      (mkIf (cfg.displayManager.wayland && cfg.kde.version == "plasma6") {
        XDG_SESSION_TYPE = "wayland";
        XDG_CURRENT_DESKTOP = "KDE";
        XDG_SESSION_DESKTOP = "plasma";
      })
    ];

    # Core environment packages
    environment.systemPackages = commonPackages ++ selectedPackages;

    # Required services
    services = {
      power-profiles-daemon.enable = true;
      acpid.enable = true;
      udisks2.enable = true;
      gvfs.enable = true;
      accounts-daemon.enable = true;
      upower = {
        enable = true;
        percentageLow = 15;
        percentageCritical = 5;
        percentageAction = 3;
      };
    };

    # Enable PipeWire for audio
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      jack.enable = true;
      wireplumber.enable = true;
    };

    # Ensure PulseAudio is disabled
    services.pulseaudio.enable = false;

    security = {
      polkit.enable = true;
      rtkit.enable = true;
      pam = {
        services = {
          sddm.enableGnomeKeyring = true;
          login.enableGnomeKeyring = true;
        };
      };
    };

    # Enable GNOME Keyring service
    services.gnome.gnome-keyring.enable = true;

    # KDE Connect firewall rules
    networking.firewall = {
      allowedTCPPortRanges = [
        {
          from = 1714;
          to = 1764;
        }
      ];
      allowedUDPPortRanges = [
        {
          from = 1714;
          to = 1764;
        }
      ];
    };

    # System-wide KDE configuration
    qt = {
      enable = true;
      platformTheme = "kde";
      style = "breeze";
    };

    # Better Bluetooth integration
    hardware.bluetooth = {
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

    # Ensure dconf is enabled
    programs.dconf.enable = true;
  };
}
