# ~/NixOS/hosts/laptop/configuration.nix
# Independent laptop configuration without problematic shared module
{
  pkgs,
  lib,
  systemVersion,
  ...
}:
{
  imports = [
    ./hardware-configuration.nix
    ../../modules
  ];

  # Core system configuration
  modules.core = {
    enable = true;
    stateVersion = systemVersion;
    timeZone = "America/Recife";
    defaultLocale = "en_US.UTF-8";
  };

  # Simple desktop configuration - prefer X11 for stability on laptop
  modules.desktop = {
    enable = true;
    environment = "gnome";

    # Force X11 to avoid Wayland issues
    displayManager = {
      wayland = false;
      autoSuspend = true;
    };

    # Minimal theming to avoid conflicts
    theming = {
      preferDark = true;
      accentColor = "blue";
    };

    # Essential hardware support
    hardware = {
      enableTouchpad = true;
      enableBluetooth = true;
      enablePrinting = false; # Disable to reduce conflicts
      enableScanning = false;
    };

    # Auto-login for convenience
    autoLogin = {
      enable = true;
      user = "notroot";
    };
  };

  # Simple networking without aggressive optimizations
  modules.networking = {
    enable = true;
    hostName = "nixos-laptop";
    enableNetworkManager = true;
    firewall = {
      enable = true;
      allowPing = true;
      openPorts = [ 22 ];
    };
  };

  # Essential packages only - no gaming, minimal extras
  modules.packages = {
    enable = true;
    browsers.enable = true;
    development.enable = true;
    utilities.enable = true;
    terminal.enable = true;
    # Disable resource-heavy categories
    gaming.enable = false;
    media.enable = false;
    audioVideo.enable = false;
  };

  # Disable dotfiles to avoid conflicts
  modules.dotfiles.enable = false;

  # Force GNOME X11 session
  services.displayManager.defaultSession = lib.mkForce "gnome-xorg";

  # Override any Wayland environment variables
  environment.sessionVariables = {
    XDG_SESSION_TYPE = lib.mkForce "x11";
    WAYLAND_DISPLAY = lib.mkForce "";
    QT_QPA_PLATFORM = lib.mkForce "xcb";
    GDK_BACKEND = lib.mkForce "x11";
    SDL_VIDEODRIVER = lib.mkForce "x11";
    MOZ_ENABLE_WAYLAND = lib.mkForce "0";
    NIXOS_OZONE_WL = lib.mkForce "0";
  };

  # Simple console configuration
  console = {
    font = "Lat2-Terminus16";
    useXkbConfig = true;
  };

  # Basic keyboard configuration
  services.xserver.xkb = {
    layout = "br";
    variant = "abnt2";
    options = "grp:alt_shift_toggle";
  };

  # Basic locale settings
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
        "input"
        "bluetooth"
      ];
    };
  };

  # Laptop-specific packages
  environment.systemPackages = with pkgs; [
    # Laptop essentials
    powertop
    acpi
    brightnessctl

    # Basic tools
    firefox
    kitty
    git
    vim
    htop

    # GNOME utilities for extensions
    gnome-tweaks
    gnome-extension-manager
    dconf-editor

    # Essential GNOME extensions - Core requested ones
    gnomeExtensions.caffeine # Prevent sleep/screen lock
    gnomeExtensions.vitals # System monitoring (CPU, temp, memory, etc.)
    gnomeExtensions.forge # Tiling window manager
    gnomeExtensions.arc-menu # Application menu replacement
    gnomeExtensions.fuzzy-app-search # Better app search
    gnomeExtensions.launch-new-instance # Always launch new app instances
    gnomeExtensions.auto-move-windows # Remember window positions per workspace
    gnomeExtensions.clipboard-indicator # Clipboard history manager

    # Additional useful extensions for laptop
    gnomeExtensions.tophat # Elegant system resource monitor in top bar
    gnomeExtensions.appindicator # System tray support
    gnomeExtensions.dash-to-dock # Enhanced dock
    gnomeExtensions.blur-my-shell # Blur effects
    gnomeExtensions.gsconnect # Phone integration
    gnomeExtensions.workspace-indicator # Better workspace management
    gnomeExtensions.sound-output-device-chooser # Audio device switching
    gnomeExtensions.removable-drive-menu # USB drive management
    gnomeExtensions.battery-health-charging # Battery charge limiting
    gnomeExtensions.quick-settings-audio-panel # Audio quick settings
    gnomeExtensions.paperwm # Advanced tiling (alternative to forge)
    gnomeExtensions.pop-shell # Pop!_OS tiling features
    gnomeExtensions.places-status-indicator # Quick access to bookmarks
    gnomeExtensions.night-theme-switcher # Auto dark/light theme switching
    gnomeExtensions.battery-time # Show battery time remaining
    gnomeExtensions.user-themes # Theme support
    gnomeExtensions.just-perfection # Customize GNOME interface

    # Fun desktop extensions - The cat you requested!
    gnomeExtensions.runcat # Running cat in top bar shows CPU usage

    # System performance extensions
    gnomeExtensions.system-monitor-next # Classic system monitor with graphs
    gnomeExtensions.resource-monitor # Real-time monitoring in top bar

    # Productivity extensions
    gnomeExtensions.advanced-alttab-window-switcher # Enhanced Alt+Tab
    gnomeExtensions.clipboard-history # Enhanced clipboard manager
    gnomeExtensions.panel-workspace-scroll # Scroll on panel to switch workspaces
  ];

  # Basic hardware configuration
  hardware = {
    enableRedistributableFirmware = true;
    bluetooth = {
      enable = true;
      powerOnBoot = true;
    };
    graphics = {
      enable = true;
    };
  };

  # Audio configuration
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    pulse.enable = true;
  };
  services.pulseaudio.enable = lib.mkForce false;

  # Laptop-specific services
  services = {
    libinput.enable = true; # Touchpad support
    upower.enable = true; # Battery management
    thermald.enable = true;
    fstrim.enable = true;

    # Power management
    power-profiles-daemon.enable = true;

    # SSH
    openssh = {
      enable = true;
      settings = {
        PermitRootLogin = "no";
        PasswordAuthentication = true;
      };
    };
  };

  # Laptop power management
  services.logind = {
    lidSwitch = "suspend";
    lidSwitchExternalPower = "lock";
  };

  # Programs
  programs = {
    zsh.enable = true;
    dconf.enable = true;
  };

  # Bootloader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Security
  security = {
    sudo.wheelNeedsPassword = true;
    polkit.enable = true;
  };

  # GNOME autologin workaround
  systemd.services."getty@tty1".enable = false;
  systemd.services."autovt@tty1".enable = false;

  # Disable problematic overlays by ensuring clean nixpkgs
  nixpkgs.overlays = lib.mkForce [ ];
}
