{ config, lib, pkgs, ... }:

{
  imports = [
    ./options.nix
    ./common
    ./hyprland
    ./gnome
    ./kde
  ];
}
