# modules/core/pipewire.nix
{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.modules.core.pipewire;
in {
  options.modules.core.pipewire = {
    enable = mkEnableOption "PipeWire audio system";

    # High quality audio settings
    highQualityAudio = mkOption {
      type = types.bool;
      default = true;
      description = "Enable high quality audio configuration";
    };

    # Bluetooth settings
    bluetooth = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable Bluetooth audio via PipeWire";
      };

      highQualityProfiles = mkOption {
        type = types.bool;
        default = true;
        description = "Enable high quality Bluetooth audio codecs";
      };
    };

    # Used for real-time audio applications
    lowLatency = mkOption {
      type = types.bool;
      default = false;
      description = "Enable settings optimized for low-latency audio (for music production)";
    };

    # Tools options
    tools = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Install PipeWire tools";
      };

      extraPackages = mkOption {
        type = with types; listOf package;
        default = [];
        description = "Additional PipeWire-related packages to install";
      };
    };
  };

  config = mkIf cfg.enable {
    # Ensure PipeWire is enabled and PulseAudio is disabled
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      jack.enable = true;
      wireplumber.enable = true;

      # Single extraConfig definition for all settings
      extraConfig = {
        # High quality audio settings
        pipewire = mkIf cfg.highQualityAudio {
          "context.properties" = {
            "default.clock.rate" = "48000";
            "default.clock.allowed-rates" = "[ 44100 48000 88200 96000 192000 ]";
            "default.clock.quantum" =
              if cfg.lowLatency
              then "64"
              else "1024";
            "default.clock.min-quantum" =
              if cfg.lowLatency
              then "16"
              else "32";
            "default.clock.max-quantum" =
              if cfg.lowLatency
              then "1024"
              else "8192";
          };
        };

        # Enhanced Bluetooth settings with better autoswitch support
        "pipewire-pulse" = mkIf cfg.bluetooth.enable {
          "pulse.properties" = {
            "server.address" = "[ unix:native ]";
            "module.bluez5.autoswitch-profile" = "true";
            "bluez5.enable-sbc-xq" = "true";
            "bluez5.enable-msbc" = "true";
            "bluez5.enable-hw-volume" = "true";
            "bluez5.headset-roles" = "[ hsp_hs hsp_ag hfp_hf hfp_ag ]";
            "bluez5.codecs" = "[ sbc sbc_xq aac ldac aptx aptx_hd ]";
          };
        };
      };
    };

    # Explicitly disable PulseAudio
    services.pulseaudio.enable = lib.mkForce false;

    # Enable realtime scheduling for audio applications
    security.rtkit.enable = true;

    # Bluetooth configuration for PipeWire
    hardware.bluetooth = mkIf cfg.bluetooth.enable {
      enable = true;
      powerOnBoot = true;
      settings = {
        General = {
          Enable = "Source,Sink,Media,Socket";
          Experimental = mkIf cfg.bluetooth.highQualityProfiles "true";
        };
      };
    };

    # Install PipeWire tools
    environment.systemPackages = with pkgs;
      mkIf cfg.tools.enable ([
          # Core PipeWire packages
          pipewire
          wireplumber

          # Audio tools
          easyeffects # Audio effects processor
          pavucontrol # PulseAudio volume control (works with PipeWire)
          helvum # PipeWire patchbay

          # Media tools that integrate well with PipeWire
          qpwgraph # Qt PipeWire Graph
          pulsemixer # TUI mixer for PulseAudio/PipeWire
          playerctl # MPRIS controller
        ]
        ++ cfg.tools.extraPackages);

    # Add users to audio group
    users.groups.audio.gid = config.ids.gids.audio or 29;

    # Set user realtime priority for audio
    security.pam.loginLimits = [
      {
        domain = "@audio";
        item = "memlock";
        type = "-";
        value = "unlimited";
      }
      {
        domain = "@audio";
        item = "rtprio";
        type = "-";
        value = "99";
      }
      {
        domain = "@audio";
        item = "nofile";
        type = "soft";
        value = "99999";
      }
      {
        domain = "@audio";
        item = "nofile";
        type = "hard";
        value = "99999";
      }
    ];
  };
}
