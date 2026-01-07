# ~/NixOS/modules/default.nix
# Note: profiles/ has moved to top-level profiles/ directory
# Host configurations now import profiles directly
{
  imports = [
    ./core
    ./packages
    ./networking
    ./desktop
    ./dotfiles
    ./hardware
    ./services
    ./gpu
    ./secrets
    ./gaming
  ];
}
