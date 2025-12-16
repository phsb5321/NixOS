# ~/NixOS/modules/hardware/laptop/power.nix
#
# Module: Laptop Power Management
# Purpose: Power management, battery optimization, CPU frequency scaling
# Part of: 001-module-optimization (T035-T039 - hardware/laptop.nix split)
{
  config,
  lib,
  ...
}: let
  cfg = config.modules.hardware.laptop;
in {
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

    # CPU frequency scaling
    powerManagement = {
      enable = true;
      cpuFreqGovernor = lib.mkDefault cfg.powerManagement.profile;
    };
  };
}
