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

  # Enable auto-login for laptop convenience
  modules.desktop.autoLogin = {
    enable = lib.mkForce true;
    user = "notroot";
  };

  # GNOME autologin workaround
  systemd.services."getty@tty1".enable = false;
  systemd.services."autovt@tty1".enable = false;

  # Laptop-specific core module additions
  modules.core.documentTools = {
    enable = true;
    latex = {
      enable = lib.mkForce false; # Disabled for laptop to save space
    };
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

  # Laptop-specific power management
  services.power-profiles-daemon.enable = lib.mkForce false; # Disable to use TLP instead
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
  modules.core.keyboard.enable = true;

  # Laptop-specific keyboard configuration - use ABNT2 variant
  services.xserver.xkb = {
    layout = "br";
    variant = lib.mkForce ",abnt2"; # Aligned with shared configuration
  };

  # Console keymap for laptop
  console.keyMap = lib.mkForce "br-abnt2";

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

  # --- GNOME FIXES ---
  # Override desktop module settings for laptop
  modules.desktop = {
    enable = lib.mkForce true;
    environment = lib.mkForce "gnome";
    displayManager = {
      wayland = lib.mkForce false; # Force X11 for NVIDIA compatibility
      autoSuspend = lib.mkForce false; # Disable auto-suspend for laptop
    };
  };

  # Force GNOME services to be enabled
  services.xserver = {
    enable = lib.mkForce true;
  };

  services.desktopManager.gnome.enable = lib.mkForce true;

  services.displayManager = {
    gdm = {
      enable = lib.mkForce true;
      wayland = lib.mkForce false; # Force X11 for NVIDIA compatibility
      autoSuspend = lib.mkForce false;
    };
    sddm.enable = lib.mkForce false;
  };

  # Ensure defaultSession is set to X11
  services.displayManager.defaultSession = lib.mkForce "gnome-xorg"; # Explicitly force X11 session
  services.gnome = {
    core-shell.enable = lib.mkForce true;
    core-os-services.enable = lib.mkForce true;
    core-apps.enable = lib.mkForce true;
    gnome-keyring.enable = lib.mkForce true;
    gnome-settings-daemon.enable = lib.mkForce true;
    evolution-data-server.enable = lib.mkForce true;
    glib-networking.enable = lib.mkForce true;
    sushi.enable = lib.mkForce true;
    gnome-remote-desktop.enable = lib.mkForce true;
    gnome-user-share.enable = lib.mkForce true;
    rygel.enable = lib.mkForce true;
  };
  security.rtkit.enable = lib.mkForce true;
  services.pipewire = {
    enable = lib.mkForce true;
    alsa.enable = lib.mkForce true;
    alsa.support32Bit = lib.mkForce true;
    pulse.enable = lib.mkForce true;
    wireplumber.enable = lib.mkForce true;
    jack.enable = lib.mkForce true;
  };
  environment.sessionVariables = {
    # Force X11 backend for all applications
    XDG_SESSION_TYPE = lib.mkForce "x11";
    GDK_BACKEND = lib.mkForce "x11";
    QT_QPA_PLATFORM = lib.mkForce "xcb";
    SDL_VIDEODRIVER = lib.mkForce "x11";
    CLUTTER_BACKEND = lib.mkForce "x11";

    # Disable Wayland for all applications
    WAYLAND_DISPLAY = lib.mkForce "";
    NIXOS_OZONE_WL = lib.mkForce "0";
    MOZ_ENABLE_WAYLAND = lib.mkForce "0";
    QT_WAYLAND_FORCE_DPI = lib.mkForce "";

    # GNOME X11 optimizations
    GSK_RENDERER = "gl";
    GNOME_SHELL_SLOWDOWN_FACTOR = "1";
    GNOME_SHELL_DISABLE_HARDWARE_ACCELERATION = "0";
    GNOME_WAYLAND = lib.mkForce "0";

    # NVIDIA-specific GNOME fixes
    __GL_SYNC_TO_VBLANK = "1";
    __GL_VRR_ALLOWED = "0";
    CLUTTER_PAINT = "disable-clipped-redraws:disable-culling";
    MUTTER_DEBUG_FORCE_KMS_MODE = "simple";
  };

  # Additional GNOME fixes
  programs.dconf.enable = lib.mkForce true;
  services.gvfs.enable = lib.mkForce true;
  services.udisks2.enable = lib.mkForce true;
  services.upower.enable = lib.mkForce true;
  services.accounts-daemon.enable = lib.mkForce true;
  services.gnome.at-spi2-core.enable = lib.mkForce true;

  # XDG desktop portal for GNOME
  xdg.portal = {
    enable = lib.mkForce true;
    extraPortals = lib.mkForce [pkgs.xdg-desktop-portal-gnome];
    config.common.default = lib.mkForce "gnome";
  };

  # Additional X11 enforcement and NVIDIA fixes
  hardware.graphics = {
    enable = lib.mkForce true;
    enable32Bit = lib.mkForce true;
  };

  # Force NVIDIA as primary GPU for GNOME
  services.xserver.screenSection = ''
    Option "metamodes" "nvidia-auto-select +0+0 {ForceFullCompositionPipeline=On}"
    Option "AllowIndirectGLXProtocol" "off"
    Option "TripleBuffer" "on"
  '';

  # Disable problematic GNOME features that conflict with NVIDIA
  services.gnome.tinysparql.enable = lib.mkForce false;
  services.gnome.localsearch.enable = lib.mkForce false;
}
