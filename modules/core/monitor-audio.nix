# modules/core/monitor-audio.nix
{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.modules.core.monitorAudio;
in {
  options.modules.core.monitorAudio = {
    enable = mkEnableOption "Monitor audio output support";

    autoSwitch = mkOption {
      type = types.bool;
      default = true;
      description = "Automatically switch to HDMI/DisplayPort audio when connected";
    };

    preferMonitorAudio = mkOption {
      type = types.bool;
      default = false;
      description = "Prefer monitor audio over other outputs when available";
    };
  };

  config = mkIf cfg.enable {
    # Essential packages for audio device management
    environment.systemPackages = with pkgs; [
      alsa-utils
      pamixer
      pavucontrol
    ];

    # Core audio configuration
    services.pulseaudio.enable = false;

    # PipeWire configuration for HDMI/DP audio
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      jack.enable = true;

      # Enhanced PipeWire configuration for monitor audio
      extraConfig = {
        # Better device detection and routing
        "pipewire-pulse" = {
          "pulse.properties" = {
            # Improved device detection
            "pulse.defaults.sink.api" = "alsa";
            # Auto-switching behavior based on config
            "module.stream-restore.restore-device" =
              if cfg.autoSwitch
              then "true"
              else "false";
          };
          "pulse.rules" = [
            {
              # Match HDMI outputs and increase their priority if preferred
              matches = [{"node.name" = "~hdmi*";} {"node.name" = "~displayport*";}];
              actions = {
                "update-props" = {
                  "node.nick" = "Monitor Audio";
                  "priority.session" = mkIf cfg.preferMonitorAudio 1500;
                  "priority.driver" = mkIf cfg.preferMonitorAudio 1500;
                  "node.pause-on-idle" = false;
                };
              };
            }
          ];
        };
      };
    };

    # Add udev rules for better hotplug detection
    services.udev.extraRules = ''
      # When HDMI/DP cables are connected/disconnected
      ACTION=="change", SUBSYSTEM=="drm", ENV{HOTPLUG}=="1", RUN+="${pkgs.systemd}/bin/systemctl --no-block try-restart pipewire pipewire-pulse"
    '';

    # System-wide configurations to improve HDMI audio detection
    boot.kernelModules = [
      "snd_hda_codec_hdmi" # HDMI audio codec support
    ];

    boot.kernelParams =
      [
        "snd_hda_intel.enable_hdmi=1" # Enable HDMI audio for Intel
      ]
      ++ lib.optionals config.hardware.graphics.enable [
        "radeon.audio=1" # Enable HDMI audio for Radeon
        "amdgpu.audio=1" # Enable HDMI audio for AMDGPU
      ];
  };
}
