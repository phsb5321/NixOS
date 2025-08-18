# NixOS Desktop Configuration - Unified and Organized
# Combines all working configurations with proper module structure
{
  pkgs,
  lib,
  hostname,
  ...
}: let
  # Configuration variants for different scenarios
  variants = {
    # Normal operation with hardware acceleration
    hardware = {
      kernelParams = [
        "amdgpu.runpm=0" # Disable runtime power management (prevents flickering)
        "amdgpu.dpm=1" # Enable dynamic power management
        "amdgpu.dc=1" # Enable display core
        "consoleblank=0" # Disable console blanking
        "rd.systemd.show_status=true"
        "quiet"
      ];
      videoDrivers = ["amdgpu"];
      enableHardwareAccel = true;
    };

    # Conservative fallback for GPU issues
    conservative = {
      kernelParams = [
        "amdgpu.runpm=0"
        "amdgpu.dpm=1"
        "amdgpu.dc=1"
        "consoleblank=0"
        "rd.systemd.show_status=true"
      ];
      videoDrivers = ["amdgpu"];
      enableHardwareAccel = true;
      forceTearFree = true;
    };

    # Emergency software rendering fallback
    software = {
      kernelParams = [
        "nomodeset"
        "amdgpu.modeset=0"
        "radeon.modeset=0"
        "video=1024x768@60"
        "consoleblank=0"
        "iommu=soft"
      ];
      videoDrivers = [
        "vesa"
        "fbdev"
      ];
      enableHardwareAccel = false;
      blacklistModules = [
        "amdgpu"
        "radeon"
        "nouveau"
      ];
    };
  };

  # Select active variant (change this to switch modes)
  activeVariant = variants.hardware; # Change to: conservative, software
