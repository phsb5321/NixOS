# ~/NixOS/modules/home/hosts/laptop.nix
# This file is now deprecated - all configurations moved to system-level
# Home Manager is now completely generic and shared across all hosts
{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
with lib; {
  # Import only shared configuration
  imports = [
    ../shared.nix
  ];

  # No host-specific configurations in Home Manager
  # All host-specific packages should be defined at system level
}
