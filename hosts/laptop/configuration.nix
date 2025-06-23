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

  # Ensure WiFi firmware is available
  hardware.enableRedistributableFirmware = true;
  hardware.firmware = with pkgs; [
    linux-firmware
  ];

  # Additional WiFi-related services
  systemd.services.wifi-unblock = {
    description = "Attempt to unblock WiFi on startup";
    after = ["network-pre.target"];
    wants = ["network-pre.target"];
    before = ["network.target"];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.util-linux}/bin/rfkill unblock wifi";
      ExecStartPost = "${pkgs.util-linux}/bin/rfkill unblock all";
      RemainAfterExit = true;
    };
    wantedBy = ["multi-user.target"];
  };

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

  # Laptop-specific Python without GTK (to match original config)
  modules.packages.python.withGTK = lib.mkForce false;

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

  # Laptop-specific Intel hardware configuration for NixOS 25.05
  hardware.cpu.intel.updateMicrocode = true;

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages = with pkgs; [
      intel-media-driver # Modern driver (iHD) for Broadwell+
      intel-vaapi-driver # Legacy driver (i965) - better browser support
      vpl-gpu-rt # Intel Quick Sync Video
      libvdpau-va-gl # VDPAU support
    ];
    extraPackages32 = with pkgs.pkgsi686Linux; [
      intel-vaapi-driver
    ];
  };

  # Laptop-specific X server configuration for Intel graphics with Wayland
  services.xserver = {
    enable = true;
    videoDrivers = ["intel"];
    deviceSection = ''
      Option "TearFree" "true"
      Option "DRI" "3"
      Option "AccelMethod" "sna"
    '';
    xkb = {
      layout = "br";
      variant = "";
    };
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

  # Laptop-specific environment configuration for Intel/Wayland on NixOS 25.05
  environment = {
    sessionVariables = {
      LD_LIBRARY_PATH = lib.mkForce "/run/opengl-driver/lib:/run/opengl-driver-32/lib:${pkgs.pipewire}/lib";
      LIBVA_DRIVER_NAME = "iHD"; # Intel VAAPI driver (modern)
      SHELL = "${pkgs.zsh}/bin/zsh";

      # Wayland support for Intel graphics
      NIXOS_OZONE_WL = "1";
      MOZ_ENABLE_WAYLAND = "1";
      QT_QPA_PLATFORM = "wayland;xcb";
      GDK_BACKEND = "wayland,x11";
      VDPAU_DRIVER = "va_gl";
    };

    systemPackages = with pkgs; [
      # Laptop-specific packages for NixOS 25.05
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

      # Verification tools for Intel graphics
      libva-utils # vainfo command
      vulkan-tools # vulkaninfo
      glxinfo
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

  # Laptop-specific boot configuration for Intel graphics and Wayland
  boot = {
    blacklistedKernelModules = [
      "nouveau"
      "nvidia"
      "nvidia_drm"
      "nvidia_modeset"
      "nvidia_uvm"
    ];

    # Intel graphics optimizations for NixOS 25.05
    kernelParams = [
      "i915.enable_fbc=1"
      "i915.enable_psr=2"
      "i915.enable_hd_vgaarb=1"
      "i915.enable_dc=2"
      # Uncomment if needed for specific Intel GPUs (12th Gen Alder Lake example)
      # "i915.force_probe=46a8"
      # WiFi-specific parameters to handle hard block issues
      "rfkill.default_state=1"
      "iwlwifi.power_save=0"
      "iwlwifi.disable_11n=0"
      "rfkill.master_switch_mode=0"
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
