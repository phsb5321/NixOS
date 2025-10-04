# Remote Desktop Configuration Module
# Comprehensive support for VNC and RDP protocols (client and server)
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.networking.remoteDesktop;
in {
  options.modules.networking.remoteDesktop = with lib; {
    enable = mkEnableOption "Remote desktop support (VNC/RDP client and server)";

    client = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable remote desktop client tools";
      };

      tools = mkOption {
        type = types.listOf types.package;
        default = with pkgs; [
          remmina         # Multi-protocol remote desktop client
          freerdp3        # Latest FreeRDP for best compatibility
          tigervnc        # VNC client
          gnome-connections # GNOME's native remote desktop client
        ];
        description = "Remote desktop client packages to install";
      };
    };

    server = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable remote desktop server functionality";
      };

      vnc = {
        enable = mkOption {
          type = types.bool;
          default = false;
          description = "Enable VNC server";
        };

        port = mkOption {
          type = types.int;
          default = 5900;
          description = "VNC server port";
        };
      };

      rdp = {
        enable = mkOption {
          type = types.bool;
          default = false;
          description = "Enable RDP server (xrdp)";
        };

        port = mkOption {
          type = types.int;
          default = 3389;
          description = "RDP server port";
        };
      };

      gnomeRemoteDesktop = mkOption {
        type = types.bool;
        default = true;
        description = "Enable GNOME Remote Desktop (modern RDP/VNC)";
      };
    };

    firewall = {
      openPorts = mkOption {
        type = types.bool;
        default = false;
        description = "Open firewall ports for remote desktop servers";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    # Combined client and server packages
    environment.systemPackages =
      lib.optionals cfg.client.enable cfg.client.tools
      ++ lib.optionals cfg.server.enable (with pkgs; [
        # Server management tools
        tigervnc  # Also includes vncserver
      ] ++ lib.optionals cfg.server.rdp.enable [
        xrdp
      ]);

    # GNOME Remote Desktop (modern approach for Wayland)
    services.gnome.gnome-remote-desktop.enable =
      lib.mkIf (cfg.server.enable && cfg.server.gnomeRemoteDesktop) true;

    # Traditional VNC server using TigerVNC
    services.xserver = lib.mkIf (cfg.server.enable && cfg.server.vnc.enable) {
      enable = true;
      # VNC server configuration would go here if using x11vnc or tigervnc server
    };

    # RDP server using xrdp
    services.xrdp = lib.mkIf (cfg.server.enable && cfg.server.rdp.enable) {
      enable = true;
      port = cfg.server.rdp.port;
      openFirewall = cfg.firewall.openPorts;
      defaultWindowManager =
        if config.services.displayManager.gdm.wayland
        then "gnome-session"
        else "startplasma-x11";
    };

    # Firewall configuration
    networking.firewall = lib.mkIf cfg.firewall.openPorts {
      allowedTCPPorts =
        lib.optionals cfg.server.vnc.enable [ cfg.server.vnc.port ]
        ++ lib.optionals cfg.server.rdp.enable [ cfg.server.rdp.port ];
    };

    # Enable required system services for remote desktop
    services.dbus.enable = lib.mkIf cfg.server.enable true;

    # Ensure PipeWire is available for screen sharing
    services.pipewire = lib.mkIf cfg.server.enable {
      enable = lib.mkDefault true;
      alsa.enable = lib.mkDefault true;
      pulse.enable = lib.mkDefault true;
    };

    # Portal configuration for screen sharing
    xdg.portal = lib.mkIf cfg.server.enable {
      enable = true;
      extraPortals = with pkgs; [
        xdg-desktop-portal-gnome
        xdg-desktop-portal-gtk
      ];
    };


    # Session variables for better remote desktop experience
    environment.sessionVariables = lib.mkIf cfg.server.enable {
      # Enable screen sharing via PipeWire
      WEBRTC_PIPEWIRE_CAPTURER = "1";
    };
  };
}