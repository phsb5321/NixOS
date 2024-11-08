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
    # Allow broken packages for KDE Plasma 6
    nixpkgs.config.allowBroken = true;

    # Ensure NetworkManager is not disabled here
    networking.networkmanager.enable = true;

    # Basic X server and KDE configuration
    services = {
      xserver.enable = true;
      # Display manager settings
      displayManager = {
        sddm = {
          enable = true;
          wayland.enable = true;
          settings = {
            Theme = {
              CursorTheme = "breeze_cursors";
              Font = "Noto Sans";
            };
            General = {
              InputMethod = "";
              Numlock = "on";
            };
            Wayland = {
              CompositorCommand = "kwin_wayland --drm --no-lockscreen";
            };
          };
        };
        defaultSession = "plasma"; # Use Plasma session by default
        autoLogin = mkIf cfg.autoLogin.enable {
          enable = true;
          user = cfg.autoLogin.user;
        };
      };
      # Desktop manager settings
      desktopManager.plasma6.enable = true;
    };

    # Session variables for Wayland/KDE
    environment.sessionVariables = {
      NIXOS_OZONE_WL = "1";
      WLR_NO_HARDWARE_CURSORS = "1";
      XDG_SESSION_TYPE = "wayland";
      XDG_CURRENT_DESKTOP = "KDE";
      XDG_SESSION_DESKTOP = "KDE";
      GDK_BACKEND = "wayland,x11";
      QT_QPA_PLATFORM = "wayland;xcb";
      QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
      SDL_VIDEODRIVER = "wayland";
      CLUTTER_BACKEND = "wayland";
      MOZ_ENABLE_WAYLAND = "1";
    };

    # Core environment packages
    environment.systemPackages = with pkgs; [
      # Wayland support
      wayland
      xwayland
      qt6.qtwayland
      kdePackages.kwayland

      # Screen sharing support
      pipewire
      libsForQt5.qt5.qtwebengine
      xdg-desktop-portal
      xdg-desktop-portal-kde
      xdg-desktop-portal-gtk

      # Core KDE packages
      kdePackages.plasma-workspace
      kdePackages.plasma-activities
      kdePackages.plasma-activities-stats
      kdePackages.plasma5support

      # Power management
      kdePackages.powerdevil
      power-profiles-daemon
      acpi
      acpid
      powertop

      # Online accounts and integration
      kdePackages.kaccounts-integration
      kdePackages.kaccounts-providers
      kdePackages.signon-kwallet-extension
      gnome-keyring
      kdePackages.kio
      kdePackages.kio-extras
      kdePackages.kio-gdrive
      kdePackages.kwallet-pam

      # System settings and info
      kdePackages.plasma-systemmonitor
      kdePackages.kinfocenter
      kdePackages.ksystemstats
      kdePackages.kgamma
      kdePackages.sddm-kcm
      kdePackages.kauth
      kdePackages.polkit-kde-agent-1

      # Core applications
      kdePackages.dolphin
      kdePackages.konsole
      kdePackages.kate
      kdePackages.ark
      kdePackages.spectacle
      kdePackages.okular

      # Plasma addons and integration
      kdePackages.plasma-browser-integration
      kdePackages.kdeplasma-addons
      kdePackages.kscreen
      kdePackages.plasma-nm
      kdePackages.plasma-vault
      kdePackages.plasma-pa
      kdePackages.kdeconnect-kde

      # Theming
      kdePackages.breeze
      kdePackages.breeze-gtk
      kdePackages.breeze-icons

      # Additional utilities
      xdg-utils
    ];

    # XDG portal configuration for screen sharing
    xdg.portal = {
      enable = true;
      extraPortals = [
        pkgs.xdg-desktop-portal-kde
        pkgs.xdg-desktop-portal-gtk
      ];
      config = {
        common = {
          default = [
            "kde"
            "gtk"
          ];
          "org.freedesktop.impl.portal.Secret" = ["gnome-keyring"];
          "org.freedesktop.impl.portal.ScreenCast" = ["kde"];
        };
      };
      xdgOpenUsePortal = true;
    };

    # PipeWire configuration
    services.pipewire = {
      enable = true;
      alsa = {
        enable = true;
        support32Bit = true;
      };
      pulse.enable = true;
      jack.enable = true;
      wireplumber.enable = true;
    };

    # Required services
    services = {
      power-profiles-daemon = {
        enable = true;
      };
      acpid.enable = true;
      udisks2.enable = true;
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
    services.gnome = {
      gnome-keyring.enable = true;
    };

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

    # Flatpak support
    services.flatpak.enable = true;

    # Fonts
    fonts.packages = with pkgs; [
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-emoji
      liberation_ttf
      fira-code
      fira-code-symbols
      (nerdfonts.override {fonts = ["JetBrainsMono"];})
    ];

    # Increase download buffer size
    nix.settings.download-buffer-size = 128 * 1024 * 1024; # Set to 128 MiB

    # Enable required features
    hardware.bluetooth = {
      enable = true;
      powerOnBoot = true;
    };

    # Ensure dconf is enabled
    programs.dconf.enable = true;
  };
}
