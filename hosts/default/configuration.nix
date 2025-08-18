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
    wayland = true;
  };

  services.desktopManager.gnome = {
    enable = true;
  };

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
        "MOZ_USE_XINPUT2" = "1";
        "MOZ_WEBRENDER" = "1";
      })
    ];

    # Session variables for theming and functionality
    sessionVariables = {
      NIXOS_OZONE_WL = "1";
      XDG_SESSION_TYPE = "wayland";
      
      # Theme variables
      GTK_THEME = "Arc-Dark";
      XCURSOR_THEME = "Bibata-Modern-Ice";
      XCURSOR_SIZE = "24";
      
      # Qt integration
      QT_QPA_PLATFORMTHEME = "gnome";
      QT_STYLE_OVERRIDE = "adwaita-dark";
      
      # Wayland support for applications
      MOZ_ENABLE_WAYLAND = "1";
      ELECTRON_OZONE_PLATFORM_HINT = "wayland";
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

      # Essential GNOME packages
      gnome-session
      gnome-settings-daemon
      gnome-control-center
      gnome-tweaks

      # GNOME Extensions
      gnomeExtensions.appindicator
      gnomeExtensions.dash-to-dock
      gnomeExtensions.user-themes
      gnomeExtensions.just-perfection
      gnomeExtensions.vitals
      gnomeExtensions.caffeine
      gnomeExtensions.clipboard-indicator
      gnomeExtensions.gsconnect
      gnomeExtensions.workspace-indicator
      gnomeExtensions.sound-output-device-chooser

      # Theme packages
      arc-theme
      papirus-icon-theme
      bibata-cursors
      adwaita-icon-theme
      gnome-themes-extra
      gtk-engine-murrine
      
      # Essential GNOME applications
      gnome-terminal
      gnome-text-editor
      nautilus
      firefox
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

  # Comprehensive GNOME services
  services.gnome = {
    gnome-keyring.enable = true;
    gnome-settings-daemon.enable = true;
    evolution-data-server.enable = true;
    glib-networking.enable = true;
    sushi.enable = true; # File previews in Nautilus
    tinysparql.enable = true; # Search indexing
  };

  # Additional services for GNOME functionality
  services.geoclue2.enable = true; # Location services
  services.upower.enable = true; # Power management

  # GNOME dconf configuration
  programs.dconf.profiles.user.databases = [
    {
      lockAll = false;
      settings = {
        # Enable extensions
        "org/gnome/shell" = {
          enabled-extensions = [
            "dash-to-dock@micxgx.gmail.com"
            "user-theme@gnome-shell-extensions.gcampax.github.com"
            "just-perfection-desktop@just-perfection"
            "appindicatorsupport@rgcjonas.gmail.com"
            "workspace-indicator@gnome-shell-extensions.gcampax.github.com"
            "Vitals@CoreCoding.com"
            "caffeine@patapon.info"
            "clipboard-indicator@tudmotu.com"
            "gsconnect@andyholmes.github.io"
            "sound-output-device-chooser@kgshank.net"
          ];
          favorite-apps = [
            "org.gnome.Nautilus.desktop"
            "firefox.desktop"
            "org.gnome.Terminal.desktop"
            "org.gnome.TextEditor.desktop"
          ];
        };

        # Interface theming
        "org/gnome/desktop/interface" = {
          color-scheme = "prefer-dark";
          gtk-theme = "Arc-Dark";
          icon-theme = "Papirus-Dark";
          cursor-theme = "Bibata-Modern-Ice";
          cursor-size = lib.gvariant.mkInt32 24;
          font-name = "Cantarell 11";
          document-font-name = "Cantarell 11";
          monospace-font-name = "Source Code Pro 10";
          enable-animations = true;
          enable-hot-corners = false;
          show-battery-percentage = true;
          clock-show-weekday = true;
        };

        # Mutter window manager settings
        "org/gnome/mutter" = {
          edge-tiling = true;
          dynamic-workspaces = true;
          workspaces-only-on-primary = false;
          center-new-windows = true;
        };

        # Window manager preferences
        "org/gnome/desktop/wm/preferences" = {
          button-layout = "appmenu:minimize,maximize,close";
          theme = "Arc-Dark";
          titlebar-font = "Cantarell Bold 11";
          focus-mode = "click";
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

        # User theme extension
        "org/gnome/shell/extensions/user-theme" = {
          name = "Arc-Dark";
        };

        # Privacy settings
        "org/gnome/desktop/privacy" = {
          report-technical-problems = false;
          send-software-usage-stats = false;
        };

        # Session settings
        "org/gnome/desktop/session" = {
          idle-delay = lib.gvariant.mkUint32 900;
        };

        # Power settings
        "org/gnome/settings-daemon/plugins/power" = {
          sleep-inactive-ac-type = "nothing";
          sleep-inactive-battery-type = "suspend";
          power-button-action = "interactive";
        };
      };
    }
  ];

  # Qt theming integration
  qt = {
    enable = true;
    platformTheme = "gnome";
    style = "adwaita-dark";
  };

  # Enhanced font configuration
  fonts = {
    packages = with pkgs; [
      cantarell-fonts
      source-code-pro
      noto-fonts
      noto-fonts-emoji
      noto-fonts-cjk-sans
      nerd-fonts.jetbrains-mono
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
