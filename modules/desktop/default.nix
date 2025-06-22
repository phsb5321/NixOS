# hosts/modules/desktop/default.nix
{
  config,
  lib,
  pkgs,
  ...
}: {
  imports = [
    ./options.nix
    ./common
    ./coordinator.nix
    ./gnome
    ./kde
  ];
}
