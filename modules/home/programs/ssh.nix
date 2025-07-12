# ~/NixOS/modules/home/programs/ssh.nix
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
      programs.ssh = {
        enable = true;

        # Common SSH configuration
        extraConfig = ''
          # Use SSH key agent for authentication
          AddKeysToAgent yes

          # Keep connections alive
          ServerAliveInterval 60
          ServerAliveCountMax 3

          # Reuse connections
          ControlMaster auto
          ControlPath ~/.ssh/sockets/%r@%h-%p
          ControlPersist 600

          # Security settings
          HashKnownHosts yes
          VisualHostKey yes

          # Performance
          Compression yes
        '';

        # Common host configurations
        matchBlocks = {
          # GitHub configuration
          "github.com" = {
            hostname = "github.com";
            user = "git";
            identityFile = "~/.ssh/id_ed25519";
            identitiesOnly = true;
          };

          # GitLab configuration
          "gitlab.com" = {
            hostname = "gitlab.com";
            user = "git";
            identityFile = "~/.ssh/id_ed25519";
            identitiesOnly = true;
          };

          # Local development servers
          "*.local" = {
            extraOptions = {
              CheckHostIP = "no";
              StrictHostKeyChecking = "no";
              UserKnownHostsFile = "/dev/null";
            };
          };
        };
      };

      # Create SSH socket directory
      home.file.".ssh/sockets/.keep".text = "";
    };
  };
}
