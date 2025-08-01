# ~/NixOS/hosts/shared/common.nix
{
  pkgs,
  lib,
  systemVersion,
  ...
}: {
  # Shared configuration for desktop hosts

  # Enable shared packages
  modules.packages = {
    enable = true;
    browsers.enable = true;
    development.enable = true;
    media.enable = true;
    utilities.enable = true;
    audioVideo.enable = true;
    terminal.enable = true;
    python = {
      enable = true;
      withGTK = true;
    };
  };

  # Enable dotfiles management
  modules.dotfiles = {
    enable = true;
    enableHelperScripts = true;
  };

  # Core configuration
  modules.core = {
    enable = true;
    stateVersion = systemVersion;
    timeZone = "America/Recife";
    defaultLocale = "en_US.UTF-8";
    extraSystemPackages = with pkgs; [
      # Basic system utilities
      blueman
      pciutils
      usbutils
      speechd

      # Shared GNOME applications for all hosts
      gnome-text-editor
      gnome-calculator
      gnome-calendar
      gnome-contacts
      gnome-maps
      gnome-weather
      gnome-music
      gnome-photos
      simple-scan
      seahorse # Keyring management

      # GNOME utilities
      gnome-tweaks
      gnome-extension-manager
      dconf-editor

      # File management
      file-roller # Archive manager

      # Multimedia
      celluloid # Modern video player

      # Essential GNOME extensions - Core functionality
      gnomeExtensions.dash-to-dock
      gnomeExtensions.user-themes
      gnomeExtensions.just-perfection

      # System monitoring extensions - Multiple options for comprehensive monitoring
      gnomeExtensions.vitals # Temperature, voltage, fan speed, memory, CPU, network, storage
      gnomeExtensions.system-monitor-next # Classic system monitor with graphs
      gnomeExtensions.tophat # Elegant system resource monitor
      gnomeExtensions.resource-monitor # Real-time monitoring in top bar

      # Productivity and customization extensions
      gnomeExtensions.caffeine # Prevent screen lock
      gnomeExtensions.appindicator # System tray support
      gnomeExtensions.blur-my-shell # Blur effects for shell elements
      gnomeExtensions.clipboard-indicator # Clipboard manager
      gnomeExtensions.night-theme-switcher # Automatic dark/light theme switching
      gnomeExtensions.gsconnect # Phone integration (KDE Connect)

      # Workspace and window management
      gnomeExtensions.workspace-indicator # Better workspace indicator
      gnomeExtensions.advanced-alttab-window-switcher # Enhanced Alt+Tab

      # Quick access and navigation
      gnomeExtensions.places-status-indicator # Quick access to bookmarks
      gnomeExtensions.removable-drive-menu # USB drive management
      gnomeExtensions.sound-output-device-chooser # Audio device switching

      # Visual enhancements
      gnomeExtensions.weather-or-not # Weather in top panel

      # Additional useful extensions
      gnomeExtensions.clipboard-history # Enhanced clipboard manager
      gnomeExtensions.panel-workspace-scroll # Scroll on panel to switch workspaces

      # Recently requested extensions
      gnomeExtensions.runcat # Cat animation showing CPU usage
      gnomeExtensions.launch-new-instance # Always launch new app instances
      gnomeExtensions.auto-move-windows # Remember window positions per workspace
      gnomeExtensions.lock-keys # Show Caps Lock and Num Lock status

      # Essential system packages for desktop functionality
      xdg-utils
      glib
      gsettings-desktop-schemas
    ];
  };

  # Desktop environment configuration moved to individual hosts
  # Each host now configures its own desktop environment based on GPU requirements

  # Networking configuration
  modules.networking = {
    enable = true;
    hostName = lib.mkDefault "nixos";
    optimizeTCP = true;
    enableNetworkManager = true;
    dns = {
      enableSystemdResolved = true;
      enableDNSOverTLS = true;
      primaryProvider = "cloudflare";
    };
    firewall = {
      enable = true;
      allowPing = true;
      openPorts = [22];
      trustedInterfaces = [];
    };
  };

  # Console configuration
  console = {
    font = "Lat2-Terminus16";
    useXkbConfig = true;
  };

  # Keyboard configuration
  services.xserver.xkb = {
    layout = "br";
    variant = ",abnt2";
    options = "grp:alt_shift_toggle,compose:ralt";
  };

  # Input method
  i18n.inputMethod = {
    enable = true;
    type = "ibus";
  };

  # GNOME keyboard integration
  services.desktopManager.gnome.extraGSettingsOverrides = ''
    [org.gnome.desktop.input-sources]
    sources=[('xkb', 'br+abnt2')]
    xkb-options=['grp:alt_shift_toggle', 'compose:ralt']

    [org.gnome.desktop.peripherals.keyboard]
    numlock-state=true
    remember-numlock-state=true

    [org.gnome.desktop.interface]
    show-battery-percentage=true
  '';

  # GNOME services configuration - shared across all GNOME hosts
  services.gnome = {
    core-shell.enable = lib.mkDefault true;
    core-os-services.enable = lib.mkDefault true;
    core-apps.enable = lib.mkDefault true;
    gnome-keyring.enable = lib.mkDefault true;
    gnome-settings-daemon.enable = lib.mkDefault true;
    evolution-data-server.enable = lib.mkDefault true;
    glib-networking.enable = lib.mkDefault true;
    sushi.enable = lib.mkDefault true;
    gnome-remote-desktop.enable = lib.mkForce false;
    gnome-user-share.enable = lib.mkDefault true;
    rygel.enable = lib.mkDefault true;
  };

  # Essential services for GNOME - shared configuration
  services.geoclue2.enable = lib.mkDefault true;
  services.upower.enable = lib.mkDefault true;
  services.power-profiles-daemon.enable = lib.mkDefault true;

  services.desktopManager.gnome.extraGSettingsOverridePackages = [
    pkgs.gsettings-desktop-schemas
    pkgs.gnome-settings-daemon
  ];

  # Locale settings
  i18n = {
    defaultLocale = "en_US.UTF-8";
    extraLocaleSettings = {
      LC_ADDRESS = "pt_BR.UTF-8";
      LC_IDENTIFICATION = "pt_BR.UTF-8";
      LC_MEASUREMENT = "pt_BR.UTF-8";
      LC_MONETARY = "pt_BR.UTF-8";
      LC_NAME = "pt_BR.UTF-8";
      LC_NUMERIC = "pt_BR.UTF-8";
      LC_PAPER = "pt_BR.UTF-8";
      LC_TELEPHONE = "pt_BR.UTF-8";
      LC_TIME = "pt_BR.UTF-8";
    };
  };

  # Boot parameters
  boot.kernelParams = [
    "consoleblank=0"
    "rd.systemd.show_status=true"
  ];

  # Environment variables
  environment.variables = {
    EDITOR = "nvim";
    SHELL = "${pkgs.zsh}/bin/zsh";
  };

  # GNOME-specific environment variables - shared configuration
  environment.sessionVariables = {
    # UI and theming for GNOME
    XCURSOR_THEME = lib.mkDefault "Adwaita";
    XCURSOR_SIZE = lib.mkDefault "24";
    GSK_RENDERER = lib.mkDefault "gl";
    GNOME_SHELL_SLOWDOWN_FACTOR = lib.mkDefault "1";
    GNOME_SHELL_DISABLE_HARDWARE_ACCELERATION = lib.mkDefault "0";
  };

  # User configuration
  users = {
    defaultUserShell = pkgs.zsh;
    users.notroot = {
      isNormalUser = true;
      description = "Pedro Balbino";
      extraGroups = [
        "networkmanager"
        "wheel"
        "audio"
        "video"
        "disk"
        "input"
        "bluetooth"
        "docker"
        "render"
        "kvm"
        "pipewire"
      ];
    };
  };

  # Hardware configuration
  hardware = {
    enableRedistributableFirmware = true;
    bluetooth = {
      enable = true;
      powerOnBoot = true;
      disabledPlugins = ["sap"];
      settings = {
        General = {
          AutoEnable = "true";
          ControllerMode = "dual";
          Experimental = "true";
        };
      };
    };
    graphics = {
      enable = true;
      enable32Bit = true;
    };
  };

  # GNOME hardware support - shared configuration
  services.blueman.enable = lib.mkDefault true;
  services.printing.enable = lib.mkDefault true;
  services.printing.drivers = lib.mkDefault (
    with pkgs; [
      gutenprint
      hplip
      epson-escpr
    ]
  );
  services.avahi = {
    enable = lib.mkDefault true;
    nssmdns4 = lib.mkDefault true;
    openFirewall = lib.mkDefault true;
  };

  # Services
  services = {
    # Audio system - comprehensive PipeWire setup for GNOME
    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      wireplumber.enable = true;
      jack.enable = true;
    };
    pulseaudio.enable = false;

    syncthing = {
      enable = true;
      user = "notroot";
      dataDir = "/home/notroot/Sync";
      configDir = "/home/notroot/.config/syncthing";
      overrideDevices = true;
      overrideFolders = true;
    };

    openssh = {
      enable = true;
      settings = {
        PermitRootLogin = "no";
        PasswordAuthentication = true;
        KbdInteractiveAuthentication = false;
      };
    };

    fstrim.enable = true;
    thermald.enable = true;
  };

  # Programs
  programs = {
    zsh.enable = true;
    nix-ld.enable = true;
    dconf.enable = true;
    thunderbird.enable = true;
  };

  # Enable and configure GNOME extensions via dconf
  programs.dconf.profiles.user.databases = [
    {
      settings = {
        "org/gnome/shell" = {
          enabled-extensions = [
            # Core functionality extensions
            "dash-to-dock@micxgx.gmail.com"
            "user-theme@gnome-shell-extensions.gcampax.github.com"
            "just-perfection-desktop@just-perfection"

            # System monitoring extensions
            "Vitals@CoreCoding.com"
            "system-monitor-next@paradoxxx.zero.gmail.com"
            "tophat@fflewddur.github.io"
            "Resource_Monitor@Ory0n"

            # Productivity and customization extensions
            "caffeine@patapon.info"
            "appindicatorsupport@rgcjonas.gmail.com"
            "blur-my-shell@aunetx"
            "clipboard-indicator@tudmotu.com"
            "nightthemeswitcher@romainvigier.fr"
            "gsconnect@andyholmes.github.io"

            # Workspace and window management
            "workspace-indicator@gnome-shell-extensions.gcampax.github.com"
            "advanced-alt-tab@G-dH.github.com"

            # Quick access and navigation
            "places-menu@gnome-shell-extensions.gcampax.github.com"
            "drive-menu@gnome-shell-extensions.gcampax.github.com"
            "sound-output-device-chooser@kgshank.net"

            # Visual enhancements
            "weatherornot@somepaulo.github.io"

            # Additional useful extensions
            "clipboard-history@alexsaveau.dev"
            "panel-workspace-scroll@polymeilex.github.io"
            
            # Recently requested extensions
            "runcat@kolesnikov.se"
            "launch-new-instance@gnome-shell-extensions.gcampax.github.com"
            "auto-move-windows@gnome-shell-extensions.gcampax.github.com"
            "lockkeys@vaina.lt"
          ];
        };
      };
    }
  ];

  # Security
  security = {
    sudo.wheelNeedsPassword = true;
    polkit.enable = true;
    rtkit.enable = true;
  };
}
