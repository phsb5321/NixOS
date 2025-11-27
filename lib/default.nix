# NixOS Module Optimization - Shared Library Functions
# Purpose: Centralized utilities for reducing code duplication across modules
# See: docs/module-patterns.md for usage examples
{lib, ...}: {
  # Import sub-modules
  moduleHelpers = import ./module-helpers.nix {inherit lib;};
  systemBuilders = import ./system-builders.nix {inherit lib;};
}
