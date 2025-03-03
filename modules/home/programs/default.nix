# ~/NixOS/hosts/modules/home/programs/default.nix
{
  imports = [
    ./fish.nix
    ./zsh.nix
    ./kitty.nix
    ./git.nix
    ./nixvim.nix
  ];
}
