{lib, ...}:
with lib; {
  options.modules.desktop = {
    enable = mkEnableOption "Desktop environment module";

    environment = mkOption {
      type = types.enum ["gnome" "kde"];
      default = "gnome";
      description = "The desktop environment to use";
    };

    # Display and session configuration
    displayManager = {
      wayland = mkOption {
        type = types.bool;
        default = true;
        description = "Enable Wayland support for the display manager";
      };

      autoSuspend = mkOption {
        type = types.bool;
        default = true;
        description = "Allow the display manager to auto-suspend the system";
      };
    };

    # Accessibility options
    accessibility = {
      enable = mkEnableOption "Accessibility features";

      screenReader = mkOption {
        type = types.bool;
        default = false;
        description = "Enable screen reader support";
      };

      magnifier = mkOption {
        type = types.bool;
        default = false;
        description = "Enable screen magnifier";
      };

      onScreenKeyboard = mkOption {
        type = types.bool;
        default = false;
        description = "Enable on-screen keyboard";
      };
    };

    # Theming options
    theming = {
      preferDark = mkOption {
        type = types.bool;
        default = true;
        description = "Prefer dark theme when available";
      };

      accentColor = mkOption {
        type = types.enum ["blue" "purple" "pink" "red" "orange" "yellow" "green" "gray" "teal" "indigo"];
        default = "blue";
        description = "System accent color for modern GNOME themes";
      };
    };

    # Hardware integration
    hardware = {
      enableTouchpad = mkOption {
        type = types.bool;
        default = true;
        description = "Enable touchpad configuration and gestures";
      };

      enableBluetooth = mkOption {
        type = types.bool;
        default = true;
        description = "Enable Bluetooth support";
      };

      enablePrinting = mkOption {
        type = types.bool;
        default = true;
        description = "Enable printing support";
      };

      enableScanning = mkOption {
        type = types.bool;
        default = false;
        description = "Enable scanner support";
      };
    };

    extraPackages = mkOption {
      type = with types; listOf package;
      default = [];
      description = "Additional packages to install for the desktop environment";
    };

    autoLogin = {
      enable = mkEnableOption "Automatic login";
      user = mkOption {
        type = types.str;
        description = "Username for automatic login";
      };
    };
  };
}
