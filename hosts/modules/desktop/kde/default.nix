# ~/NixOS/hosts/modules/desktop/kde/default.nix
{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.modules.desktop;
in {
  config = mkIf (cfg.enable && cfg.environment == "kde") {
    # Enable X server
    services.xserver.enable = true;

    # Display Manager configuration
    services.displayManager = {
      enable = true;
      defaultSession = "plasma";
      autoLogin = mkIf cfg.autoLogin.enable {
        enable = true;
        user = cfg.autoLogin.user;
      };
      sddm = {
        enable = true;
        settings = {
          Theme = {
            CursorTheme = "breeze_cursors";
            Font = "Noto Sans";
          };
          General = {
            InputMethod = "";
            Numlock = "on";
          };
        };
      };
    };

    # Desktop Manager configuration
    services.xserver.desktopManager.plasma5.enable = true;

    # Session variables for Plasma (adjusted for X11)
    environment.sessionVariables = {
      XDG_SESSION_TYPE = "x11";
      XDG_CURRENT_DESKTOP = "KDE";
      XDG_SESSION_DESKTOP = "KDE";
      KDE_FULL_SESSION = "true";
    };

    # Core environment packages
    environment.systemPackages = with pkgs; let
      plasma5 = pkgs.plasma5Packages;
    in [
      # X11 support
      xorg.xorgserver
      pkgs.xrandr

      # Core KDE packages
      plasma5.plasma-workspace
      plasma5.plasma-desktop
      plasma5.plasma-framework
      plasma5.kactivities
      plasma5.kactivities-stats

      # Power management
      plasma5.powerdevil
      power-profiles-daemon
      acpi
      acpid
      powertop

      # Online accounts and integration
      pkgs.kaccounts-integration
      pkgs.kaccounts-providers
      gnome-keyring
      pkgs.kio
      pkgs.kio-extras
      pkgs.kwallet-pam

      # System settings and info
      plasma5.plasma-systemmonitor
      plasma5.kinfocenter
      plasma5.ksystemstats
      plasma5.kgamma5
      plasma5.sddm-kcm
      plasma5.kauth
      plasma5.polkit-kde-agent

      # Core applications
      pkgs.dolphin
      pkgs.konsole
      pkgs.kate
      pkgs.ark
      pkgs.spectacle
      pkgs.okular
      pkgs.kdegraphics-thumbnailers
      pkgs.ffmpegthumbs
      pkgs.kimageformats

      # Plasma addons and integration
      plasma5.plasma-browser-integration
      plasma5.kdeplasma-addons
      plasma5.kscreen
      plasma5.plasma-nm
      plasma5.plasma-vault
      plasma5.plasma-pa
      pkgs.kdeconnect

      # Theming
      plasma5.breeze
      plasma5.breeze-gtk
      plasma5.breeze-icons

      # Additional utilities
      xdg-utils
      shared-mime-info
    ];

    # Adjust other services accordingly
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      pulse.enable = true;
      jack.enable = true;
      wireplumber.enable = true;
    };

    # Required services
    services = {
      power-profiles-daemon.enable = true;
      acpid.enable = true;
      udisks2.enable = true;
      gvfs.enable = true;
      accounts-daemon.enable = true;
      upower = {
        enable = true;
        percentageLow = 15;
        percentageCritical = 5;
        percentageAction = 3;
      };
    };

    # Security and system features
    security = {
      polkit.enable = true;
      rtkit.enable = true;
      pam = {
        services = {
          sddm.enableGnomeKeyring = true;
          login.enableGnomeKeyring = true;
        };
      };
    };

    # Enable GNOME Keyring service
    services.gnome.gnome-keyring.enable = true;

    # KDE Connect firewall rules
    networking.firewall = {
      allowedTCPPortRanges = [
        {
          from = 1714;
          to = 1764;
        }
      ];
      allowedUDPPortRanges = [
        {
          from = 1714;
          to = 1764;
        }
      ];
    };

    # System-wide KDE configuration
    qt = {
      enable = true;
      platformTheme = "kde";
      style = "breeze";
    };

    # Fonts
    fonts.packages = with pkgs; [
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-emoji
      liberation_ttf
      fira-code
      fira-code-symbols
      (nerdfonts.override {fonts = ["JetBrainsMono"];})
    ];

    # Enable required features
    hardware.bluetooth = {
      enable = true;
      powerOnBoot = true;
    };

    # Ensure dconf is enabled
    programs.dconf.enable = true;

    # Add home-manager configuration for Dolphin service
    home-manager.users.${cfg.autoLogin.user} = {
      systemd.user.services.dolphin = {
        Unit = {
          Description = "Dolphin File Manager";
          PartOf = ["plasma-core.target"];
          After = [
            "plasma-core.target"
            "dbus.socket"
            "graphical-session-pre.target"
          ];
          Requires = [
            "dbus.socket"
            "plasma-core.target"
          ];
        };
        Service = {
          Type = "simple";
          Environment = [
            "PATH=/run/current-system/sw/bin:$HOME/.nix-profile/bin:/etc/profiles/per-user/$USER/bin:/run/current-system/sw/bin"
            "DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/%U/bus"
            "KDE_SESSION_VERSION=5"
            "KDE_FULL_SESSION=true"
            "DESKTOP_SESSION=plasma"
            "XDG_CURRENT_DESKTOP=KDE"
            "XDG_SESSION_DESKTOP=plasma"
            "XDG_SESSION_TYPE=x11"
          ];
          ExecStart = "${pkgs.dolphin}/bin/dolphin --daemon";
          ExecStop = "${pkgs.util-linux}/bin/kill -TERM $MAINPID";
          Restart = "always";
          RestartSec = "1";
          TimeoutStopSec = "5";
        };
        Install = {
          WantedBy = ["plasma-core.target"];
        };
      };

      # Add service target for KDE Plasma
      systemd.user.targets.plasma-core = {
        Unit = {
          Description = "KDE Plasma Core Services";
          Requires = ["graphical-session-pre.target"];
          BindsTo = ["graphical-session.target"];
          Before = ["graphical-session.target"];
        };
      };
    };
  };
}
