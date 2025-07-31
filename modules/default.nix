# ~/NixOS/modules/default.nix
{
  imports = [
    ./networking
    ./core
    ./packages
    ./dotfiles
  ];
}
