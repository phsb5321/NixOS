# ~/NixOS/lib/default.nix
# Library functions for NixOS configuration
{
  lib,
  inputs,
  ...
}: {
  # Import all lib modules
  builders = import ./builders.nix {inherit lib inputs;};
  utils = import ./utils.nix {inherit lib;};

  # Re-export commonly used nixpkgs lib functions
  inherit
    (lib)
    mkIf
    mkDefault
    mkForce
    mkMerge
    mkBefore
    mkAfter
    mkEnableOption
    mkOption
    types
    optionals
    optionalAttrs
    ;
}
