# ~/NixOS/modules/home/programs/default.nix
{
  imports = [
    ./zsh.nix
    ./kitty.nix
    ./git.nix
    ./ssh.nix
    ./nixvim.nix
    ./zellij.nix
    ./ghostty.nix
  ];
}
