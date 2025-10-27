# GNOME Desktop Environment - Main Module
# Imports base and extensions sub-modules
# Host-specific configurations should be in hosts/<hostname>/gnome.nix
{
  config,
  lib,
  pkgs,
  ...
}: {
  imports = [
    ./base.nix
    ./extensions.nix
  ];

  options.modules.desktop.gnome = {
    enable = lib.mkEnableOption "GNOME desktop environment";

    # Wayland configuration
    wayland = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable Wayland session (NixOS 25.11+ default)";
      };
    };

    # Theme configuration
    theme = {
      iconTheme = lib.mkOption {
        type = lib.types.str;
        default = "Papirus-Dark";
        description = "Icon theme name";
      };

      cursorTheme = lib.mkOption {
        type = lib.types.str;
        default = "Bibata-Modern-Ice";
        description = "Cursor theme name";
      };
    };
  };

  config = lib.mkIf config.modules.desktop.gnome.enable {
    # Enable base GNOME configuration
    modules.desktop.gnome.base.enable = lib.mkDefault true;

    # GDM Wayland/X11 configuration
    services.displayManager.gdm.wayland = config.modules.desktop.gnome.wayland.enable;

    # Force X11 session when Wayland is disabled
    services.displayManager.gdm.settings = lib.mkIf (!config.modules.desktop.gnome.wayland.enable) {
      daemon = {
        WaylandEnable = false;
        DefaultSession = "gnome-xorg.desktop";
      };
      security = {
        AllowGuestAccount = false;
        AllowUserList = true;
      };
    };

    # X11 support for non-Wayland configurations
    services.xserver.enable = lib.mkDefault (!config.modules.desktop.gnome.wayland.enable);

    # Common environment variables
    environment.sessionVariables = lib.mkMerge [
      # Common variables for both modes
      {
        XCURSOR_THEME = config.modules.desktop.gnome.theme.cursorTheme;
        XCURSOR_SIZE = "24";
        GTK_USE_PORTAL = "1"; # Portal support for file dialogs
      }

      # Wayland-specific variables
      (lib.mkIf config.modules.desktop.gnome.wayland.enable {
        # Electron Wayland support
        NIXOS_OZONE_WL = "1";
        XDG_SESSION_TYPE = "wayland";
        XDG_CURRENT_DESKTOP = "GNOME";

        # WebRTC PipeWire screen sharing support
        WEBRTC_PIPEWIRE_CAPTURER = "1";

        # Wayland display configuration
        GDK_BACKEND = "wayland,x11";
        QT_QPA_PLATFORM = "wayland;xcb";
        MOZ_ENABLE_WAYLAND = "1";

        # Basic GTK configuration
        "GTK_CSD" = "1"; # Enable client-side decorations

        # Wayland compositor settings
        "WLR_DRM_NO_ATOMIC" = "1"; # Compatibility for older compositors
        "CLUTTER_BACKEND" = "wayland"; # Force Wayland for GNOME Shell

        # Chrome/Electron specific fixes for tab bar rendering
        "CHROME_OZONE_PLATFORM_WAYLAND" = "1";
        "ELECTRON_ENABLE_WAYLAND" = "1";
      })

      # X11-specific variables
      (lib.mkIf (!config.modules.desktop.gnome.wayland.enable) {
        # Force GNOME to use X11
        GDK_BACKEND = "x11";
        # Disable Wayland for all applications
        MOZ_ENABLE_WAYLAND = "0";
        ELECTRON_OZONE_PLATFORM_HINT = "auto";
        # Set renderer for GTK apps (ngl fixes GNOME 47+ rendering issues)
        GSK_RENDERER = "ngl"; # Use new GL renderer for better compatibility
        # Explicitly disable Wayland
        QT_QPA_PLATFORM = "xcb";
        # Force X11 for session
        XDG_SESSION_TYPE = "x11";
      })
    ];

    # Portal service initialization
    environment.extraInit = ''
      # Ensure portal services start properly
      systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP GTK_USE_PORTAL XDG_SESSION_TYPE 2>/dev/null || true
      dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP GTK_USE_PORTAL XDG_SESSION_TYPE 2>/dev/null || true
    '';

    # Portal services configuration
    systemd.user.services.xdg-desktop-portal-gnome = {
      wantedBy = ["default.target"];
      after = lib.mkIf (!config.modules.desktop.gnome.wayland.enable) ["graphical-session.target"];
      environment = lib.mkMerge [
        {
          XDG_CURRENT_DESKTOP = "GNOME";
        }
        (lib.mkIf config.modules.desktop.gnome.wayland.enable {
          WAYLAND_DISPLAY = "wayland-0";
          XDG_SESSION_TYPE = "wayland";
        })
        (lib.mkIf (!config.modules.desktop.gnome.wayland.enable) {
          DISPLAY = ":0";
          XDG_SESSION_TYPE = "x11";
          XAUTHORITY = "%h/.Xauthority";
        })
      ];
    };

    systemd.user.services.xdg-desktop-portal-gtk = {
      wantedBy = ["default.target"];
      after = lib.mkIf (!config.modules.desktop.gnome.wayland.enable) ["graphical-session.target"];
      environment = lib.mkMerge [
        {
          XDG_CURRENT_DESKTOP = "GNOME";
        }
        (lib.mkIf config.modules.desktop.gnome.wayland.enable {
          WAYLAND_DISPLAY = "wayland-0";
          XDG_SESSION_TYPE = "wayland";
        })
        (lib.mkIf (!config.modules.desktop.gnome.wayland.enable) {
          DISPLAY = ":0";
          XDG_SESSION_TYPE = "x11";
          XAUTHORITY = "%h/.Xauthority";
        })
      ];
    };
  };
}
