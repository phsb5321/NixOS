# ~/NixOS/modules/services/default.nix
# Service modules for NixOS configuration
{ ... }: {
  imports = [
    ./spotifyd.nix
  ];
}
