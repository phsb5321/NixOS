{
  lib,
  pkgs,
  config,
  ...
}: {
  config = {
    services.languagetool = {
      enable = lib.mkDefault config.homeServer.enable;
      port = lib.mkDefault 8081;
      allowOrigin = lib.mkDefault "*";
      public = lib.mkDefault true;

      package = lib.mkDefault pkgs.languagetool;
      jrePackage = lib.mkDefault pkgs.openjdk17;

      jvmOptions = lib.mkDefault [
        "-Xmx512m"
        "-XX:+UseG1GC"
        "-XX:MaxGCPauseMillis=100"
        "-Dfile.encoding=UTF-8"
        "-Djava.awt.headless=true"
      ];

      settings = {
        maxTextLength = 100000;
        maxCheckTimeMillis = 60000;
        maxErrors = 500;
        cacheSize = 1000;
        warmup = true;
      };
    };

    systemd.services.languagetool = {
      after = ["network.target"];
      requires = ["network.target"];

      serviceConfig = {
        Type = lib.mkForce "exec";
        Restart = lib.mkForce "always";
        RestartSec = lib.mkForce "5s";

        RuntimeDirectory = lib.mkForce "languagetool";
        RuntimeDirectoryMode = lib.mkForce "0750";
        StateDirectory = lib.mkForce "languagetool";
        StateDirectoryMode = lib.mkForce "0750";

        # Security settings
        ProtectSystem = lib.mkForce "strict";
        ProtectHome = lib.mkForce "yes";
        PrivateTmp = lib.mkForce true;
        NoNewPrivileges = lib.mkForce true;

        # Environment setup
        WorkingDirectory = lib.mkForce "/var/lib/languagetool";
      };

      environment = {
        LANG = "en_US.UTF-8";
        LC_ALL = "en_US.UTF-8";
      };
    };

    # Create directory structure
    systemd.tmpfiles.rules = [
      "d /var/lib/languagetool 0750 languagetool languagetool -"
      "d /var/log/languagetool 0750 languagetool languagetool -"
    ];

    # Firewall configuration
    networking.firewall.allowedTCPPorts = [
      config.services.languagetool.port
    ];
  };
}
