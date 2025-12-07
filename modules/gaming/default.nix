{
  config,
  lib,
  pkgs,
  ...
}: {
  # Gaming modules aggregator
  # Imports all gaming-specific modules for NixOS gaming optimization

  imports = [
    ./steam.nix
    ./protontricks.nix
    ./performance-tools.nix
    ./low-latency-audio.nix
    ./gamemode.nix
    ./shader-cache.nix
    ./mangohud.nix
  ];
}
