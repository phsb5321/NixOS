# ~/NixOS/hosts/modules/desktop/kde/default.nix
{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.modules.desktop;
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
    # Configure Display Manager directly, removing references to services.xserver.displayManager
    services.displayManager = {
      defaultSession = "plasma";
      autoLogin = mkIf cfg.autoLogin.enable {
        enable = true;
        user = cfg.autoLogin.user;
      };
      sddm = {
        enable = true;
        wayland = mkIf (cfg.kde.version == "plasma6") {
          enable = true;
        };
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

    # Correctly configure desktopManager under services.xserver.desktopManager
    services.xserver.desktopManager = mkMerge [
      (mkIf (cfg.kde.version == "plasma5") {
        plasma5.enable = true;
      })
      (mkIf (cfg.kde.version == "plasma6") {
        plasma6.enable = true;
      })
    ];

    # Session variables for Plasma
    environment.sessionVariables = mkMerge [
      (mkIf (cfg.kde.version == "plasma5") {
        XDG_SESSION_TYPE = "x11";
        XDG_CURRENT_DESKTOP = "KDE";
        XDG_SESSION_DESKTOP = "KDE";
        KDE_FULL_SESSION = "true";
      })
      (mkIf (cfg.kde.version == "plasma6") {
        XDG_SESSION_TYPE = "wayland";
        XDG_CURRENT_DESKTOP = "KDE";
        XDG_SESSION_DESKTOP = "plasma";
      })
    ];

    # Core environment packages
    environment.systemPackages = let
      # Common packages for both Plasma 5 and 6
      commonPackages = with pkgs; [
        # Power management
        power-profiles-daemon
        acpi
        acpid
        powertop

        # Core applications
        dolphin
        konsole
        kate
        ark
        spectacle
        okular
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
        kinfocenter
        plasma5.ksystemstats
        kgamma5
        plasma5.sddm-kcm
        plasma5.polkit-kde-agent-1

        # Plasma addons and integration
        plasma5.plasma-browser-integration
        plasma5.kdeplasma-addons
        plasma5.kscreen
        plasma5.plasma-nm
        plasma5.plasma-vault
        plasma5.plasma-pa
        plasma5.kdeconnect-kde

        # Theming
        plasma5Packages.breeze-gtk
        plasma5Packages.breeze-icons
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
    in
      commonPackages
      ++ (
        if cfg.kde.version == "plasma5"
        then plasma5Packages
        else plasma6Packages
      );

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

      pipewire = {
        enable = true;
        alsa.enable = true;
        pulse.enable = true;
        jack.enable = true;
        wireplumber.enable = true;
      };
    };

    # Security and system features
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

    # Enable required features
    hardware.bluetooth = {
      enable = true;
      powerOnBoot = true;
    };

    # Ensure dconf is enabled
    programs.dconf.enable = true;
  };
}
