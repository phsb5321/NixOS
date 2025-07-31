# ~/NixOS/hosts/default/configuration.nix
{
  pkgs,
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

  # GNOME configuration for AMD GPU - Force X11 for compatibility
  services.xserver.enable = true;

  # Display manager configuration - Force X11 only
  services.displayManager.gdm = {
    enable = true;
    wayland = false; # Force X11 only for AMD GPU compatibility
    autoSuspend = true;
  };

  # Disable Wayland compositor packages
  environment.gnome.excludePackages = with pkgs; [
    mutter # GNOME's Wayland compositor
  ];

  # Desktop manager configuration
  services.desktopManager.gnome.enable = true;

  # Ensure only GDM is enabled
  services.displayManager.sddm.enable = false;

  # Host-specific X11 configuration for AMD GPU compatibility
  services.thermald.enable = true;

  # Force X11 environment variables for AMD GPU
  environment.sessionVariables = {
    # Force X11 session - no Wayland for better compatibility
    XDG_SESSION_TYPE = "x11";
    GDK_BACKEND = "x11";
    QT_QPA_PLATFORM = "xcb";

    # Completely disable Wayland - use /dev/null to prevent connection attempts
    WAYLAND_DISPLAY = "/dev/null";
    MOZ_ENABLE_WAYLAND = "0";
    # NIXOS_OZONE_WL unset to prevent VS Code from adding Wayland flags
    ELECTRON_OZONE_PLATFORM_HINT = "x11";

    # Additional Wayland disabling
    SDL_VIDEODRIVER = "x11";
    CLUTTER_BACKEND = "x11";

    # AMD GPU configuration - Fixed deprecated MESA variables
    AMD_VULKAN_ICD = "RADV";
    VDPAU_DRIVER = "radeonsi";
    GALLIUM_DRIVER = "radeonsi";
    MESA_SHADER_CACHE_MAX_SIZE = "2G";
    MESA_DISK_CACHE_MAX_SIZE = "4G";

    # Force GLFW to use X11 backend - prevents Wayland connection attempts
    GLFW_BACKEND = "x11";
  };

  # Force applications to use X11 - system-wide
  environment.etc."environment".text = ''
    XDG_SESSION_TYPE=x11
    GDK_BACKEND=x11
    QT_QPA_PLATFORM=xcb
    WAYLAND_DISPLAY=/dev/null
    MOZ_ENABLE_WAYLAND=0
    SDL_VIDEODRIVER=x11
    CLUTTER_BACKEND=x11
    GLFW_BACKEND=x11
  '';

  # Additional Wayland disabling in systemd environment
  systemd.user.extraConfig = ''
    DefaultEnvironment="WAYLAND_DISPLAY="
    DefaultEnvironment="XDG_SESSION_TYPE=x11"
    DefaultEnvironment="GDK_BACKEND=x11"
    DefaultEnvironment="GLFW_BACKEND=x11"
  '';

  # Ensure GLFW uses X11 backend - create profile script
  environment.etc."profile.d/glfw-x11.sh".text = ''
    export GLFW_BACKEND=x11
  '';

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

  # AMD GPU configuration using hardware module
  modules.hardware.amd = {
    enable = true;
    gpu = {
      driver = "amdgpu";
      enableOpenCL = true;
      enableROCm = true;
      enableVulkan = true;
    };
    vram = {
      profile = "performance";
      enableLargePages = true;
      gttSize = 16384;
    };
    performance = {
      powerProfile = "high";
      enableMemoryBandwidthOptimization = true;
      pcie = {
        disableASPM = true;
      };
      thermal = {
        enableThrottling = true;
        enableFanControl = true;
      };
    };
  };

  # Additional AMD GPU packages
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
    # AMD GPU kernel parameters are now handled by the hardware module
  };

  # Memory optimization - reduced swappiness for better performance
  boot.kernel.sysctl."vm.swappiness" = 10;

  # Disable unnecessary services for this host
  services.ollama.enable = false;
  services.tailscale.enable = false;
}
