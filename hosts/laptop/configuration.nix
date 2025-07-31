# ~/NixOS/hosts/laptop/configuration.nix
{
  config,
  pkgs,
  lib,
  inputs,
  hostname,
  systemVersion,
  pkgs-unstable,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    ../../modules
    ../shared/common.nix
  ];

  # Host-specific metadata
  networking.hostName = hostname;

  # Override shared configuration as needed
  modules.networking.hostName = hostname;
  # Note: Home Manager removed - packages are now managed at system level

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
  services.printing.drivers = with pkgs; [gutenprint hplip epson-escpr];
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
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
    NIXOS_OZONE_WL = "0";
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
    ELECTRON_OZONE_PLATFORM_HINT=x11
  '';

  # GNOME autologin workaround
  systemd.services."getty@tty1".enable = false;
  systemd.services."autovt@tty1".enable = false;

  # Laptop-specific core module additions
  modules.core.documentTools = {
    enable = true;
    latex.enable = false; # Disabled for laptop to save space
  };

  # Laptop-specific package preferences (disabled gaming to save battery)
  modules.packages.gaming.enable = false;

  # Laptop-specific extra packages
  modules.packages.extraPackages = with pkgs; [
    # Laptop-specific utilities
    powertop
    tlp

    # Development tools for mobile work
    git
    vim
    curl
    wget
  ];

  # Laptop-specific power management (handled above in GNOME section)
  services.tlp = {
    enable = true;
    settings = {
      CPU_SCALING_GOVERNOR_ON_AC = "performance";
      CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
    };
  };

  # Laptop-specific networking - no special ports needed
  modules.networking.firewall.openPorts = [22]; # SSH only

  # Enable explicit keyboard configuration for laptop (ABNT2)
  modules.core.keyboard = {
    enable = true;
    variant = ",abnt2";
  };

  # NVIDIA GPU configuration for laptop
  modules.hardware.nvidia = {
    enable = true;
    intelBusId = "PCI:0:2:0"; # Intel UHD Graphics
    nvidiaBusId = "PCI:1:0:0"; # GeForce GTX 1650 Mobile
    prime.mode = "sync"; # Use sync mode for better GNOME compatibility
    driver.version = "stable";
    driver.openSource = false; # Use proprietary drivers for GTX 1650
    powerManagement.enable = false; # Disabled for sync mode
    powerManagement.finegrained = false; # Disabled for sync mode
    performance.forceFullCompositionPipeline = true; # Reduce tearing
  };

  # Laptop-specific bootloader configuration
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Desktop configuration already handled above - NVIDIA specific services
  services.gnome.tinysparql.enable = false;
  services.gnome.localsearch.enable = false;

  # Additional laptop-specific NVIDIA fixes

  # Force NVIDIA as primary GPU for GNOME
  services.xserver.screenSection = ''
    Option "metamodes" "nvidia-auto-select +0+0 {ForceFullCompositionPipeline=On}"
    Option "AllowIndirectGLXProtocol" "off"
    Option "TripleBuffer" "on"
  '';
}
