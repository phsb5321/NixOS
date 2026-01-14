# Server Host - GNOME Configuration
# Proxmox VM X11 setup optimized for VirtIO-GPU
{
  config,
  lib,
  ...
}: {
  # Enable GNOME with X11 for VM compatibility
  modules.desktop.gnome = {
    enable = true;
    wayland.enable = false; # X11 for Proxmox VM compatibility

    # GNOME Core Apps - Minimal Suite for server
    # Only essential tools: system monitor, console, logs, disk utility, papers
    coreApps = {
      enable = true;
      fullSuite = false; # Minimal set (disables productivity, media, scanner, connections)
      utilities.enable = false; # No calculator, clocks, weather
      media.enable = false; # No camera, video player, image viewer
      productivity.enable = false; # No calendar, contacts, maps
      documents = {
        enable = true;
        viewer = true; # Papers PDF viewer
        scanner = false; # No scanner hardware on server
      };
      systemTools = {
        enable = true;
        systemMonitor = true;
        logs = true;
        console = true;
        help = true;
        connections = false; # No remote desktop client needed
        dconfEditor = true;
      };
      fileManagement = {
        enable = true;
        diskAnalyzer = true; # Baobab
        diskUtility = true;
      };
    };

    # Minimal extensions for server use
    extensions = {
      enable = true;
      appIndicator = true;
      dashToDock = true;
      userThemes = false; # Not needed for server
      justPerfection = true;
      vitals = true; # Useful for monitoring server
      caffeine = true;
      clipboard = false; # Not needed for server
      gsconnect = false; # Not needed for server
      workspaceIndicator = true;
      soundOutputChooser = false; # Not needed for server
    };
  };

  # Complete dconf configuration for server
  programs.dconf.profiles.user.databases = [
    {
      lockAll = false;
      settings = {
        # Enabled extensions list
        "org/gnome/shell" = {
          enabled-extensions = [
            "appindicatorsupport@rgcjonas.gmail.com"
            "dash-to-dock@micxgx.gmail.com"
            "just-perfection-desktop@just-perfection"
            "Vitals@CoreCoding.com"
            "caffeine@patapon.info"
            "workspace-indicator@gnome-shell-extensions.gcampax.github.com"
          ];
          favorite-apps = [
            "org.gnome.Nautilus.desktop"
            "firefox.desktop"
            "org.gnome.Terminal.desktop"
            "org.gnome.TextEditor.desktop"
          ];
        };

        # Interface settings - simple for VM
        "org/gnome/desktop/interface" = {
          color-scheme = "prefer-dark";
          icon-theme = config.modules.desktop.gnome.theme.iconTheme;
          cursor-theme = config.modules.desktop.gnome.theme.cursorTheme;
          cursor-size = lib.gvariant.mkInt32 24;
          font-name = "Cantarell 11";
          document-font-name = "Cantarell 11";
          monospace-font-name = "Source Code Pro 10";
          enable-animations = false; # Disable for VM performance
          enable-hot-corners = false;
          show-battery-percentage = false; # No battery on server
          clock-show-weekday = true;
          clock-show-seconds = false;
          locate-pointer = true;
        };

        # Mutter settings - VM optimized
        "org/gnome/mutter" = {
          edge-tiling = true;
          dynamic-workspaces = false; # Fixed workspaces for server
          workspaces-only-on-primary = true;
          center-new-windows = true;
          experimental-features = lib.gvariant.mkEmptyArray lib.gvariant.type.string;
          dynamic-triple-buffering = false;
        };

        # Window manager preferences
        "org/gnome/desktop/wm/preferences" = {
          button-layout = "appmenu:minimize,maximize,close";
          titlebar-font = "Cantarell Bold 11";
          focus-mode = "click";
          num-workspaces = lib.gvariant.mkInt32 2; # Fixed workspaces
        };

        # Input configuration
        "org/gnome/desktop/peripherals/keyboard" = {
          numlock-state = true;
          remember-numlock-state = true;
        };

        # Privacy settings
        "org/gnome/desktop/privacy" = {
          report-technical-problems = false;
          send-software-usage-stats = false;
        };

        # Session idle settings - never idle for server
        "org/gnome/desktop/session" = {
          idle-delay = lib.gvariant.mkUint32 0; # Never idle
        };

        # Power settings - server (always on)
        "org/gnome/settings-daemon/plugins/power" = {
          sleep-inactive-ac-type = "nothing"; # Never sleep
          sleep-inactive-battery-type = "nothing";
          power-button-action = "nothing"; # Ignore power button
          idle-dim = false;
        };

        # Search settings
        "org/gnome/desktop/search-providers" = {
          disable-external = false;
        };
      };
    }
  ];

  # JUSTIFIED: Override GSK_RENDERER for Proxmox VM (let GTK auto-detect llvmpipe)
  # Other hosts set specific renderers; server needs auto-detection for VirtIO-GPU
  environment.sessionVariables = {
    GSK_RENDERER = lib.mkForce "";
  };

  # Security configuration for GNOME
  security.pam.services = {
    gdm.enableGnomeKeyring = true;
    gdm-password.enableGnomeKeyring = true;
  };

  # GNOME login fixes (NixOS Wiki solution for session registration failures)
  systemd.services."getty@tty1".enable = false;
  systemd.services."autovt@tty1".enable = false;
}
