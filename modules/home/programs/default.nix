# ~/NixOS/hosts/modules/home/programs/default.nix
{
  imports = [
    ./fish.nix
    ./zsh.nix
    ./kitty.nix
    ./zellij.nix
    # ./git.nix
    ./nixvim.nix
  ];
}
