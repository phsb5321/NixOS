# ~/NixOS/modules/default.nix
{
  imports = [
    ./desktop
    ./networking
    ./core
    ./packages
    ./hardware
  ];
}
