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
    # Basic X server and KDE configuration
    services = {
      xserver.enable = true;
      desktopManager.plasma6.enable = true;
      displayManager = {
        sddm = {
          enable = true;
          wayland.enable = true;
        };
        autoLogin = mkIf cfg.autoLogin.enable {
          enable = true;
          user = cfg.autoLogin.user;
        };
      };
    };

    # Session variables for Wayland/KDE
    environment.sessionVariables = {
      NIXOS_OZONE_WL = "1";
      WLR_NO_HARDWARE_CURSORS = "1";
      XDG_SESSION_TYPE = "wayland";
      XDG_CURRENT_DESKTOP = "KDE";
      XDG_SESSION_DESKTOP = "KDE";
      GDK_BACKEND = "wayland,x11";
      QT_QPA_PLATFORM = "wayland;xcb";
      QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
      SDL_VIDEODRIVER = "wayland";
      CLUTTER_BACKEND = "wayland";
      MOZ_ENABLE_WAYLAND = "1";
    };

    # Core environment packages
    environment.systemPackages = with pkgs; [
      wayland
      xwayland
      qt6.qtwayland

      # KDE specific packages
      kdePackages.dolphin
      kdePackages.konsole
      kdePackages.kate
      kdePackages.ark
      kdePackages.spectacle
      kdePackages.okular
      kdePackages.plasma-systemmonitor
      kdePackages.plasma-nm
      kdePackages.plasma-vault
      kdePackages.plasma-workspace
      kdePackages.kdeconnect-kde

      # XDG portals
      xdg-desktop-portal-kde
      xdg-utils
    ];

    # XDG portal configuration
    xdg.portal = {
      enable = true;
      extraPortals = [
        pkgs.xdg-desktop-portal-kde
        pkgs.xdg-desktop-portal-gtk
      ];
      config = {
        common.default = ["kde" "gtk"];
      };
    };

    # Audio configuration
    services.pipewire = {
      enable = true;
      alsa = {
        enable = true;
        support32Bit = true;
      };
      pulse.enable = true;
      jack.enable = true;
    };

    # Required services
    services = {
      power-profiles-daemon.enable = true;
      udisks2.enable = true;
      accounts-daemon.enable = true;
      upower.enable = true;
    };

    # Security and system features
    security.polkit.enable = true;
    security.rtkit.enable = true;

    # System-wide KDE configuration
    qt = {
      enable = true;
      platformTheme = "kde";
      style = "breeze";
    };

    # Flatpak support
    services.flatpak.enable = true;

    # Fonts
    fonts.packages = with pkgs; [
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-emoji
      liberation_ttf
      (nerdfonts.override {fonts = ["JetBrainsMono"];})
    ];

    # Increase download buffer size to fix warning
    nix.settings.download-buffer-size = 128 * 1024 * 1024; # Set to 128 MiB
  };
}
