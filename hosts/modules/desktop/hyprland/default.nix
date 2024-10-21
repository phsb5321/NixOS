{ config, lib, pkgs, inputs, ... }:

with lib;

let
  cfg = config.modules.desktop;
  mod = "ALT"; # Changed from SUPER to ALT for better VM compatibility
in
{
  imports = [
    ./waybar.nix
    ./dunst.nix
  ];

  options.modules.desktop = {
    enable = mkEnableOption "Desktop environment";
    environment = mkOption {
      type = types.enum [ "hyprland" ];
      default = "hyprland";
      description = "The desktop environment to use";
    };
    autoLogin = {
      enable = mkEnableOption "Automatic login";
      user = mkOption {
        type = types.str;
        description = "The user to automatically log in";
      };
    };
  };

  config = mkIf (cfg.enable && cfg.environment == "hyprland") {
    # System-level Hyprland configuration
    programs.hyprland = {
      enable = true;
      xwayland.enable = true;
    };

    # Reintroduce greetd configuration
    services.greetd = {
      enable = true;
      settings = {
        default_session = {
          command = "${pkgs.greetd.tuigreet}/bin/tuigreet --time --cmd Hyprland";
          user = "greeter";
        };
      };
    };

    environment.sessionVariables = {
      NIXOS_OZONE_WL = "1";
      WLR_NO_HARDWARE_CURSORS = "1";
      XDG_SESSION_TYPE = "wayland";
      XDG_CURRENT_DESKTOP = "Hyprland";
      XDG_SESSION_DESKTOP = "Hyprland";
      GDK_BACKEND = "wayland,x11";
      QT_QPA_PLATFORM = "wayland;xcb";
      SDL_VIDEODRIVER = "wayland";
      CLUTTER_BACKEND = "wayland";
    };

    hardware.graphics.enable = true;

    environment.systemPackages = with pkgs; [
      waybar
      wofi
      swww
      grim
      slurp
      wl-clipboard
      dunst
      libnotify
      swaylock-effects
      wlogout
      hyprpaper
      xdg-desktop-portal-hyprland
      xdg-utils
      polkit-kde-agent
      networkmanagerapplet
      kitty
      firefox
      brightnessctl
      pamixer
    ];

    xdg.portal = {
      enable = true;
      wlr.enable = true;
      extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
    };

    security.pam.services.swaylock = { };

    fonts.packages = with pkgs; [
      (nerdfonts.override { fonts = [ "JetBrainsMono" "FiraCode" "DroidSansMono" ]; })
    ];

    # Enable Waybar and Dunst modules
    modules.waybar.enable = true;
    modules.dunst.enable = true;

    # Home Manager configuration for Hyprland
    home-manager.users.${cfg.autoLogin.user} = { pkgs, ... }: {
      imports = [
        inputs.hyprland.homeManagerModules.default
      ];

      wayland.windowManager.hyprland = {
        enable = true;
        systemd.enable = true;
        xwayland.enable = true;

        settings = {
          monitor = ",preferred,auto,1";

          "$mod" = "ALT";
          "$terminal" = "kitty";
          "$menu" = "wofi --show drun --show-icons";
          "$browser" = "firefox";

          env = "XCURSOR_SIZE,24";

          input = {
            kb_layout = "br";
            follow_mouse = 1;
            touchpad.natural_scroll = true;
            sensitivity = 0;
          };

          general = {
            gaps_in = 5;
            gaps_out = 5;
            border_size = 2;
            "col.active_border" = "rgba(33ccffee) rgba(00ff99ee) 45deg";
            "col.inactive_border" = "rgba(595959aa)";
            layout = "dwindle";
          };

          decoration = {
            rounding = 10;
            drop_shadow = true;
            shadow_range = 4;
            shadow_render_power = 3;
            "col.shadow" = "rgba(1a1a1aee)";
          };

          animations = {
            enabled = true;
            bezier = "myBezier, 0.05, 0.9, 0.1, 1.05";
            animation = [
              "windows, 1, 7, myBezier"
              "windowsOut, 1, 7, default, popin 80%"
              "border, 1, 10, default"
              "borderangle, 1, 8, default"
              "fade, 1, 7, default"
              "workspaces, 1, 6, default"
            ];
          };

          dwindle = {
            pseudotile = true;
            preserve_split = true;
          };

          gestures.workspace_swipe = true;

          # Example keybinds
          bind = [
            "$mod, RETURN, exec, $terminal"
            "$mod, Q, killactive"
            "$mod, M, exit"
            "$mod, E, exec, $fileManager"
            "$mod, V, togglefloating"
            "$mod, R, exec, $menu"
            "$mod, P, pseudo"
            "$mod, J, togglesplit"
            "$mod, left, movefocus, l"
            "$mod, right, movefocus, r"
            "$mod, up, movefocus, u"
            "$mod, down, movefocus, d"
          ] ++ (
            # Workspaces
            builtins.concatLists (builtins.genList
              (
                x:
                let
                  ws =
                    let
                      c = (x + 1) / 10;
                    in
                    builtins.toString (x + 1 - (c * 10));
                in
                [
                  "$mod, ${ws}, workspace, ${toString (x + 1)}"
                  "$mod SHIFT, ${ws}, movetoworkspace, ${toString (x + 1)}"
                ]
              ) 10)
          );

          bindm = [
            "$mod, mouse:272, movewindow"
            "$mod, mouse:273, resizewindow"
          ];

          exec-once = "waybar & hyprpaper & dunst";
        };
      };
    };
  };
}
