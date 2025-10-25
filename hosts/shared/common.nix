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

  # Enable shell configuration
  modules.shell = {
    enable = true;
    zsh = {
      enable = true;
      ohMyZsh.enable = true;
      powerlevel10k.enable = true;
      plugins = {
        autosuggestions = true;
        syntaxHighlighting = true;
        youShouldUse = true;
        fastSyntaxHighlighting = false;
      };
      modernTools = {
        enable = true;
        zoxide = true;
      };
    };
  };

  # Enable dotfiles management
  modules.dotfiles = {
    enable = true;
    enableHelperScripts = true;
  };

  # GNOME extensions are now configured directly in gnome.nix module
  # modules.desktop.gnomeExtensions.enable = true;  # Removed - integrated into gnome.nix

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

      # GNOME Extensions are now managed by the shared gnome-extensions module
      # Essential system packages for desktop functionality
      xdg-utils
      glib
      gsettings-desktop-schemas
    ];
  };

  # Desktop environment base configuration
  # Host-specific GNOME config is in individual host files

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
    gnome-user-share.enable = lib.mkForce false; # Disable for security: disables GNOME file sharing over network (WebDAV, Bluetooth). Re-enable if you need network file sharing.
    rygel.enable = lib.mkForce false; # Media sharing - disable by default
    tinysparql.enable = lib.mkDefault true; # File indexing (renamed from tracker)
    localsearch.enable = lib.mkDefault true; # File indexing miners (renamed from tracker-miners)
  };

  # Essential services for GNOME - shared configuration
  services.geoclue2.enable = lib.mkDefault true;
  services.upower.enable = lib.mkDefault true;
  # Power management is configured per-host based on hardware type

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

  # User configuration (shell is configured via shell module)
  users = {
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

  # Programs (shell programs configured via shell module)
  programs = {
    nix-ld.enable = true;
    dconf.enable = true;
    thunderbird.enable = true;
  };

  # Base GNOME dconf configuration - shared settings
  # Extension-specific configuration is handled in individual host files
  programs.dconf.profiles.user.databases = [
    {
      settings = {
        # Base GNOME interface settings
        "org/gnome/desktop/interface" = {
          show-battery-percentage = true;
          clock-show-weekday = true;
          clock-show-seconds = false;
          locate-pointer = true;
        };

        # Base input configuration
        "org/gnome/desktop/peripherals/keyboard" = {
          numlock-state = true;
          remember-numlock-state = true;
        };

        # Base privacy settings
        "org/gnome/desktop/privacy" = {
          report-technical-problems = false;
          send-software-usage-stats = false;
        };

        # Base search settings
        "org/gnome/desktop/search-providers" = {
          disable-external = false;
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
