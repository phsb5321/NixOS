# /home/notroot/NixOS/hosts/modules/desktop/hyprland/default.nix
{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
with lib; let
  cfg = config.modules.desktop;
in {
  imports = [
    ../options.nix
    ./ags.nix
    ./dunst.nix
  ];

  config = mkIf (cfg.enable && cfg.environment == "hyprland") {
    # System-level Hyprland configuration
    programs.hyprland = {
      enable = true;
      xwayland.enable = true;
    };

    # Display manager configuration (corrected paths)
    services = {
      xserver.enable = true;
      displayManager = {
        sddm = {
          enable = true;
          wayland.enable = true;
        };
        defaultSession = "hyprland";
      };
    };

    # Core system configuration
    security = {
      polkit.enable = true;
      rtkit.enable = true;
    };

    # Required packages
    environment.systemPackages = with pkgs; [
      kitty
      wofi
      networkmanagerapplet
      wl-clipboard
      grim
      slurp
      brightnessctl
      playerctl
      adwaita-icon-theme # Corrected package name
      ags
    ];

    # XDG portal configuration
    xdg.portal = {
      enable = true;
      extraPortals = [
        pkgs.xdg-desktop-portal-gtk
        pkgs.xdg-desktop-portal-hyprland
      ];
    };

    # Home manager configuration
    home-manager.users.${cfg.autoLogin.user} = {pkgs, ...}: {
      wayland.windowManager.hyprland = {
        enable = true;
        systemd.enable = true;
        xwayland.enable = true;

        settings = {
          "$mod" = "SUPER";
          "$terminal" = "kitty";
          "$menu" = "wofi --show drun";

          monitor = ",preferred,auto,1";

          general = {
            gaps_in = 4;
            gaps_out = 8;
            border_size = 2;
            "col.active_border" = "rgb(89b4fa)";
            "col.inactive_border" = "rgba(595959aa)";
            layout = "dwindle";
          };

          decoration = {
            rounding = 8;
            blur = {
              enabled = true;
              size = 3;
              passes = 1;
              new_optimizations = true;
            };
            drop_shadow = true;
            shadow_range = 4;
          };

          animations = {
            enabled = true;
            bezier = "myBezier, 0.05, 0.9, 0.1, 1.05";
            animation = [
              "windows, 1, 7, myBezier"
              "windowsOut, 1, 7, default, popin 80%"
              "border, 1, 10, default"
              "fade, 1, 7, default"
              "workspaces, 1, 6, default"
            ];
          };

          bind =
            [
              "$mod, RETURN, exec, $terminal"
              "$mod, Q, killactive"
              "$mod, M, exit"
              "$mod, V, togglefloating"
              "$mod, R, exec, $menu"
              "$mod, P, pseudo"
              "$mod, J, togglesplit"
              "$mod, left, movefocus, l"
              "$mod, right, movefocus, r"
              "$mod, up, movefocus, u"
              "$mod, down, movefocus, d"
            ]
            ++ (
              builtins.concatLists (builtins.genList (
                  x: let
                    ws = toString (x + 1);
                  in [
                    "$mod, ${ws}, workspace, ${ws}"
                    "$mod SHIFT, ${ws}, movetoworkspace, ${ws}"
                  ]
                )
                10)
            );

          bindm = [
            "$mod, mouse:272, movewindow"
            "$mod, mouse:273, resizewindow"
          ];

          # Essential autostart applications
          exec-once = [
            "systemctl --user import-environment PATH"
            "systemctl --user start ags.service" # Start AGS
            "${pkgs.polkit-kde-agent}/libexec/polkit-kde-authentication-agent-1"
            "nm-applet --indicator"
          ];
        };
      };
    };
  };
}
