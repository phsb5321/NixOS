# modules/desktop/coordinator.nix
# This file coordinates between different desktop environments to avoid conflicts
{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.modules.desktop;
in {
  config = mkIf cfg.enable {
    # X server and display manager configuration for NixOS 25.05
    services.xserver = {
      enable = true;

      # Video drivers - set by specific hosts if needed
      videoDrivers = mkDefault [];

      # Let desktop environments handle keyboard configuration automatically
      # (removed explicit keyboard layout configuration)

      # SDDM configuration for KDE is handled by the KDE module
    };

    # GDM configuration for GNOME (moved to new structure)
    services.displayManager.gdm = mkIf (cfg.environment == "gnome") {
      enable = true;
      wayland = cfg.displayManager.wayland;
      autoSuspend = cfg.displayManager.autoSuspend;
    };

    # Auto-login configuration - updated for NixOS 25.05
    services.displayManager.autoLogin = mkIf cfg.autoLogin.enable {
      enable = true;
      user = cfg.autoLogin.user;
    };

    # New display manager service configuration for NixOS 25.05
    services.displayManager = {
      defaultSession = mkDefault (
        if cfg.environment == "gnome"
        then
          (
            if cfg.displayManager.wayland
            then "gnome"
            else "gnome-xorg"
          )
        else if cfg.environment == "kde"
        then
          (
            if cfg.displayManager.wayland
            then "plasma"
            else "plasmax11"
          )
        else "gnome-xorg"
      );
    };

    # Display protocol specific environment variables for NixOS 25.05
    environment.sessionVariables = mkMerge [
      # Wayland-specific environment variables
      (mkIf cfg.displayManager.wayland {
        # Essential Wayland variables
        XDG_SESSION_TYPE = "wayland";
        WAYLAND_DISPLAY = "wayland-0";

        # Application compatibility
        QT_QPA_PLATFORM = "wayland;xcb";
        GDK_BACKEND = "wayland,x11";
        SDL_VIDEODRIVER = "wayland";
        CLUTTER_BACKEND = "wayland";
        MOZ_ENABLE_WAYLAND = "1";
        NIXOS_OZONE_WL = "1";

        # Force Wayland for specific applications
        QT_WAYLAND_FORCE_DPI = "physical";

        # GNOME specific variables
        GNOME_WAYLAND = mkIf (cfg.environment == "gnome") "1";

        # KDE specific variables
        QT_WAYLAND_DISABLE_WINDOWDECORATION = mkIf (cfg.environment == "kde") "1";
      })

      # X11-specific environment variables
      (mkIf (!cfg.displayManager.wayland) {
        # Essential X11 variables
        XDG_SESSION_TYPE = "x11";
        WAYLAND_DISPLAY = "";

        # Application compatibility
        QT_QPA_PLATFORM = "xcb";
        GDK_BACKEND = "x11";
        SDL_VIDEODRIVER = "x11";
        CLUTTER_BACKEND = "x11";
        MOZ_ENABLE_WAYLAND = "0";
        NIXOS_OZONE_WL = "0";

        # Disable Wayland for applications
        QT_WAYLAND_FORCE_DPI = "";

        # GNOME specific variables
        GNOME_WAYLAND = mkIf (cfg.environment == "gnome") "0";
      })
    ];

    # Accessibility support
    services.gnome.at-spi2-core.enable = mkIf cfg.accessibility.enable true;

    programs.dconf.enable = true;

    # Essential desktop packages
    environment.systemPackages = with pkgs;
      [
        # Wayland utilities
        wl-clipboard
        wayland-utils

        # XDG portal support
        xdg-utils
        xdg-desktop-portal

        # Common desktop utilities
        file-roller # Archive manager
        evince # PDF viewer

        # Accessibility packages
      ]
      ++ optionals cfg.accessibility.enable [
        espeak # Text-to-speech
        at-spi2-atk
        at-spi2-core
      ]
      ++ optionals cfg.accessibility.screenReader [
        orca
      ]
      ++ optionals cfg.accessibility.magnifier [
        # Magnus screen magnifier is available through GNOME
      ]
      ++ optionals cfg.accessibility.onScreenKeyboard [
        onboard
      ];

    # Hardware support
    hardware = {
      bluetooth.enable = mkIf cfg.hardware.enableBluetooth true;
    };

    services = {
      # Printing support
      printing = mkIf cfg.hardware.enablePrinting {
        enable = true;
        drivers = with pkgs; [
          hplip
          epson-escpr
        ];
      };

      # Bluetooth support
      blueman.enable = mkIf cfg.hardware.enableBluetooth true;
    };

    # XDG portals configuration - Only set defaults, let specific DEs override
    xdg.portal = {
      enable = true;
      # Don't set extraPortals here to avoid conflicts - let specific DE modules handle it
      config = {
        common = {
          default = mkDefault ["gtk"];
        };
        # GNOME and KDE modules will override these settings
      };
    };

    # Safety measures to ensure desktop environments don't conflict
    assertions = [
      {
        assertion =
          (cfg.environment == "gnome" -> !config.services.desktopManager.plasma6.enable)
          && (cfg.environment == "kde" -> !config.services.desktopManager.gnome.enable);
        message = "You cannot enable multiple desktop environments simultaneously.";
      }
      {
        assertion = cfg.autoLogin.enable -> cfg.autoLogin.user != "";
        message = "Auto-login user must be specified when auto-login is enabled.";
      }
    ];
  };
}
