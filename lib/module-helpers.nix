# Shared Utility Functions for Module Creation
# Common patterns extracted from modules for reuse
{lib, ...}: {
  # Service module creator
  # Reduces boilerplate for simple services
  mkServiceModule = {
    name,
    description,
    package,
    defaultPort ? null,
    ...
  }: {
    config,
    lib,
    pkgs,
    ...
  }: let
    cfg = config.modules.services.${name};
  in {
    options.modules.services.${name} = with lib; {
      enable = mkEnableOption "${description}";
      # Add common options automatically
    };
    config = lib.mkIf cfg.enable {
      # Standard service setup
    };
  };

  # Option group creator
  # Groups related options under an attrset
  mkOptionGroup = options:
    lib.mkOption {
      type = lib.types.submodule {inherit options;};
      default = {};
    };
}
