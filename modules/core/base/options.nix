# ~/NixOS/modules/core/base/options.nix
#
# Module: Core System Options
# Purpose: Declares all core system configuration options
# Part of: 001-module-optimization (T030-T034 - core/default.nix split)
{lib, ...}: {
  options.modules.core = with lib; {
    enable = mkEnableOption "Core system configuration module";

    stateVersion = mkOption {
      type = types.str;
      description = "The NixOS state version";
    };

    timeZone = mkOption {
      type = types.str;
      default = "UTC";
      description = "System timezone";
    };

    defaultLocale = mkOption {
      type = types.str;
      default = "en_US.UTF-8";
      description = "Default system locale";
    };

    extraSystemPackages = mkOption {
      type = with types; listOf package;
      default = [];
      description = "Additional system-wide packages to install";
    };

    # 🎯 KEYBOARD LAYOUT: Configuration options for Brazilian layout
    keyboard = {
      enable = mkOption {
        type = types.bool;
        default = false; # Disabled by default to let desktop environments handle it
        description = "Enable explicit keyboard configuration";
      };

      layout = mkOption {
        type = types.str;
        default = "br";
        description = "Keyboard layout";
      };

      variant = mkOption {
        type = types.str;
        default = ""; # Default to standard Brazilian ABNT (no variant)
        description = "Keyboard variant";
      };

      options = mkOption {
        type = types.str;
        default = "grp:alt_shift_toggle,compose:ralt";
        description = "Keyboard options";
      };
    };
  };
}
