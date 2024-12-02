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
  config = mkIf (cfg.enable && cfg.environment == "kde") {
    # Enable X server
    services.xserver.enable = true;

    # Display Manager configuration
    services.displayManager = {
      enable = true;
      defaultSession = "plasma";
      autoLogin = mkIf cfg.autoLogin.enable {
        enable = true;
        user = cfg.autoLogin.user;
      };
      sddm = {
        enable = true;
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

    # Desktop Manager configuration
    services.xserver.desktopManager.plasma5.enable = true;

    # Session variables for Plasma
    environment.sessionVariables = {
      XDG_SESSION_TYPE = "x11";
      XDG_CURRENT_DESKTOP = "KDE";
      XDG_SESSION_DESKTOP = "KDE";
      KDE_FULL_SESSION = "true";
    };

    # Core environment packages
    environment.systemPackages = with pkgs; let
      plasma5 = pkgs.plasma5Packages;
      xorg = pkgs.xorg;
    in [
      # X11 support
      xorg.xorgserver
      xorg.xrandr

      # Core KDE packages
      plasma5.plasma-workspace
      plasma5.plasma-desktop
      plasma5.plasma-framework
      plasma5.kactivities
      plasma5.kactivities-stats

      kdePackages.kio-gdrive

      # Power management
      plasma5.powerdevil
      pkgs.power-profiles-daemon
      pkgs.acpi
      pkgs.acpid
      pkgs.powertop

      # Online accounts and integration
      pkgs.gnome-keyring

      # System settings and info
      plasma5.plasma-systemmonitor
      pkgs.kinfocenter
      plasma5.ksystemstats
      pkgs.kgamma5
      plasma5.sddm-kcm
      plasma5.polkit-kde-agent

      # Core applications
      pkgs.dolphin
      pkgs.konsole
      pkgs.kate
      pkgs.ark
      pkgs.spectacle
      pkgs.okular
      pkgs.ffmpegthumbnailer

      # Plasma addons and integration
      plasma5.plasma-browser-integration
      plasma5.kdeplasma-addons
      plasma5.kscreen
      plasma5.plasma-nm
      plasma5.plasma-vault
      plasma5.plasma-pa
      plasma5.kdeconnect-kde

      # Theming
      pkgs.plasma5Packages.breeze-gtk
      pkgs.plasma5Packages.breeze-icons

      # Additional utilities
      pkgs.xdg-utils
      pkgs.shared-mime-info
    ];

    # Adjust other services accordingly
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      pulse.enable = true;
      jack.enable = true;
      wireplumber.enable = true;
    };

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

    # Note: User-specific configurations should be placed in the user's Home Manager configuration.
  };
}
