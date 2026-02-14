{...}: {
  # Gaming modules aggregator
  # Imports all gaming-specific modules for NixOS gaming optimization

  imports = [
    ./steam.nix
    ./protontricks.nix
    ./gamemode.nix
    ./shader-cache.nix
    ./mangohud.nix
  ];
}
