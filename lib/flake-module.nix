# ~/NixOS/lib/flake-module.nix
# Flake-parts module to expose library functions
{
  self,
  lib,
  ...
}: {
  flake.lib = import ./default.nix {
    inherit lib;
    inherit (self) inputs;
  };
}