in {
  imports = [
    ./hardware-configuration.nix
    ../../modules
    ../shared/common.nix
  ];

  # Host-specific metadata
  modules.networking.hostName = lib.mkForce hostname;

  # Conditional boot configuration based on variant
  boot = {
    # Use LTS kernel for maximum stability
    kernelPackages = pkgs.linuxPackages_6_6;

    # Dynamic kernel parameters based on variant
    kernelParams = activeVariant.kernelParams;

    # Conditional kernel module handling
    initrd.kernelModules =
      if activeVariant.enableHardwareAccel
      then ["amdgpu"]
      else [];
    kernelModules =
      if activeVariant.enableHardwareAccel
      then [
        "kvm-intel"
        "amdgpu"
      ]
      else [];
    blacklistedKernelModules = activeVariant.blacklistModules or [];

    # Temporary filesystem in RAM for better performance
    tmp.useTmpfs = true;
  };

  # Hardware configuration - conditional based on variant
  hardware = {
    graphics = lib.mkIf activeVariant.enableHardwareAccel {
      enable = true;
      extraPackages = with pkgs; [amdvlk];
      extraPackages32 = with pkgs; [driversi686Linux.amdvlk];
    };
    cpu.intel.updateMicrocode = true;
  };

  # X11 server configuration for compatibility (Wayland is primary)
  services.xserver = {
    enable = true;
    videoDrivers = lib.mkForce activeVariant.videoDrivers;
    # X11 config only needed for software rendering fallback
    config = lib.mkIf (!activeVariant.enableHardwareAccel) ''
      Section "Device"
        Identifier "Software Graphics"
        Driver "vesa"
        Option "AccelMethod" "none"
        Option "ShadowFB" "true"
      EndSection

      Section "Screen"
        Identifier "Software Screen"
        DefaultDepth 24
        SubSection "Display"
          Depth 24
          Modes "1024x768" "800x600"
        EndSubSection
      EndSection
    '';
  };

  # Modern NixOS 25.11 display manager and desktop environment configuration
  services.displayManager.gdm = {
    enable = true;
    # Enable Wayland by default for better performance with AMD GPU
    wayland = lib.mkIf activeVariant.enableHardwareAccel true;
  };

  services.desktopManager.gnome = {
    enable = lib.mkForce true;
  };

  # System tray support for GNOME
  services.udev.packages = with pkgs; [
    gnome-settings-daemon
  ];

  # Environment variables for optimal GNOME experience
  environment = {
    variables = lib.mkMerge [
      # Software rendering fallback
      (lib.mkIf (!activeVariant.enableHardwareAccel) {
        "LIBGL_ALWAYS_SOFTWARE" = "1";
        "MESA_LOADER_DRIVER_OVERRIDE" = "swrast";
        "GALLIUM_DRIVER" = "llvmpipe";
        "GSK_RENDERER" = "cairo";
        "GDK_BACKEND" = "x11";
        "QT_XCB_GL_INTEGRATION" = "none";
      })

      # Hardware acceleration with Wayland optimizations
      (lib.mkIf activeVariant.enableHardwareAccel {
        "MOZ_ENABLE_WAYLAND" = "1";
        "QT_QPA_PLATFORM" = "wayland;xcb";
        "SDL_VIDEODRIVER" = "wayland";
        "CLUTTER_BACKEND" = "wayland";
        "GDK_BACKEND" = "wayland,x11";
        "AMD_VULKAN_ICD" = "RADV";
        "RADV_PERFTEST" = "gpl";
        # Firefox dark mode support
        "MOZ_USE_XINPUT2" = "1";
        "MOZ_WEBRENDER" = "1";
      })

      # Common environment variables for all scenarios
      {
        "GTK_THEME" = lib.mkForce "Arc-Dark";
      }
    ];

    # Session variables for all users
    sessionVariables = {
      NIXOS_OZONE_WL = "1"; # Enable Wayland for Electron apps
      XCURSOR_THEME = "Bibata-Modern-Ice";
      XCURSOR_SIZE = "24";
      # Force beautiful dark theme for all GTK applications
      GTK_THEME = "Arc-Dark";
      GTK2_RC_FILES = "${pkgs.arc-theme}/share/themes/Arc-Dark/gtk-2.0/gtkrc";
      # Qt theming to match GNOME
      QT_QPA_PLATFORMTHEME = "gnome";
      # Firefox preferences for dark mode
      MOZ_GTK_TITLEBAR_DECORATION = "client";
      MOZ_ENABLE_WAYLAND = "1";
      # GNOME theming variables
      GNOME_DESKTOP_INTERFACE_GTK_THEME = "Arc-Dark";
      GNOME_DESKTOP_INTERFACE_ICON_THEME = "Papirus-Dark";
      GNOME_DESKTOP_INTERFACE_CURSOR_THEME = "Bibata-Modern-Ice";
      # Color scheme
      GNOME_DESKTOP_INTERFACE_COLOR_SCHEME = "prefer-dark";
      # Additional theming
      GTK_USE_PORTAL = "1";
      GSETTINGS_SCHEMA_DIR = "${pkgs.gsettings-desktop-schemas}/share/gsettings-schemas/${pkgs.gsettings-desktop-schemas.name}/glib-2.0/schemas:${pkgs.gtk3}/share/gsettings-schemas/${pkgs.gtk3.name}/glib-2.0/schemas";
    };
  };

  # SystemD service for AMD GPU optimization (only when hardware accel enabled)
  systemd.services.amd-gpu-optimization = lib.mkIf activeVariant.enableHardwareAccel {
    description = "AMD GPU Performance Optimization";
    after = ["graphical-session.target"];
    wantedBy = ["multi-user.target"];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = pkgs.writeShellScript "amd-gpu-optimization" ''
        # Set performance level based on variant
        ${
          if activeVariant == variants.conservative
          then ''
            echo "high" > /sys/class/drm/card0/device/power_dpm_force_performance_level 2>/dev/null || true
            echo "1" > /sys/class/drm/card0/device/pp_power_profile_mode 2>/dev/null || true
          ''
          else ''
            echo "auto" > /sys/class/drm/card0/device/power_dpm_force_performance_level 2>/dev/null || true
            echo "1" > /sys/class/drm/card0/device/power_dpm_state 2>/dev/null || true
          ''
        }
      '';
    };
  };

  # Input device management
  services.libinput = {
    enable = true;
    mouse = {
      accelProfile = "adaptive";
      accelSpeed = "0";
    };
    touchpad = {
      accelProfile = "adaptive";
      accelSpeed = "0";
      tapping = true;
      naturalScrolling = false;
    };
  };

  # Host-specific user groups (additional to shared config)
  users.groups.plugdev = {};
  users.users.notroot.extraGroups = [
    "dialout" # Serial device access for development
    "libvirtd" # Virtualization access
    "plugdev" # USB device access
    "input" # Input device access
  ];

  # Host-specific desktop packages (essential for GNOME desktop functionality)
  environment.systemPackages = with pkgs;
    [
      # GPU-specific tools for AMD hardware debugging
      vulkan-tools
      vulkan-loader
      vulkan-validation-layers
      libva-utils
      vdpauinfo
      glxinfo
      mesa-demos
      clinfo
      radeontop

      # Essential development tools for desktop host
      gcc
      gnumake
      python3
      nodejs

      # System monitoring
      neofetch
      lm_sensors

      # Critical session management and input handling
      gnome-session
      xorg.xf86inputlibinput
      libinput
      evtest

      # System tray integration
      gnomeExtensions.appindicator

      # GNOME theming and appearance packages
      adwaita-icon-theme
      gnome-themes-extra
      gtk-engine-murrine
      gsettings-desktop-schemas

      # Font packages for proper theming
      cantarell-fonts
      source-code-pro
      noto-fonts
      noto-fonts-emoji

      # Cursor themes
      adwaita-icon-theme

      # GTK and Qt theming tools
      libsForQt5.qtstyleplugin-kvantum
      libsForQt5.qt5ct
      adwaita-qt
      adwaita-qt6

      # GNOME wallpapers and theme support
      gnome-backgrounds
      gnome-themes-extra
      vanilla-dmz

      # Premium GTK Themes
      arc-theme
      orchis-theme
      whitesur-gtk-theme
      nordic
      graphite-gtk-theme
      catppuccin-gtk
      yaru-theme
      materia-theme
      pop-gtk-theme

      # Beautiful Icon Themes
      papirus-icon-theme
      tela-icon-theme
      whitesur-icon-theme
      nordzy-icon-theme
      catppuccin-papirus-folders
      numix-icon-theme
      fluent-icon-theme

      # Modern Cursor Themes
      bibata-cursors
      nordzy-cursor-theme
      catppuccin-cursors
      volantes-cursors

      # Additional theming components
      hicolor-icon-theme
      gtk-engine-murrine
      gtk_engines
      sassc # Required for compiling some themes
    ]
    ++ lib.optionals (!activeVariant.enableHardwareAccel) [
      # Essential packages for software rendering mode
      firefox
      gnome-text-editor
      gnome-terminal
      nano
      htop
    ];

  # Enable modules based on hardware capabilities
  modules.packages.gaming.enable = lib.mkDefault activeVariant.enableHardwareAccel;
  modules.core.java = {
    enable = true;
    androidTools.enable = activeVariant.enableHardwareAccel;
  };

  # Document tools
  modules.core.documentTools = {
    enable = true;
    latex = {
      enable = activeVariant.enableHardwareAccel;
      minimal = false;
      extraPackages = lib.optionals activeVariant.enableHardwareAccel (
        with pkgs; [
          biber
          texlive.combined.scheme-context
        ]
      );
    };
    markdown = {
      enable = true;
      lsp = true;
      linting = {
        enable = true;
        markdownlint = true;
        vale = {
          enable = true;
          styles = ["google" "write-good"];
        };
        linkCheck = true;
      };
      formatting = {
        enable = true;
        mdformat = true;
        prettier = false;
      };
      preview = {
        enable = true;
        glow = true;
        grip = false;
      };
      utilities = {
        enable = true;
        doctoc = true;
        mdbook = activeVariant.enableHardwareAccel;
        mermaid = true;
      };
    };
  };

  # Host-specific extra packages (desktop-specific applications)
  modules.packages.extraPackages = with pkgs;
    lib.optionals activeVariant.enableHardwareAccel [
      # Development tools
      calibre
      anydesk
      postman
      dbeaver-bin
      android-studio
      android-tools

      # Media and Graphics (GPU-accelerated)
      gimp
      inkscape
      blender
      krita
      kdePackages.kdenlive
      obs-studio

      # Music streaming
      spotify
      spot
      ncspot

      # Communication
      telegram-desktop
      vesktop
      slack
      zoom-us

      # Gaming
      steam
      lutris
      wine
      winetricks

      # Productivity
      obsidian
      notion-app-enhanced

      # System monitoring
      htop
      btop
      iotop
      atop
      smem
      numactl
      stress-ng
      memtester

      # Memory analysis
      valgrind
      heaptrack
      massif-visualizer

      # Disk utilities
      ncdu
      duf

      # Process management
      psmisc
      lsof

      # Development
      gh
      git-crypt
      gnupg
      ripgrep
      fd
      jq
      yq
      unzip
      zip
      p7zip

      # Fonts
      nerd-fonts.jetbrains-mono
      noto-fonts-emoji
      noto-fonts
      noto-fonts-cjk-sans
    ];

  # Host-specific network configuration
  modules.networking.firewall.openPorts = [3000]; # Development server port

  # Programs (conditional)
  programs.steam = lib.mkIf activeVariant.enableHardwareAccel {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
  };

  # Security and sudo access
  security = {
    sudo.extraRules = [
      {
        groups = ["wheel"];
        commands = [
          {
            command = "${pkgs.corectrl}/bin/corectrl";
            options = ["NOPASSWD"];
          }
        ];
      }
    ];

    auditd.enable = activeVariant.enableHardwareAccel;
    audit = lib.mkIf activeVariant.enableHardwareAccel {
      enable = true;
      backlogLimit = 8192;
      failureMode = "printk";
      rules = ["-a exit,always -F arch=b64 -S execve"];
    };

    apparmor = lib.mkIf activeVariant.enableHardwareAccel {
      enable = true;
      killUnconfinedConfinables = true;
    };
  };

  # Audio configuration is handled by core modules (pipewire.nix and monitor-audio.nix)
  # No host-specific audio overrides needed

  # GNOME-optimized services configuration
  services.power-profiles-daemon.enable = lib.mkDefault true;
  services.thermald.enable = lib.mkDefault false; # Conflicts with power-profiles-daemon
  services.tlp.enable = lib.mkForce false; # Use power-profiles-daemon instead

  # Additional GNOME services
  services.gnome = {
    localsearch.enable = lib.mkDefault true; # Renamed from tracker-miners
    tinysparql.enable = lib.mkDefault true; # Renamed from tracker
    gnome-browser-connector.enable = lib.mkDefault true;
    gnome-keyring.enable = lib.mkDefault true;
    gnome-settings-daemon.enable = lib.mkDefault true;
    evolution-data-server.enable = lib.mkDefault true;
    glib-networking.enable = lib.mkDefault true;
    sushi.enable = lib.mkDefault true; # File previews in Nautilus
  };

  # Hardware integration for GNOME
  hardware.sensor.iio.enable = lib.mkDefault true; # For automatic screen rotation

  # Additional GNOME hardware support
  services.geoclue2.enable = lib.mkDefault true; # Location services
  services.upower.enable = lib.mkDefault true; # Battery/power management

  # Printing support
  services.printing = {
    enable = lib.mkDefault true;
    drivers = with pkgs; [
      gutenprint
      hplip
      epson-escpr
    ];
  };

  # Network discovery for printers
  services.avahi = {
    enable = lib.mkDefault true;
    nssmdns4 = lib.mkDefault true;
    openFirewall = lib.mkDefault true;
  };

  # GNOME-specific dconf configuration for optimal desktop experience
  programs.dconf.profiles.user.databases = [
    {
      lockAll = false;
      settings = {
        "org/gnome/shell" = {
          enabled-extensions = [
            "dash-to-dock@micxgx.gmail.com"
            "user-theme@gnome-shell-extensions.gcampax.github.com"
            "just-perfection-desktop@just-perfection"
            "Vitals@CoreCoding.com"
            "caffeine@patapon.info"
            "appindicatorsupport@rgcjonas.gmail.com"
            "blur-my-shell@aunetx"
            "clipboard-indicator@tudmotu.com"
            "gsconnect@andyholmes.github.io"
            "workspace-indicator@gnome-shell-extensions.gcampax.github.com"
            "sound-output-device-chooser@kgshank.net"
          ];
          favorite-apps = [
            "org.gnome.Nautilus.desktop"
            "firefox.desktop"
            "org.gnome.Terminal.desktop"
            "org.gnome.TextEditor.desktop"
          ];
        };

        # Experimental GNOME features
        "org/gnome/mutter" = {
          experimental-features = [
            "scale-monitor-framebuffer"
            "variable-refresh-rate"
            "xwayland-native-scaling"
          ];
          edge-tiling = true;
          dynamic-workspaces = true;
          workspaces-only-on-primary = true;
          center-new-windows = false;
        };

        # GNOME Interface and Theming - Multiple Options Available
        "org/gnome/desktop/interface" = {
          color-scheme = "prefer-dark";
          accent-color = "blue";
          # Beautiful theme options (change as desired):
          # gtk-theme = "Arc-Dark";           # Modern flat design
          # gtk-theme = "Orchis-Dark";        # macOS-like elegance
          # gtk-theme = "WhiteSur-Dark";      # Premium macOS look
          # gtk-theme = "Nordic-darker";      # Nordic minimalism
          # gtk-theme = "Graphite-dark";      # Material design
          # gtk-theme = "Catppuccin-Mocha";   # Pastel colors
          gtk-theme = "Arc-Dark";

          # Icon theme options (change as desired):
          # icon-theme = "Papirus-Dark";      # Material design icons
          # icon-theme = "Tela-dark";         # Rounded modern icons
          # icon-theme = "WhiteSur-dark";     # macOS-style icons
          # icon-theme = "Nordzy-dark";       # Nordic-themed icons
          # icon-theme = "Fluent-dark";       # Microsoft Fluent icons
          icon-theme = "Papirus-Dark";

          # Cursor theme options (change as desired):
          # cursor-theme = "Bibata-Modern-Ice";    # Modern animated
          # cursor-theme = "Nordzy-cursors";       # Nordic style
          # cursor-theme = "Catppuccin-Mocha-Dark"; # Pastel cursors
          # cursor-theme = "Volantes";             # Elegant cursors
          cursor-theme = "Bibata-Modern-Ice";

          cursor-size = lib.gvariant.mkInt32 24;
          font-name = "Cantarell 11";
          document-font-name = "Cantarell 11";
          monospace-font-name = "Source Code Pro 10";
          font-antialiasing = "grayscale";
          font-hinting = "slight";
          text-scaling-factor = lib.gvariant.mkDouble 1.0;
          enable-animations = lib.gvariant.mkBoolean (
            if activeVariant.enableHardwareAccel
            then true
            else false
          );
          enable-hot-corners = lib.gvariant.mkBoolean false;
          show-battery-percentage = true;
          clock-show-weekday = true;
          clock-show-seconds = false;
          locate-pointer = true;
          gtk-enable-primary-paste = true;
          overlay-scrolling = true;
          gtk-key-theme = "Default";
        };

        # Enhanced color and theming settings
        "org/gnome/desktop/background" = {
          color-shading-type = "solid";
          picture-options = "zoom";
          picture-uri = "file://${pkgs.gnome-backgrounds}/share/backgrounds/gnome/adwaita-l.webp";
          picture-uri-dark = "file://${pkgs.gnome-backgrounds}/share/backgrounds/gnome/adwaita-d.webp";
          primary-color = "#3071AE";
          secondary-color = "#000000";
        };

        # GTK theme settings

        # GNOME Shell theme (requires user-theme extension)
        "org/gnome/shell/extensions/user-theme" = {
          # Shell theme options (change as desired):
          # name = "Arc-Dark";           # Matches Arc GTK theme
          # name = "Orchis-Dark";        # Matches Orchis GTK theme
          # name = "WhiteSur-Dark";      # Matches WhiteSur GTK theme
          # name = "Nordic-darker";      # Matches Nordic GTK theme
          # name = "Graphite-dark";      # Matches Graphite GTK theme
          name = "Arc-Dark";
        };

        # Enhanced window decorations
        "org/gnome/desktop/wm/preferences" = {
          button-layout = "appmenu:minimize,maximize,close";
          theme = "Arc-Dark"; # Should match GTK theme
          titlebar-font = "Cantarell Bold 11";
          resize-with-right-button = true;
          mouse-button-modifier = "<Super>";
          focus-mode = "click";
          auto-raise = false;
          raise-on-click = true;
        };

        # File manager (Nautilus) enhancements
        "org/gnome/nautilus/preferences" = {
          default-folder-viewer = "list-view";
          search-filter-time-type = "last_modified";
          show-hidden-files = false;
          show-image-thumbnails = "always";
          click-policy = "double";
          executable-text-activation = "ask";
          show-create-link = true;
          show-delete-permanently = true;
        };

        # Enhanced file manager appearance
        "org/gnome/nautilus/list-view" = {
          default-column-order = ["name" "size" "type" "owner" "group" "permissions" "where" "date_modified" "date_modified_with_time" "recency"];
          default-visible-columns = ["name" "size" "date_modified"];
          use-tree-view = false;
        };

        # Sound theme
        "org/gnome/desktop/sound" = {
          theme-name = "freedesktop";
          event-sounds = true;
          input-feedback-sounds = false;
        };

        # Power Management
        "org/gnome/settings-daemon/plugins/power" = {
          sleep-inactive-ac-type = "nothing";
          sleep-inactive-battery-type = "suspend";
          power-button-action = "interactive";
        };

        # Session and Screen Lock
        "org/gnome/desktop/session" = {
          idle-delay = lib.gvariant.mkUint32 900;
        };

        "org/gnome/desktop/screensaver" = {
          lock-enabled = lib.gvariant.mkBoolean true;
          lock-delay = lib.gvariant.mkUint32 0;
        };

        # GNOME Terminal theming
        "org/gnome/terminal/legacy/profiles:/:b1dcc9dd-5262-4d8d-a863-c897e6d979b9" = {
          background-color = "rgb(23,20,33)";
          foreground-color = "rgb(208,207,204)";
          use-theme-colors = false;
          palette = [
            "rgb(23,20,33)"
            "rgb(192,28,40)"
            "rgb(38,162,105)"
            "rgb(162,115,76)"
            "rgb(18,72,139)"
            "rgb(163,71,186)"
            "rgb(42,161,179)"
            "rgb(208,207,204)"
            "rgb(94,92,100)"
            "rgb(246,97,81)"
            "rgb(51,209,122)"
            "rgb(233,173,12)"
            "rgb(42,123,222)"
            "rgb(192,97,203)"
            "rgb(51,199,222)"
            "rgb(255,255,255)"
          ];
        };

        # Dash to Dock configuration
        "org/gnome/shell/extensions/dash-to-dock" = {
          dock-position = "BOTTOM";
          extend-height = false;
          dock-fixed = false;
          autohide = true;
          intellihide = true;
          show-apps-at-top = true;
        };

        # Just Perfection configuration
        "org/gnome/shell/extensions/just-perfection" = {
          panel-in-overview = true;
          activities-button = true;
          app-menu = false;
          clock-menu = true;
          keyboard-layout = true;
        };

        # Blur My Shell configuration
        "org/gnome/shell/extensions/blur-my-shell" = {
          brightness = lib.gvariant.mkDouble 0.75;
          noise-amount = lib.gvariant.mkInt32 0;
        };

        # Input sources
        "org/gnome/desktop/input-sources" = {
          sources = [["xkb" "br+abnt2"]];
          xkb-options = ["grp:alt_shift_toggle" "compose:ralt"];
        };

        # Window management keybindings
        "org/gnome/desktop/wm/keybindings" = {
          maximize = ["<Super>Up"];
          unmaximize = ["<Super>Down" "<Alt>F5"];
          toggle-maximized = ["<Alt>F10"];
          minimize = ["<Super>h"];
          move-to-workspace-left = ["<Super><Shift>Left"];
          move-to-workspace-right = ["<Super><Shift>Right"];
          switch-to-workspace-left = ["<Super>Left"];
          switch-to-workspace-right = ["<Super>Right"];
        };

        # Privacy settings
        "org/gnome/desktop/privacy" = {
          report-technical-problems = false;
          send-software-usage-stats = false;
        };

        # Search settings
        "org/gnome/desktop/search-providers" = {
          disable-external = false;
        };
      };
    }
  ];

  # Qt theming integration for GNOME
  qt = {
    enable = true;
    platformTheme = "gnome";
    style = lib.mkForce "adwaita-dark";
  };

  # Font configuration for GNOME
  fonts = {
    packages = with pkgs; [
      cantarell-fonts
      source-code-pro
      noto-fonts
      noto-fonts-emoji
    ];
    fontconfig = {
      defaultFonts = {
        serif = ["Noto Serif"];
        sansSerif = ["Cantarell"];
        monospace = ["Source Code Pro"];
        emoji = ["Noto Color Emoji"];
      };
      hinting.enable = true;
      antialias = true;
    };
  };

  # Optional services (disabled by default for this desktop)
  services.ollama.enable = lib.mkDefault false;
  services.tailscale.enable = lib.mkDefault false;

  # System state version
  system.stateVersion = "25.11";
}
