# ~/NixOS/hosts/laptop/configuration.nix
{
  pkgs,
  systemVersion,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    ../../modules
    ../shared/common.nix
  ];

  # Core system configuration using modules
  modules.core = {
    enable = true;
    stateVersion = systemVersion;
    timeZone = "America/Recife";
    defaultLocale = "en_US.UTF-8";
  };

  # Networking configuration
  modules.networking = {
    enable = true;
    hostName = "nixos-laptop";
    enableNetworkManager = true;
    firewall = {
      enable = true;
      allowPing = true;
      openPorts = [22]; # SSH only for laptop
    };
  };

  # Package configuration - disable gaming to save battery
  modules.packages = {
    enable = true;
    browsers.enable = true;
    development.enable = true;
    utilities.enable = true;
    terminal.enable = true;
    media.enable = true;
    audioVideo.enable = true;
    gaming.enable = false; # Disabled for laptop to save battery

    # Laptop-specific extra packages
    extraPackages = with pkgs; [
      # Laptop-specific utilities
      powertop
      tlp
      acpi
      brightnessctl

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

      # Development tools for mobile work
      git
      vim
      curl
      wget
    ];
  };

  # Laptop-specific core module additions
  modules.core.documentTools = {
    enable = true;
    latex.enable = false; # Disabled for laptop to save space
  };

  # Enable explicit keyboard configuration for laptop (ABNT2)
  modules.core.keyboard = {
    enable = true;
    variant = ",abnt2";
  };

  # Simple NVIDIA GPU support for laptop
  services.xserver.videoDrivers = ["nvidia"];
  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = false;
    open = false;
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.stable;
    prime = {
      sync.enable = true;
      intelBusId = "PCI:0:2:0";
      nvidiaBusId = "PCI:1:0:0";
    };
  };

  # Direct GNOME configuration for NVIDIA GPU laptop
  # Force X11 session for NVIDIA GPU compatibility
  services.xserver.enable = true;

  # Display manager configuration for NVIDIA
  services.displayManager.gdm = {
    enable = true;
    wayland = false; # Force X11 only for NVIDIA
    autoSuspend = false; # Keep laptop awake
  };

  # Desktop manager configuration
  services.desktopManager.gnome.enable = true;

  # Auto-login for laptop convenience
  services.displayManager.autoLogin = {
    enable = true;
    user = "notroot";
  };

  # Ensure only GDM is enabled
  services.displayManager.sddm.enable = false;

  # GNOME services for laptop
  services.gnome = {
    core-shell.enable = true;
    core-os-services.enable = true;
    core-apps.enable = true;
    gnome-keyring.enable = true;
    gnome-settings-daemon.enable = true;
    evolution-data-server.enable = true;
    glib-networking.enable = true;
    sushi.enable = true;
    gnome-remote-desktop.enable = false;
    gnome-user-share.enable = true;
    rygel.enable = true;
    tinysparql.enable = false;
    localsearch.enable = false;
  };

  # Essential services for GNOME
  services.geoclue2.enable = true;
  services.upower.enable = true;
  services.power-profiles-daemon.enable = false; # Disabled for TLP
  services.thermald.enable = true;

  # Audio system
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    wireplumber.enable = true;
    jack.enable = true;
  };

  # Hardware support
  hardware.bluetooth.enable = true;
  services.blueman.enable = true;
  services.printing.enable = true;
  services.printing.drivers = with pkgs; [
    gutenprint
    hplip
    epson-escpr
  ];
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
  };

  # Laptop-specific power management
  services.tlp = {
    enable = true;
    settings = {
      CPU_SCALING_GOVERNOR_ON_AC = "performance";
      CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
    };
  };

  # Laptop power management
  services.logind = {
    lidSwitch = "suspend";
    lidSwitchExternalPower = "lock";
  };

  # Force X11 environment variables for NVIDIA laptop
  environment.sessionVariables = {
    # Force X11 session - no Wayland for NVIDIA
    XDG_SESSION_TYPE = "x11";
    GDK_BACKEND = "x11";
    QT_QPA_PLATFORM = "xcb";

    # Completely disable Wayland
    WAYLAND_DISPLAY = "";
    MOZ_ENABLE_WAYLAND = "0";
    # NIXOS_OZONE_WL unset to prevent VS Code from adding Wayland flags
    ELECTRON_OZONE_PLATFORM_HINT = "x11";

    # NVIDIA-specific settings
    __GL_SYNC_TO_VBLANK = "1";
    __GL_VRR_ALLOWED = "0";
    MUTTER_DEBUG_FORCE_KMS_MODE = "simple";
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";
    __VK_LAYER_NV_optimus = "NVIDIA_only";

    # UI and cursor
    XCURSOR_THEME = "Adwaita";
    XCURSOR_SIZE = "24";
    GSK_RENDERER = "gl";
    GNOME_SHELL_SLOWDOWN_FACTOR = "1";
    GNOME_SHELL_DISABLE_HARDWARE_ACCELERATION = "0";
  };

  # Force applications to use X11 - system-wide
  environment.etc."environment".text = ''
    XDG_SESSION_TYPE=x11
    GDK_BACKEND=x11
    QT_QPA_PLATFORM=xcb
    WAYLAND_DISPLAY=
    MOZ_ENABLE_WAYLAND=0
  '';

  # GNOME autologin workaround
  systemd.services."getty@tty1".enable = false;
  systemd.services."autovt@tty1".enable = false;

  # Force NVIDIA as primary GPU for GNOME
  services.xserver.screenSection = ''
    Option "metamodes" "nvidia-auto-select +0+0 {ForceFullCompositionPipeline=On}"
    Option "AllowIndirectGLXProtocol" "off"
    Option "TripleBuffer" "on"
  '';

  # Laptop-specific bootloader configuration
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
}
