# ~/NixOS/modules/core/java.nix
{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.modules.core.java;

  # Custom JDK with JavaFX support
  customJDK = pkgs.jdk17.override {
    enableJavaFX = true;
  };
in {
  options.modules.core.java = {
    enable = mkEnableOption "Java development environment";

    package = mkOption {
      type = types.package;
      default = customJDK;
      description = "The Java package to use";
    };

    javaFx.enable = mkOption {
      type = types.bool;
      default = true;
      description = "Whether to enable JavaFX support";
    };

    androidTools.enable = mkOption {
      type = types.bool;
      default = true;
      description = "Whether to enable Android tools support";
    };
  };

  config = mkIf cfg.enable {
    # System packages
    environment.systemPackages = with pkgs; [
      # Java Development Kit
      cfg.package
      openjfx17
      maven
      gradle
      ant

      # GUI dependencies
      gtk3
      glib
      xorg.libX11
      xorg.libXrender
      xorg.libXtst
      alsa-lib
      cairo
      pango
      gdk-pixbuf
      libGL

      # Android tools if enabled
      (mkIf cfg.androidTools.enable android-tools)
    ];

    # Environment variables for Java and JavaFX
    environment.variables = {
      JAVA_HOME = "${cfg.package.home}";
      _JAVA_AWT_WM_NONREPARENTING = "1";
      ANDROID_HOME = mkIf cfg.androidTools.enable "/home/notroot/.android/sdk";
    };

    # Add udev rules for Android devices
    services.udev.extraRules = mkIf cfg.androidTools.enable ''
      # Google
      SUBSYSTEM=="usb", ATTR{idVendor}=="18d1", MODE="0666", GROUP="adbusers"
      # Xiaomi
      SUBSYSTEM=="usb", ATTR{idVendor}=="2717", MODE="0666", GROUP="adbusers"
      # OnePlus
      SUBSYSTEM=="usb", ATTR{idVendor}=="2a70", MODE="0666", GROUP="adbusers"
      # Generic
      SUBSYSTEM=="usb", ATTR{idVendor}=="1f3a", MODE="0666", GROUP="adbusers"
    '';

    # Setup Android debug bridge users group
    users.groups.adbusers = {};

    # Add your user to adbusers group if Android tools are enabled
    users.users.notroot.extraGroups = mkIf cfg.androidTools.enable ["adbusers"];

    # System configurations for better Java application support
    security.polkit.enable = true;
    programs.dconf.enable = true;

    # Fix common Java application issues
    security.pam.loginLimits = [
      {
        domain = "*";
        type = "soft";
        item = "nofile";
        value = "4096";
      }
    ];

    # System-wide Java configuration
    programs.java = {
      enable = true;
      package = cfg.package;
    };
  };
}
