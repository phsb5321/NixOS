# ~/NixOS/lib/default.nix
# Library functions for NixOS configuration
{ lib, inputs }:

{
  # Import utility functions
  utils = import ./utils.nix { inherit lib; };

  # Import system builders
  builders = import ./builders.nix { inherit lib inputs; };
}
