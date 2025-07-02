# ~/NixOS/modules/home/programs/default.nix
{
  imports = [
    ./zsh.nix
    ./starship.nix
    ./kitty.nix
    ./git.nix
    ./nixvim.nix
    ./zellij.nix
    ./ghostty.nix
    ./vscode.nix
  ];
}
