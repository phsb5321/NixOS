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
    # Ensure NetworkManager is not disabled here
    networking.networkmanager.enable = true; # <-- Add this line if missing

    # Existing KDE configuration
    services.xserver = {
      enable = true;
      displayManager = {
        sddm = {
          enable = true;
          wayland.enable = true; # Enable Wayland in SDDM
        };
        defaultSession = "plasma"; # Use Plasma session by default
        autoLogin = mkIf cfg.autoLogin.enable {
          enable = true;
          user = cfg.autoLogin.user;
        };
      };
      desktopManager.plasma6.enable = true;
    };

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

    environment.systemPackages = with pkgs; [
      # Core KDE packages
      libsForQt5.plasma-workspace
      libsForQt5.kdeconnect-kde
      libsForQt5.kaccounts-integration

      # Wayland support
      qt6.qtwayland
      wayland
      xwayland

      # Desktop portals
      xdg-desktop-portal-kde
      xdg-utils

      # Basic applications
      libsForQt5.dolphin
      libsForQt5.konsole
      firefox

      # KDE utilities
      libsForQt5.ark
      libsForQt5.kate
      libsForQt5.spectacle
      libsForQt5.okular

      # System tray utilities
      libsForQt5.plasma-systemmonitor
      libsForQt5.plasma-nm
      libsForQt5.plasma-vault
    ];

    # XDG portal configuration
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
        };
      };
    };

    # Audio configuration
    services.pipewire = {
      enable = true;
      alsa = {
        enable = true;
        support32Bit = true;
      };
      pulse.enable = true;
      jack.enable = true;
    };

    hardware.bluetooth = {
      enable = true;
      powerOnBoot = true;
    };

    # Required services and other configurations
    services.power-profiles-daemon.enable = true;
    services.udisks2.enable = true;
    services.accounts-daemon.enable = true;
    services.upower.enable = true;

    # KDE Connect and Firewall configuration
    networking.firewall = {
      allowedTCPPortRanges = [
        {
          from = 1714;
          to = 1764;
        } # KDE Connect
      ];
      allowedUDPPortRanges = [
        {
          from = 1714;
          to = 1764;
        } # KDE Connect
      ];
    };

    # Home Manager configuration for KDE
    home-manager.users.${cfg.autoLogin.user} = {pkgs, ...}: {
      home.packages = with pkgs; [
        # Additional KDE apps
        libsForQt5.filelight
        libsForQt5.kcalc
        libsForQt5.krita
        libsForQt5.gwenview
      ];

      # KDE Connect configuration
      services.kdeconnect = {
        enable = true;
        indicator = true;
      };

      # Notification service
      services.dunst = {
        enable = true;
        settings = {
          global = {
            font = "JetBrainsMono Nerd Font 11";
            frame_width = 2;
            frame_color = "#89b4fa";
          };
        };
      };

      # Plasma specific configuration
      programs.plasma = {
        enable = true;
        workspace = {
          clickItemTo = "select";
          theme = "breeze-dark";
          wallpaper = "Next";
        };
      };
    };

    # System-wide KDE configuration
    qt = {
      enable = true;
      platformTheme = "kde";
      style = "breeze";
    };

    # Enable required features
    security.rtkit.enable = true;
    security.polkit.enable = true;

    # Enable Flatpak support
    services.flatpak.enable = true;

    fonts.packages = with pkgs; [
      noto-fonts
      noto-fonts-cjk
      noto-fonts-emoji
      liberation_ttf
      fira-code
      fira-code-symbols
      (nerdfonts.override {fonts = ["JetBrainsMono"];})
    ];
  };
}
