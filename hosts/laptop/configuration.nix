# /home/notroot/NixOS/hosts/laptop/configuration.nix
{
  config,
  pkgs,
  lib,
  inputs,
  systemVersion,
  bleedPkgs,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    ../../modules
    inputs.home-manager.nixosModules.default
    ../shared/common.nix
  ];

  # Laptop-specific configuration
  # Override hostname for laptop
  modules.networking.hostName = "nixos-laptop";
  modules.home.hostName = "laptop";

  # Laptop-specific core module additions
  modules.core.extraSystemPackages = with pkgs; [
    nvtopPackages.full # Keep for monitoring
    bash # Make sure bash is in system packages
  ];

  # Laptop-specific extra packages (minimal set for laptop)
  modules.packages.extraPackages = with pkgs; [
    # Debugging tools for laptop
    glxinfo
  ];

  # Laptop doesn't need gaming packages
  modules.packages.gaming.enable = false;

  # Laptop-specific locale settings (override if needed)
  i18n = {
    defaultLocale = "en_US.UTF-8";
    supportedLocales = ["en_US.UTF-8/UTF-8" "pt_BR.UTF-8/UTF-8" "C.UTF-8/UTF-8"];
    glibcLocales = pkgs.glibcLocales;
  };

  # Laptop-specific user configuration
  users.users.notroot = {
    initialPassword = "changeme";
    shell = "${pkgs.zsh}/bin/zsh";
    extraGroups = [
      "nvidia" # Intel laptop might not need this, but keeping for compatibility
      "sddm"
    ];
  };

  # Register shells with explicit paths
  environment.shells = [
    "${pkgs.bash}/bin/bash"
    "${pkgs.zsh}/bin/zsh"
    "${pkgs.fish}/bin/fish"
  ];

  # Laptop-specific Intel hardware configuration
  hardware.cpu.intel.updateMicrocode = true;
  hardware.graphics.extraPackages = with pkgs; [
    intel-media-driver
    vaapiIntel
    libvdpau-va-gl
  ];

  # Nixpkgs configuration
  nixpkgs.config = {
    allowUnfree = true;
  }; # Laptop-specific X server configuration for Intel graphics
  services.xserver = {
    videoDrivers = ["intel"];
    deviceSection = ''
      Option "TearFree" "true"
      Option "DRI" "3"
      Option "AccelMethod" "sna"
    '';
  };

  services.dbus = {
    enable = true;
    packages = [pkgs.dconf];
  };
  # Laptop-specific PAM services
  security.pam.services = {
    sddm.enableKwallet = true;
    sddm-greeter.enableKwallet = true;
    login.enableGnomeKeyring = true;
  };

  # Laptop-specific environment configuration for Intel/Wayland
  environment = {
    sessionVariables = {
      XDG_SESSION_TYPE = "wayland";
      LD_LIBRARY_PATH = lib.mkForce "/run/opengl-driver/lib:/run/opengl-driver-32/lib:${pkgs.pipewire}/lib";
      LIBVA_DRIVER_NAME = "iHD"; # Intel VAAPI driver
      SDL_VIDEODRIVER = "wayland";
      GDK_BACKEND = "wayland";
      MOZ_ENABLE_WAYLAND = "1";
      QT_QPA_PLATFORM = "wayland";
      CLUTTER_BACKEND = "wayland";
      SHELL = "${pkgs.zsh}/bin/zsh";
    };

    systemPackages = with pkgs; [
      gnome-shell-extensions
      gnome-tweaks
      gnomeExtensions.dash-to-dock
      gnomeExtensions.clipboard-indicator
      gnomeExtensions.sound-output-device-chooser
      gnomeExtensions.gsconnect
      gnomeExtensions.blur-my-shell
      linux-firmware
      wayland
      xdg-utils
      xdg-desktop-portal
      xdg-desktop-portal-gtk
      xdg-desktop-portal-gnome
      mesa-demos
      lshw
      xorg.xrandr
      xorg.xinput
    ];
  };

  # XDG Portal configuration for laptop
  xdg.portal = {
    enable = true;
    extraPortals = [
      pkgs.xdg-desktop-portal-gtk
      pkgs.xdg-desktop-portal-gnome
    ];
    wlr.enable = true;
  };

  # Laptop-specific boot configuration for Intel graphics
  boot = {
    blacklistedKernelModules = [
      "nouveau"
      "nvidia"
      "nvidia_drm"
      "nvidia_modeset"
      "nvidia_uvm"
    ];

    kernelParams = [
      "i915.enable_fbc=1"
      "i915.enable_psr=2"
      "i915.enable_hd_vgaarb=1"
      "i915.enable_dc=2"
    ];

    kernelModules = ["i915"];
    initrd.kernelModules = ["i915"];

    loader = {
      systemd-boot.enable = true;
      efi = {
        canTouchEfiVariables = true;
        efiSysMountPoint = "/boot";
      };
    };
  };

  # Laptop-specific programs
  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
  };

  # Enable Docker for development
  virtualisation.docker.enable = true;

  # Enable Tailscale for laptop
  services.tailscale.enable = true;
}
