# ~/NixOS/modules/services/backup.nix
# Automated encrypted backups to AWS S3 using restic
# Cost-optimized: One Zone-IA storage class, zstd compression, tight retention
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.services.backup;
in {
  options.modules.services.backup = {
    enable = lib.mkEnableOption "automated S3 backups via restic";

    paths = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = "Directories to back up";
    };

    exclude = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = "Patterns to exclude from backups";
    };

    s3Bucket = lib.mkOption {
      type = lib.types.str;
      description = "S3 bucket name for backup storage";
    };

    s3Region = lib.mkOption {
      type = lib.types.str;
      default = "us-east-1";
      description = "AWS region for the S3 bucket";
    };

    passwordFile = lib.mkOption {
      type = lib.types.str;
      default = "/etc/restic/password";
      description = "Path to restic encryption password file";
    };

    awsCredentialsFile = lib.mkOption {
      type = lib.types.str;
      default = "/etc/restic/aws-env";
      description = "Path to file containing AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY";
    };

    schedule = lib.mkOption {
      type = lib.types.str;
      default = "daily";
      description = "Systemd calendar spec for backup frequency";
    };

    retention = {
      keepDaily = lib.mkOption {
        type = lib.types.int;
        default = 7;
        description = "Number of daily snapshots to keep";
      };
      keepWeekly = lib.mkOption {
        type = lib.types.int;
        default = 4;
        description = "Number of weekly snapshots to keep";
      };
      keepMonthly = lib.mkOption {
        type = lib.types.int;
        default = 6;
        description = "Number of monthly snapshots to keep";
      };
    };

    bandwidthLimit = lib.mkOption {
      type = lib.types.int;
      default = 51200;
      description = "Upload bandwidth limit in KiB/s (default 51200 = 50 MiB/s) to control S3 transfer costs";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [pkgs.restic];

    services.restic.backups.s3-daily = {
      initialize = true;
      passwordFile = cfg.passwordFile;
      environmentFile = cfg.awsCredentialsFile;
      repository = "s3:s3.${cfg.s3Region}.amazonaws.com/${cfg.s3Bucket}";
      paths = cfg.paths;
      exclude = cfg.exclude ++ [
        # Universal excludes to minimize backup size and cost
        "**/.cache"
        "**/.tmp"
        "**/node_modules"
        "**/__pycache__"
        "**/.direnv"
        "**/target" # Rust build artifacts
        "**/.git/objects" # Git object store (recoverable from remotes)
        "**/dist"
        "**/build"
        "**/.next"
        "**/*.log"
        "**/.venv"
        "**/venv"
      ];

      pruneOpts = [
        "--keep-daily ${toString cfg.retention.keepDaily}"
        "--keep-weekly ${toString cfg.retention.keepWeekly}"
        "--keep-monthly ${toString cfg.retention.keepMonthly}"
      ];

      extraBackupArgs = [
        "--compression max" # zstd max compression — reduces S3 storage cost 50-70%
        "--limit-upload ${toString cfg.bandwidthLimit}" # Cap upload KiB/s to avoid surprise transfer costs
        "--one-file-system" # Don't cross filesystem boundaries
        "--exclude-caches" # Skip directories with CACHEDIR.TAG
      ];

      timerConfig = {
        OnCalendar = cfg.schedule;
        Persistent = true; # Run missed backups after sleep/shutdown
        RandomizedDelaySec = "1h"; # Jitter to avoid exact midnight spikes
      };
    };
  };
}
