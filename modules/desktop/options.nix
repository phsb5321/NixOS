{lib, ...}:
with lib; {
  options.modules.desktop = {
    enable = mkEnableOption "Desktop environment module";

    environment = mkOption {
      type = types.enum ["gnome" "kde" "hyprland"];
      default = "gnome";
      description = "The desktop environment to use";
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
