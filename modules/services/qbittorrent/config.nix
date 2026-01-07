# qBittorrent Configuration File Generation
# Generates qBittorrent.conf and manages config setup
{
  config,
  lib,
  ...
}: let
  cfg = config.modules.services.qbittorrent;
in {
  config = lib.mkIf cfg.enable {
    # qBittorrent configuration file
    environment.etc."qbittorrent/qBittorrent.conf" = {
      text = ''
        [Preferences]
        WebUI\Enabled=true
        WebUI\Port=${toString cfg.port}
        WebUI\Address=*
        WebUI\LocalHostAuth=${
          if cfg.webUI.bypassLocalAuth
          then "false"
          else "true"
        }
        ${lib.optionalString (cfg.webUI.bypassAuthSubnetWhitelist != "") ''
          WebUI\AuthSubnetWhitelist=${cfg.webUI.bypassAuthSubnetWhitelist}
          WebUI\AuthSubnetWhitelistEnabled=true
        ''}
        Downloads\SavePath=${cfg.downloadDir}
        Downloads\TempPath=${cfg.incompleteDir}
        Downloads\TempPathEnabled=true
        Downloads\ScanDirsV2=@Variant(\0\0\0\x1c\0\0\0\x1\0\0\0\x1a\0${builtins.replaceStrings ["/"] ["\\/"] cfg.watchDir}\0\0\0\x2\0\0\0\0)
        BitTorrent\Session\Port=${toString cfg.torrentPort}
        ${lib.optionalString (cfg.settings.maxRatio != null) ''
          BitTorrent\MaxRatio=${toString cfg.settings.maxRatio}
          BitTorrent\MaxRatioAction=0
        ''}
        ${lib.optionalString (cfg.settings.maxSeedingTime != null) ''
          BitTorrent\MaxSeedingMinutes=${toString cfg.settings.maxSeedingTime}
        ''}
        ${lib.optionalString (cfg.settings.downloadLimit != null) ''
          BitTorrent\Session\GlobalDLSpeedLimit=${toString (cfg.settings.downloadLimit * 1024)}
        ''}
        ${lib.optionalString (cfg.settings.uploadLimit != null) ''
          BitTorrent\Session\GlobalUPSpeedLimit=${toString (cfg.settings.uploadLimit * 1024)}
        ''}
        ${lib.optionalString cfg.webhook.enable ''
          Downloads\FinishedTorrentExportDir=
          Downloads\TorrentExportDir=
        ''}
      '';
      mode = "0644";
    };

    # Copy configuration to qBittorrent data directory
    systemd.services.qbittorrent-config-setup = {
      description = "Setup qBittorrent configuration";
      before = ["qbittorrent.service"];
      wantedBy = ["multi-user.target"];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        User = cfg.user;
        Group = cfg.group;
      };
      script = ''
        mkdir -p ${cfg.dataDir}/qBittorrent/config
        cp /etc/qbittorrent/qBittorrent.conf ${cfg.dataDir}/qBittorrent/config/qBittorrent.conf
        chmod 644 ${cfg.dataDir}/qBittorrent/config/qBittorrent.conf
      '';
    };
  };
}
