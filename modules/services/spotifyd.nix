# ~/NixOS/modules/services/spotifyd.nix
# spotifyd - Spotify Connect daemon service
#
# This module configures spotifyd as a systemd user service.
# After enabling, users must create their own config file with credentials:
#   mkdir -p ~/.config/spotifyd
#   touch ~/.config/spotifyd/spotifyd.conf
#   chmod 600 ~/.config/spotifyd/spotifyd.conf
#
# Example spotifyd.conf:
#   [global]
#   username = "your_spotify_username"
#   password = "your_spotify_password"
#   backend = "pulseaudio"
#   device_name = "NixOS Desktop"
#   bitrate = 320
#   cache_path = "/home/user/.cache/spotifyd"
#   volume_normalisation = true
#
{
  config,
  lib,
  pkgs,
  hostname,
  ...
}:
with lib; let
  cfg = config.modules.services.spotifyd;
in {
  options.modules.services.spotifyd = {
    enable = mkEnableOption "spotifyd Spotify Connect daemon";

    deviceName = mkOption {
      type = types.str;
      default = "${hostname}-spotifyd";
      description = "Name shown in Spotify Connect device list";
    };

    backend = mkOption {
      type = types.enum ["pulseaudio" "alsa"];
      default = "pulseaudio";
      description = "Audio backend (pulseaudio works with PipeWire)";
    };

    bitrate = mkOption {
      type = types.enum [96 160 320];
      default = 320;
      description = "Audio bitrate in kbps";
    };
  };

  config = mkIf cfg.enable {
    # Install spotifyd package
    environment.systemPackages = [pkgs.spotifyd];

    # Systemd user service for spotifyd
    # Runs as user service, starts on login, waits for network and audio
    systemd.user.services.spotifyd = {
      description = "Spotify Connect daemon";
      wantedBy = ["default.target"];
      after = ["network-online.target" "pipewire.service" "pipewire-pulse.service"];
      wants = ["network-online.target"];

      serviceConfig = {
        ExecStart = "${pkgs.spotifyd}/bin/spotifyd --no-daemon --config-path %h/.config/spotifyd/spotifyd.conf";
        Restart = "on-failure";
        RestartSec = 5;
      };

      # Environment for PipeWire/PulseAudio compatibility
      environment = {
        # spotifyd will use XDG_RUNTIME_DIR for PulseAudio socket
        PULSE_SERVER = "unix:/run/user/%U/pulse/native";
      };
    };
  };
}
