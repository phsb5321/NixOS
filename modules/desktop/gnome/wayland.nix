# ~/NixOS/modules/desktop/gnome/wayland.nix
# GNOME Wayland and X11 configuration
{ config, lib, pkgs, ... }:

let
  cfg = config.modules.desktop.gnome;
in {
  options.modules.desktop.gnome.wayland = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable Wayland session (NixOS 25.11+ default, disable for X11/NVIDIA)";
    };

    electronSupport = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable Electron/Chromium Wayland support";
    };

    screenSharing = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable WebRTC PipeWire screen sharing";
    };

    variant = lib.mkOption {
      type = lib.types.enum ["hardware" "conservative" "software"];
      default = "hardware";
      description = ''
        Hardware acceleration variant:
        - hardware: Normal operation with full hardware acceleration
        - conservative: Conservative fallback for GPU issues with tear-free
        - software: Emergency software rendering fallback
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    # GDM Wayland configuration
    services.displayManager.gdm.wayland = cfg.wayland.enable;

    # X11 fallback settings
    services.displayManager.gdm.settings = lib.mkIf (!cfg.wayland.enable) {
      daemon = {
        WaylandEnable = false;
        DefaultSession = "gnome-xorg.desktop";
      };
      security = {
        AllowGuestAccount = false;
        AllowUserList = true;
      };
    };

    # X11 support for non-Wayland
    services.xserver.enable = !cfg.wayland.enable;

    # Wayland environment variables
    environment.sessionVariables = lib.mkMerge [
      # Wayland-specific
      (lib.mkIf cfg.wayland.enable {
        XDG_SESSION_TYPE = "wayland";
        XDG_CURRENT_DESKTOP = "GNOME";
        GDK_BACKEND = "wayland,x11";
        QT_QPA_PLATFORM = "wayland;xcb";
        MOZ_ENABLE_WAYLAND = "1";
        GTK_CSD = "1";
        CLUTTER_BACKEND = "wayland";
        WLR_DRM_NO_ATOMIC = "1";
      })

      # Electron Wayland support
      (lib.mkIf (cfg.wayland.enable && cfg.wayland.electronSupport) {
        NIXOS_OZONE_WL = "1";
        CHROME_OZONE_PLATFORM_WAYLAND = "1";
        ELECTRON_ENABLE_WAYLAND = "1";
      })

      # WebRTC screen sharing
      (lib.mkIf (cfg.wayland.enable && cfg.wayland.screenSharing) {
        WEBRTC_PIPEWIRE_CAPTURER = "1";
      })

      # X11-specific (for NVIDIA compatibility)
      (lib.mkIf (!cfg.wayland.enable) {
        GDK_BACKEND = "x11";
        MOZ_ENABLE_WAYLAND = "0";
        ELECTRON_OZONE_PLATFORM_HINT = "auto";
        GSK_RENDERER = "gl";
        QT_QPA_PLATFORM = "xcb";
        XDG_SESSION_TYPE = "x11";
      })
    ];

    # Mutter settings based on variant
    programs.dconf.profiles.user.databases = lib.mkIf cfg.settings.enable [
      {
        lockAll = false;
        settings = {
          "org/gnome/mutter" = lib.mkMerge [
            # Hardware variant (default)
            (lib.mkIf (cfg.wayland.variant == "hardware") {
              experimental-features = [
                "scale-monitor-framebuffer"
                "variable-refresh-rate"
              ];
            })

            # Conservative variant
            (lib.mkIf (cfg.wayland.variant == "conservative") {
              experimental-features = [];
            })

            # Software variant
            (lib.mkIf (cfg.wayland.variant == "software") {
              experimental-features = [];
            })
          ];
        };
      }
    ];
  };
}
