# ~/NixOS/modules/hardware/laptop/default.nix
#
# Module: Laptop Hardware (Orchestrator)
# Purpose: Main orchestrator for laptop-specific hardware configuration
# Part of: 001-module-optimization (T035-T039 - split from monolithic laptop.nix)
{...}: {
  imports = [
    ./options.nix
    ./power.nix
    ./hardware.nix
  ];
}
