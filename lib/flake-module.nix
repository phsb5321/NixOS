# ~/NixOS/lib/flake-module.nix
# Flake-parts module to expose library functions
<<<<<<< HEAD
{ self, lib, ... }:

{
=======
{
  self,
  lib,
  ...
}: {
>>>>>>> origin/host/server
  flake.lib = import ./default.nix {
    inherit lib;
    inherit (self) inputs;
  };
}
