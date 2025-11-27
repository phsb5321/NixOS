# System Construction Utilities
# Helpers for building consistent system configurations
{lib, ...}: {
  # Package category builder
  # Standardizes package category module structure
  mkPackageCategory = {
    name,
    description,
    packages ? [],
    ...
  }: {
    config,
    lib,
    pkgs,
    ...
  }: let
    cfg = config.modules.packages.categories.${name};
  in {
    options.modules.packages.categories.${name} = with lib; {
      enable = mkEnableOption "${description}";
    };
    config = lib.mkIf cfg.enable {
      environment.systemPackages = packages;
    };
  };

  # Priority-based configuration merger
  # Combines configurations with explicit priority handling
  mergeWithPriority = priority: value:
    lib.mkOverride priority value;

  # Conditional package inclusion helper
  pkgsIf = condition: packages:
    if condition
    then packages
    else [];

  # Enable all options in a set
  enableAll = options:
    builtins.mapAttrs (name: value: true) options;
}
