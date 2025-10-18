# ~/NixOS/modules/packages/new-default.nix
# New modular packages system - imports all category modules
{
  imports = [
    ./categories/browsers.nix
    ./categories/development.nix
    ./categories/media.nix
    ./categories/gaming.nix
    ./categories/utilities.nix
    ./categories/audio-video.nix
    ./categories/terminal.nix
  ];
}
