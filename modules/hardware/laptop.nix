# Laptop-specific hardware configuration module
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.hardware.laptop;
in {
  options.modules.hardware.laptop = {
    enable = lib.mkEnableOption "laptop-specific hardware support";

    batteryManagement = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable battery management tools and optimizations";
      };

      chargeThreshold = lib.mkOption {
        type = lib.types.nullOr lib.types.int;
        default = null;
        example = 80;
        description = "Battery charge threshold percentage (if supported)";
      };
    };

    powerManagement = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable power management optimizations";
      };

      profile = lib.mkOption {
        type = lib.types.enum ["powersave" "balanced" "performance"];
        default = "balanced";
        description = "Default power profile";
      };

      autoSuspend = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable automatic suspend on lid close";
      };

      suspendTimeout = lib.mkOption {
        type = lib.types.int;
        default = 900; # 15 minutes
        description = "Suspend timeout in seconds";
      };
    };

    display = {
      autoRotate = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable automatic display rotation for convertibles";
      };

      brightnessControl = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable brightness control";
      };

      nightLight = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable night light (blue light filter)";
      };
    };

    touchpad = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable touchpad support";
      };

      naturalScrolling = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable natural scrolling";
      };

      tapToClick = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable tap to click";
      };

      disableWhileTyping = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Disable touchpad while typing";
      };
    };

    extraPackages = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [];
      description = "Additional packages for laptop hardware support";
    };
  };

  config = lib.mkIf cfg.enable {
    # Battery management
    services.upower = {
      enable = true;
      percentageLow = 15;
      percentageCritical = 5;
      percentageAction = 3;
      criticalPowerAction = "Hibernate";
    };

    # TLP for power management
    services.tlp = lib.mkIf cfg.powerManagement.enable {
      enable = true;
      settings = {
        CPU_SCALING_GOVERNOR_ON_AC = "performance";
        CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
        CPU_MIN_PERF_ON_AC = 0;
        CPU_MAX_PERF_ON_AC = 100;
        CPU_MIN_PERF_ON_BAT = 0;
        CPU_MAX_PERF_ON_BAT = 60;

        # Battery charge thresholds (if supported by hardware)
        START_CHARGE_THRESH_BAT0 =
          lib.mkIf (cfg.batteryManagement.chargeThreshold != null)
          (cfg.batteryManagement.chargeThreshold - 5);
        STOP_CHARGE_THRESH_BAT0 = cfg.batteryManagement.chargeThreshold;

        # USB autosuspend
        USB_AUTOSUSPEND = 1;

        # PCIe power management
        RUNTIME_PM_ON_AC = "auto";
        RUNTIME_PM_ON_BAT = "auto";

        # WiFi power saving
        WIFI_PWR_ON_AC = "off";
        WIFI_PWR_ON_BAT = "on";
      };
    };

    # Thermald for thermal management
    services.thermald.enable = cfg.powerManagement.enable;

    # Power profiles daemon (alternative to TLP for GNOME integration)
    services.power-profiles-daemon.enable = lib.mkIf (!config.services.tlp.enable) true;

    # Logind configuration for lid and power button actions
    services.logind.settings.Login = lib.mkIf cfg.powerManagement.enable {
      HandleLidSwitch =
        if cfg.powerManagement.autoSuspend
        then "suspend"
        else "ignore";
      HandleLidSwitchExternalPower =
        if cfg.powerManagement.autoSuspend
        then "suspend"
        else "ignore";
      HandlePowerKey = "suspend";
      IdleAction = "suspend";
      IdleActionSec = "${toString cfg.powerManagement.suspendTimeout}s";
    };

    # Display configuration
    # Night light is handled by GNOME settings, not environment variables

    # Touchpad configuration
    services.libinput = lib.mkIf cfg.touchpad.enable {
      enable = true;
      touchpad = {
        naturalScrolling = cfg.touchpad.naturalScrolling;
        tapping = cfg.touchpad.tapToClick;
        disableWhileTyping = cfg.touchpad.disableWhileTyping;
        scrollMethod = "twofinger";
        accelSpeed = "0";
      };
    };

    # Essential laptop packages
    environment.systemPackages = with pkgs;
      [
        # Power management
        powertop
        acpi

        # Display control
        brightnessctl

        # Battery monitoring
        acpitool

        # System monitoring
        lm_sensors
      ]
      ++ lib.optionals cfg.batteryManagement.enable [
        # Battery specific tools
        upower
      ]
      ++ cfg.extraPackages;

    # Hardware support
    hardware = {
      bluetooth.enable = true;
      bluetooth.powerOnBoot = true;
    };

    # Enable firmware updates
    services.fwupd.enable = true;

    # CPU frequency scaling
    powerManagement = {
      enable = true;
      cpuFreqGovernor = lib.mkDefault cfg.powerManagement.profile;
    };

    # ACPI event handling
    services.acpid = {
      enable = true;
      handlers = {
        # Handle brightness keys if needed
        brightnessUp = lib.mkIf cfg.display.brightnessControl {
          event = "video/brightnessup";
          action = "${pkgs.brightnessctl}/bin/brightnessctl set +10%";
        };
        brightnessDown = lib.mkIf cfg.display.brightnessControl {
          event = "video/brightnessdown";
          action = "${pkgs.brightnessctl}/bin/brightnessctl set 10%-";
        };
      };
    };
  };
}
