# ~/NixOS/modules/home/programs/default.nix
{
  imports = [
    ./fish.nix
    ./zsh.nix
    ./starship.nix
    ./kitty.nix
    ./git.nix
    ./nixvim.nix
    ./zellij.nix
    ./ghostty.nix
  ];
}
