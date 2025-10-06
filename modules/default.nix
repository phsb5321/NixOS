# ~/NixOS/modules/default.nix
{
  imports = [
    ./core
    ./packages
    ./networking
    ./desktop
    ./dotfiles
    ./hardware
    ./profiles
    ./services
    ./roles
    ./gpu
  ];
}
