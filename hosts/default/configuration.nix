# ~/NixOS/hosts/default/configuration.nix
{
  pkgs,
  lib,
  inputs,
  bleedPkgs,
  systemVersion,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    ../../modules
    ../shared/common.nix
  ];

  # Desktop-specific configuration
  # Enable gaming packages for desktop
  modules.packages.gaming.enable = true;

  # Desktop-specific core module additions
  modules.core.java = {
    enable = true;
    androidTools.enable = true;
  };

  modules.core.documentTools = {
    enable = true;
    latex = {
      enable = true;
      minimal = false;
      extraPackages = with pkgs; [
        biber
        texlive.combined.scheme-context
      ];
    };
  };

  # Desktop-specific extra packages
  modules.packages.extraPackages = with pkgs; [
    # AMD GPU and Video Tools
    vulkan-tools
    vulkan-loader
    vulkan-validation-layers
    libva-utils
    vdpauinfo
    glxinfo
    ffmpeg-full

    # Development tools specific to desktop
    calibre
    anydesk

    # LACT for AMD GPU control
    lact
  ];

  # Desktop-specific networking ports
  modules.networking.firewall.openPorts = [22 3000];

  # AMD-specific hardware configuration for NixOS 25.05
  hardware.cpu.intel.updateMicrocode = true;

  # Early kernel mode setting for smooth boot
  boot.initrd.kernelModules = ["amdgpu"];

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages = with pkgs; [
      amdvlk # AMD Vulkan driver
      libva-vdpau-driver
      libvdpau-va-gl
      # rocmPackages.clr.icd  # OpenCL support - uncomment when build issues are resolved
    ];
    extraPackages32 = with pkgs.driversi686Linux; [
      amdvlk
      libva-vdpau-driver
      libvdpau-va-gl
    ];
  };

  # Explicitly configure AMD drivers
  services.xserver.videoDrivers = ["amdgpu"];

  # Enhanced Wayland/AMD graphics support for NixOS 25.05
  environment.sessionVariables = {
    # AMD-specific optimizations
    AMD_VULKAN_ICD = "RADV";
    VK_ICD_FILENAMES = "/run/opengl-driver/share/vulkan/icd.d/radeon_icd.x86_64.json";
    VDPAU_DRIVER = "radeonsi";

    # Wayland optimizations
    NIXOS_OZONE_WL = "1";
    MOZ_ENABLE_WAYLAND = "1";
    QT_QPA_PLATFORM = "wayland;xcb";
    GDK_BACKEND = "wayland,x11";
  };

  # GDM and session fixes
  services.xserver = {
    enable = true;
    xkb = {
      layout = "br";
      variant = "";
    };
  };

  # Explicitly disable conflicting display managers
  services.displayManager.sddm.enable = lib.mkForce false;

  # Additional networking overrides if needed
  networking.networkmanager.dns = lib.mkForce "default";

  # Desktop-specific user groups
  users.groups.plugdev = {};
  users.users.notroot.extraGroups = [
    "dialout"
    "libvirtd"
    "plugdev"
  ];

  # Desktop-specific AMD boot configuration
  boot = {
    kernelPackages = pkgs.linuxPackages_latest;
    tmp.useTmpfs = true;

    # AMD GPU kernel parameters for NixOS 25.05
    kernelParams = [
      "mitigations=off"
      "amdgpu.ppfeaturemask=0xffffffff"
      "radeon.si_support=0"
      "amdgpu.si_support=1"
      "radeon.cik_support=0"
      "amdgpu.cik_support=1"
      "radeon.audio=1"
      "amdgpu.audio=1"
      # Additional Wayland optimizations
      "amdgpu.dc=1"
      "amdgpu.dpm=1"
    ];
  };

  # Desktop-specific security configuration
  security.auditd.enable = true;
  security.audit = {
    enable = true;
    backlogLimit = 8192;
    failureMode = "printk";
    rules = [
      "-a exit,always -F arch=b64 -S execve"
    ];
  };

  security.apparmor = {
    enable = true;
    killUnconfinedConfinables = true;
  };

  # Desktop-specific gaming programs
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
  };

  # LACT daemon service for AMD GPU control
  systemd.packages = with pkgs; [lact];
  systemd.services.lactd.wantedBy = ["multi-user.target"];

  # AMD GPU power management - alternative to hardware.amdgpu.overdrive
  environment.etc."modprobe.d/amdgpu.conf".text = ''
    options amdgpu ppfeaturemask=0xffffffff
  '';

  # CoreCtrl sudo configuration
  security.sudo.extraRules = [
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

  # ESP32 Development
  services.udev.packages = [
    pkgs.platformio-core
    pkgs.openocd
  ];

  # Desktop-specific services
  services.ollama.enable = false;
  services.tailscale.enable = false;
}
