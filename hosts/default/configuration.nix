# ~/NixOS/hosts/default/configuration.nix
{
  pkgs,
  lib,
  hostname,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    ../../modules
    ../shared/common.nix
  ];

  # Host-specific metadata
  networking.hostName = hostname;
  modules.networking.hostName = hostname;

  # Desktop configuration - override shared Wayland to use X11
  modules.desktop.displayManager.wayland = false;

  # Host-specific features
  modules.packages.gaming.enable = true;

  # Development tools for desktop
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

  # AMD GPU configuration
  modules.hardware.amd = {
    enable = true;
    vram.profile = "performance";
    gpu = {
      enableOpenCL = true;
      enableROCm = true;
      enableVulkan = true;
    };
    performance = {
      powerProfile = "high";
      enableMemoryBandwidthOptimization = true;
      pcie.disableASPM = true;
    };
    monitoring = {
      enable = true;
      enableProfiling = true;
      enableBenchmarking = true;
      tools = [
        "radeontop"
        "nvtop"
        "amdgpu_top"
        "umr"
        "gpu-viewer"
      ];
    };
    development = {
      enableCMake = true;
      enableMLFrameworks = true;
    };
  };

  # Desktop-specific packages
  modules.packages.extraPackages = with pkgs; [
    # GPU tools
    vulkan-tools
    vulkan-loader
    vulkan-validation-layers
    libva-utils
    vdpauinfo
    glxinfo
    mesa-demos
    vulkan-caps-viewer
    clinfo
    renderdoc

    # Development tools
    calibre
    anydesk
    postman
    dbeaver-bin
    android-studio
    android-tools

    # Media and Graphics
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

  # Network ports specific to desktop
  modules.networking.firewall.openPorts = [3000]; # Additional to shared SSH

  # Desktop-specific user groups
  users.groups.plugdev = {};
  users.users.notroot.extraGroups = [
    "dialout"
    "libvirtd"
    "plugdev"
  ];

  # Gaming programs
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
  };

  # CoreCtrl sudo access
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

  # Intel microcode
  hardware.cpu.intel.updateMicrocode = true;

  # Security
  security.auditd.enable = true;
  security.audit = {
    enable = true;
    backlogLimit = 8192;
    failureMode = "printk";
    rules = ["-a exit,always -F arch=b64 -S execve"];
  };

  security.apparmor = {
    enable = true;
    killUnconfinedConfinables = true;
  };

  # Boot configuration
  boot = {
    kernelPackages = pkgs.linuxPackages_latest;
    tmp.useTmpfs = true;
    kernelParams = ["mitigations=off"];
  };

  # Memory optimization - enhance core module ZRAM settings
  zramSwap = {
    memoryPercent = 50; # Use more ZRAM than core default (25%)
    priority = 32767; # Higher priority than file swap
    swapDevices = 7; # Multiple devices for better parallelism
  };

  # Enhanced swappiness for better ZRAM usage
  boot.kernel.sysctl."vm.swappiness" = 80;

  # Early OOM killer for memory pressure (disabled due to startup issues)
  # services.earlyoom.enable = false;

  # Disable unnecessary services for this host
  services.ollama.enable = false;
  services.tailscale.enable = false;
}
