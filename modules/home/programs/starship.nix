{ config, lib, pkgs, ... }:

{
  programs.starship = {
    enable = true;
    settings = {
      format = "$all$character";
      character = {
        success_symbol = "[➜](bold green)";
        error_symbol = "[➜](bold red)";
      };
      git_branch = {
        symbol = " ";
      };
      git_status = {
        ahead = "⇡\${count}";
        behind = "⇣\${count}";
        diverged = "⇕⇡\${ahead_count}⇣\${behind_count}";
        conflicted = "=";
        deleted = "✘";
        modified = "!";
        renamed = "»";
        staged = "+";
        stashed = "\\$";
        untracked = "?";
      };
      nix_shell = {
        symbol = " ";
        format = "via [$symbol$state( \\($name\\))]($style) ";
      };
      directory = {
        truncation_length = 3;
        truncation_symbol = "…/";
      };
    };
  };
}
