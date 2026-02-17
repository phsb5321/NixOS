# ~/NixOS/modules/hardware/laptop/power.nix
#
# Module: Laptop Power Management
# Purpose: Power management, CPU frequency scaling, power-profiles-daemon
# Part of: 001-module-optimization (T035-T039 - hardware/laptop.nix split)
{
  config,
  lib,
  pkgs,
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
      criticalPowerAction = "PowerOff"; # No swap device — hibernate would fail silently
    };

    # Thermald for thermal management
    services.thermald.enable = cfg.powerManagement.enable;

    # power-profiles-daemon is the active power manager (GNOME force-disables TLP).
    # ppd manages EPP which is the actual performance control on HWP-capable CPUs.
    services.power-profiles-daemon.enable = true;

    # Set ppd to match the configured profile at boot
    # (ppd defaults to "balanced" on every boot regardless of NixOS config)
    systemd.services.ppd-set-profile = lib.mkIf cfg.powerManagement.enable {
      description = "Set power-profiles-daemon profile to ${cfg.powerManagement.profile}";
      after = ["power-profiles-daemon.service"];
      wants = ["power-profiles-daemon.service"];
      wantedBy = ["multi-user.target"];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${pkgs.power-profiles-daemon}/bin/powerprofilesctl set ${cfg.powerManagement.profile}";
        RemainAfterExit = true;
      };
    };

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
    # intel_pstate active mode only accepts "performance" and "powersave".
    # "powersave" enables HWP dynamic scaling via EPP — it is NOT the same as
    # generic powersave. The actual performance level is controlled by ppd via EPP.
    powerManagement = {
      enable = true;
      cpuFreqGovernor = lib.mkDefault (
        if cfg.powerManagement.profile == "performance"
        then "performance"
        else "powersave"
      );
    };
  };
}
