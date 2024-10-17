{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.modules.desktop;
  mod = "ALT"; # Changed from SUPER to ALT for better VM compatibility
in {
  config = mkIf (cfg.enable && cfg.environment == "hyprland") {
    programs.hyprland = {
      enable = true;
      xwayland.enable = true;
      nvidiaPatches = true;
    };

    services.greetd = {
      enable = true;
      settings = {
        default_session = {
          command = "${pkgs.greetd.tuigreet}/bin/tuigreet --time --cmd Hyprland";
          user = "greeter";
        };
      } // (if cfg.autoLogin.enable then {
        initial_session = {
          command = "Hyprland";
          user = cfg.autoLogin.user;
        };
      } else { });
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

    environment.systemPackages = with pkgs; [
      waybar
      wofi
      swww
      grim
      slurp
      wl-clipboard
      mako # Keep mako in system packages
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

    # Add Home Manager configuration for Hyprland
    home-manager.users.${cfg.autoLogin.user} = { pkgs, ... }: {
      wayland.windowManager.hyprland = {
        enable = true;
        extraConfig = ''
          # ... (keep the existing Hyprland configuration)
        '';
      };

      # Add Mako configuration to Home Manager
      programs.mako = {
        enable = true;
        defaultTimeout = 5000;
        borderSize = 2;
        borderRadius = 5;
        backgroundColor = "#1e1e2e";
        textColor = "#cdd6f4";
        borderColor = "#89b4fa";
      };
    };
  };

    xdg.portal = {
      enable = true;
      wlr.enable = true;
      extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
    };

    security.pam.services.swaylock = {};

    fonts.packages = with pkgs; [
      (nerdfonts.override { fonts = [ "FiraCode" "DroidSansMono" ]; })
    ];

    programs.waybar = {
      enable = true;
      settings = [{
        layer = "top";
        position = "top";
        height = 30;
        modules-left = [ "hyprland/workspaces" "hyprland/mode" "hyprland/window" ];
        modules-center = [ "clock" ];
        modules-right = [ "pulseaudio" "network" "cpu" "memory" "temperature" "backlight" "battery" "tray" ];
      }];
    };

    programs.mako = {
      enable = true;
      defaultTimeout = 5000;
      borderSize = 2;
      borderRadius = 5;
      backgroundColor = "#1e1e2e";
      textColor = "#cdd6f4";
      borderColor = "#89b4fa";
    };

    # Add Home Manager configuration for Hyprland
    home-manager.users.${cfg.autoLogin.user} = { pkgs, ... }: {
      wayland.windowManager.hyprland = {
        enable = true;
        extraConfig = ''
          # Monitor configuration
          monitor=,preferred,auto,1

          # Set programs that you use
          $terminal = kitty
          $menu = wofi --show drun
          $browser = firefox

          # Some default env vars.
          env = XCURSOR_SIZE,24

          # For all categories, see https://wiki.hyprland.org/Configuring/Variables/
          input {
              kb_layout = br
              kb_variant =
              kb_model =
              kb_options =
              kb_rules =

              follow_mouse = 1

              touchpad {
                  natural_scroll = yes
              }

              sensitivity = 0 # -1.0 - 1.0, 0 means no modification.
          }

          general {
              gaps_in = 5
              gaps_out = 20
              border_size = 2
              col.active_border = rgba(33ccffee) rgba(00ff99ee) 45deg
              col.inactive_border = rgba(595959aa)

              layout = dwindle
          }

          decoration {
              rounding = 10
              blur = yes
              blur_size = 3
              blur_passes = 1
              blur_new_optimizations = on

              drop_shadow = yes
              shadow_range = 4
              shadow_render_power = 3
              col.shadow = rgba(1a1a1aee)
          }

          animations {
              enabled = yes

              bezier = myBezier, 0.05, 0.9, 0.1, 1.05

              animation = windows, 1, 7, myBezier
              animation = windowsOut, 1, 7, default, popin 80%
              animation = border, 1, 10, default
              animation = borderangle, 1, 8, default
              animation = fade, 1, 7, default
              animation = workspaces, 1, 6, default
          }

          dwindle {
              pseudotile = yes # master switch for pseudotiling
              preserve_split = yes # you probably want this
          }

          master {
              new_is_master = true
          }

          gestures {
              workspace_swipe = off
          }

          # Example windowrule v1
          # windowrule = float, ^(kitty)$
          # Example windowrule v2
          # windowrulev2 = float,class:^(kitty)$,title:^(kitty)$

          # See https://wiki.hyprland.org/Configuring/Keywords/ for more

          # Example binds, see https://wiki.hyprland.org/Configuring/Binds/ for more
          bind = ${mod}, RETURN, exec, $terminal
          bind = ${mod}, Q, killactive,
          bind = ${mod}, M, exit,
          bind = ${mod}, E, exec, $fileManager
          bind = ${mod}, V, togglefloating,
          bind = ${mod}, R, exec, $menu
          bind = ${mod}, P, pseudo, # dwindle
          bind = ${mod}, J, togglesplit, # dwindle

          # Move focus with mod + arrow keys
          bind = ${mod}, left, movefocus, l
          bind = ${mod}, right, movefocus, r
          bind = ${mod}, up, movefocus, u
          bind = ${mod}, down, movefocus, d

          # Switch workspaces with mod + [0-9]
          bind = ${mod}, 1, workspace, 1
          bind = ${mod}, 2, workspace, 2
          bind = ${mod}, 3, workspace, 3
          bind = ${mod}, 4, workspace, 4
          bind = ${mod}, 5, workspace, 5
          bind = ${mod}, 6, workspace, 6
          bind = ${mod}, 7, workspace, 7
          bind = ${mod}, 8, workspace, 8
          bind = ${mod}, 9, workspace, 9
          bind = ${mod}, 0, workspace, 10

          # Move active window to a workspace with mod + SHIFT + [0-9]
          bind = ${mod} SHIFT, 1, movetoworkspace, 1
          bind = ${mod} SHIFT, 2, movetoworkspace, 2
          bind = ${mod} SHIFT, 3, movetoworkspace, 3
          bind = ${mod} SHIFT, 4, movetoworkspace, 4
          bind = ${mod} SHIFT, 5, movetoworkspace, 5
          bind = ${mod} SHIFT, 6, movetoworkspace, 6
          bind = ${mod} SHIFT, 7, movetoworkspace, 7
          bind = ${mod} SHIFT, 8, movetoworkspace, 8
          bind = ${mod} SHIFT, 9, movetoworkspace, 9
          bind = ${mod} SHIFT, 0, movetoworkspace, 10

          # Scroll through existing workspaces with mod + scroll
          bind = ${mod}, mouse_down, workspace, e+1
          bind = ${mod}, mouse_up, workspace, e-1

          # Move/resize windows with mod + LMB/RMB and dragging
          bindm = ${mod}, mouse:272, movewindow
          bindm = ${mod}, mouse:273, resizewindow

          # Execute custom scripts
          exec-once = waybar & hyprpaper & mako
        '';
      };
    };
  };
}
