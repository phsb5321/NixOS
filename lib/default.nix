# ~/NixOS/lib/default.nix
#
# Library Functions and Utilities
# Purpose: Centralized helper functions for NixOS configuration
# Part of: 001-module-optimization
{
  lib,
  pkgs,
  ...
}: {
  # Import all library modules
  module-helpers = import ./module-helpers.nix {inherit lib pkgs;};
  system-builders = import ./system-builders.nix {inherit lib pkgs;};
}
