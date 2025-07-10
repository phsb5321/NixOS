# ~/NixOS/hosts/modules/home/programs/git.nix
{
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.modules.home;
in {
  config = mkIf cfg.enable {
    home-manager.users.${cfg.username} = {
      programs.git = {
        enable = true;
        userName = "Pedro Balbino";
        userEmail = "phsb5321@gmail.com";
        extraConfig = {
          core = {
            editor = "nvim";
            autocrlf = "input";
            safecrlf = true;
            pager = "delta";
          };
          init.defaultBranch = "main";
          pull.rebase = true;
          push.default = "current";
          merge.conflictstyle = "diff3";
          diff.colorMoved = "default";
          rerere.enabled = true;
          branch.autosetupmerge = "always";
          branch.autosetuprebase = "always";
          
          # Delta configuration for better diffs
          delta = {
            navigate = true;
            light = false;
            line-numbers = true;
            side-by-side = true;
          };
          
          # Better log formatting
          alias = {
            lg = "log --color --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit";
            st = "status -s";
            co = "checkout";
            br = "branch";
            ci = "commit";
            unstage = "reset HEAD --";
            last = "log -1 HEAD";
            visual = "!gitk";
          };
        };
      };
    };
  };
}
