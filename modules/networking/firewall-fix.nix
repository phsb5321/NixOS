# ~/NixOS/modules/networking/firewall-fix.nix
{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.modules.networking;
in {
  config = mkIf cfg.enable {
    # Simplified firewall configuration that avoids potential issues
    networking.firewall = mkIf cfg.firewall.enable {
      enable = true;
      allowPing = cfg.firewall.allowPing;

      # Essential ports for AI services, GitHub and networking
      allowedTCPPorts = cfg.firewall.openPorts ++ [443];
      allowedUDPPorts = cfg.firewall.openPorts;

      # Trust interfaces if specified
      trustedInterfaces = cfg.firewall.trustedInterfaces;

      # Allow mDNS and DHCP
      allowedUDPPortRanges = [
        {
          from = 5353;
          to = 5353;
        } # mDNS
        {
          from = 67;
          to = 68;
        } # DHCP
      ];

      # Extra firewall commands without the iptables direct manipulation that might cause issues
      extraCommands = ''
        # Allow all HTTPS traffic for AI services and GitHub
        # This is a safer approach than trying to add individual rules
      '';
    };

    # Add important AI service domains to hosts file for reliability
    networking.extraHosts = ''
      # OpenAI services
      104.16.131.131 chat.openai.com
      104.18.7.192 api.openai.com
      104.18.6.192 platform.openai.com
      104.18.192.86 openai.com
      104.16.192.91 auth0.openai.com
      104.18.223.218 oaiusercontent.com

      # GitHub Copilot services
      140.82.114.3 github.com
      140.82.114.6 api.github.com
      20.200.245.245 api.individual.githubcopilot.com
      185.199.111.133 copilot-proxy.githubusercontent.com
    '';
  };
}
