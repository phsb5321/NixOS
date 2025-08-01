# NixOS Desktop Configuration - Unified and Organized
# Combines all working configurations with proper module structure
{
  config,
  pkgs,
  lib,
  hostname,
  ...
}:

let
  # Configuration variants for different scenarios
  variants = {
    # Normal operation with hardware acceleration
    hardware = {
      kernelParams = [
        "amdgpu.runpm=0"           # Disable runtime power management (prevents flickering)
        "amdgpu.dpm=1"             # Enable dynamic power management
        "amdgpu.dc=1"              # Enable display core
        "consoleblank=0"           # Disable console blanking
        "rd.systemd.show_status=true"
        "quiet"
      ];
      videoDrivers = [ "amdgpu" ];
      enableHardwareAccel = true;
    };
    
    # Conservative fallback for GPU issues
    conservative = {
      kernelParams = [
        "amdgpu.runpm=0"
        "amdgpu.dpm=1" 
        "amdgpu.dc=1"
        "consoleblank=0"
        "rd.systemd.show_status=true"
      ];
      videoDrivers = [ "amdgpu" ];
      enableHardwareAccel = true;
      forceTearFree = true;
    };
    
    # Emergency software rendering fallback
    software = {
      kernelParams = [
        "nomodeset"
        "amdgpu.modeset=0"
        "radeon.modeset=0"
        "video=1024x768@60"
        "consoleblank=0"
        "iommu=soft"
      ];
      videoDrivers = [ "vesa" "fbdev" ];
      enableHardwareAccel = false;
      blacklistModules = [ "amdgpu" "radeon" "nouveau" ];
    };
  };
  
  # Select active variant (change this to switch modes)
  activeVariant = variants.hardware; # Change to: conservative, software
  
in {
  imports = [
    ./hardware-configuration.nix
    ../../modules
    ../shared/common.nix
  ];

  # Host-specific metadata
  modules.networking.hostName = lib.mkForce hostname;

  # Conditional boot configuration based on variant
  boot = {
    # Use LTS kernel for maximum stability
    kernelPackages = pkgs.linuxPackages_6_6;
    
    # Dynamic kernel parameters based on variant
    kernelParams = activeVariant.kernelParams;
    
    # Conditional kernel module handling
    initrd.kernelModules = if activeVariant.enableHardwareAccel then [ "amdgpu" ] else [];
    kernelModules = if activeVariant.enableHardwareAccel then [ "kvm-intel" "amdgpu" ] else [];
    blacklistedKernelModules = activeVariant.blacklistModules or [];
    
    # Temporary filesystem in RAM for better performance
    tmp.useTmpfs = true;
  };

  # Hardware configuration - conditional based on variant
  hardware = {
    graphics = lib.mkIf activeVariant.enableHardwareAccel {
      enable = true;
      extraPackages = with pkgs; [ amdvlk ];
      extraPackages32 = with pkgs; [ driversi686Linux.amdvlk ];
    };
    cpu.intel.updateMicrocode = true;
  };

  # Display system configuration
  services.xserver = {
    enable = true;
    videoDrivers = lib.mkForce activeVariant.videoDrivers;
    
    # Conditional X11 configuration
    config = if activeVariant.enableHardwareAccel then ''
      Section "Device"
        Identifier "AMD Graphics"
        Driver "amdgpu"
        Option "DRI" "3"
        Option "TearFree" "${if activeVariant.forceTearFree or false then "true" else "true"}"
        Option "AccelMethod" "glamor"
        ${lib.optionalString (activeVariant ? forceTearFree && activeVariant.forceTearFree) ''
        Option "VariableRefresh" "true"
        ''}
      EndSection
    '' else ''
      Section "Device"
        Identifier "Software Graphics"
        Driver "vesa"
        Option "AccelMethod" "none"
        Option "ShadowFB" "true"
      EndSection
      
      Section "Screen"
        Identifier "Software Screen"
        DefaultDepth 24
        SubSection "Display"
          Depth 24
          Modes "1024x768" "800x600"
        EndSubSection
      EndSection
    '';
  };

  # Display manager and desktop environment
  services.displayManager.gdm = {
    enable = true;
    wayland = lib.mkForce false;  # Force X11 for AMD GPU stability
  };
  
  services.desktopManager.gnome.enable = lib.mkForce true;

  # GNOME configuration optimized for AMD GPU
  services.desktopManager.gnome.extraGSettingsOverrides = lib.mkAfter ''
    [org.gnome.mutter]
    experimental-features=[]

    [org.gnome.desktop.interface]
    enable-animations=${if activeVariant.enableHardwareAccel then "true" else "false"}
    enable-hot-corners=false

    [org.gnome.desktop.wm.preferences]
    button-layout='appmenu:minimize,maximize,close'

    [org.gnome.settings-daemon.plugins.power]
    sleep-inactive-ac-type='nothing'
    sleep-inactive-battery-type='suspend'
  '';

  # Environment variables for software rendering mode
  environment.variables = lib.mkIf (!activeVariant.enableHardwareAccel) {
    "LIBGL_ALWAYS_SOFTWARE" = "1";
    "MESA_LOADER_DRIVER_OVERRIDE" = "swrast";
    "GALLIUM_DRIVER" = "llvmpipe";
    "GSK_RENDERER" = "cairo";
    "CLUTTER_BACKEND" = "x11";
    "GDK_BACKEND" = "x11";
    "QT_XCB_GL_INTEGRATION" = "none";
    "WEBKIT_DISABLE_COMPOSITING_MODE" = "1";
  };

  # SystemD service for AMD GPU optimization (only when hardware accel enabled)
  systemd.services.amd-gpu-optimization = lib.mkIf activeVariant.enableHardwareAccel {
    description = "AMD GPU Performance Optimization";
    after = [ "graphical-session.target" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = pkgs.writeShellScript "amd-gpu-optimization" ''
        # Set performance level based on variant
        ${if activeVariant == variants.conservative then ''
        echo "high" > /sys/class/drm/card0/device/power_dpm_force_performance_level 2>/dev/null || true
        echo "1" > /sys/class/drm/card0/device/pp_power_profile_mode 2>/dev/null || true
        '' else ''
        echo "auto" > /sys/class/drm/card0/device/power_dpm_force_performance_level 2>/dev/null || true
        echo "1" > /sys/class/drm/card0/device/power_dpm_state 2>/dev/null || true
        ''}
      '';
    };
  };

  # Input device management
  services.libinput = {
    enable = true;
    mouse = {
      accelProfile = "adaptive";
      accelSpeed = "0";
    };
    touchpad = {
      accelProfile = "adaptive";
      accelSpeed = "0";
      tapping = true;
      naturalScrolling = false;
    };
  };

  # Additional user groups for desktop functionality
  users.groups.plugdev = { };
  users.users.notroot.extraGroups = [
    "dialout"
    "libvirtd"
    "plugdev"
    "input"
  ];

  # Desktop-specific system packages
  environment.systemPackages = with pkgs; [
    # GPU tools and monitoring (conditional)
    vulkan-tools
    vulkan-loader
    vulkan-validation-layers
    libva-utils
    vdpauinfo
    glxinfo
    mesa-demos
    clinfo
    radeontop

    # Development tools
    gcc
    gnumake
    python3
    nodejs

    # System monitoring
    neofetch
    lm_sensors
    
    # Session management
    gnome-session
    xorg.xf86inputlibinput
    libinput
    evtest
  ] ++ lib.optionals (!activeVariant.enableHardwareAccel) [
    # Minimal packages for software rendering mode
    firefox
    gnome-text-editor
    gnome-terminal
    nano
    htop
  ];

  # Enable additional modules
  modules.packages.gaming.enable = lib.mkDefault activeVariant.enableHardwareAccel;
  modules.core.java = {
    enable = true;
    androidTools.enable = activeVariant.enableHardwareAccel;
  };

  # Document tools
  modules.core.documentTools = {
    enable = true;
    latex = {
      enable = activeVariant.enableHardwareAccel;
      minimal = false;
      extraPackages = lib.optionals activeVariant.enableHardwareAccel (with pkgs; [
        biber
        texlive.combined.scheme-context
      ]);
    };
  };

  # Comprehensive package collection (conditional based on hardware capabilities)
  modules.packages.extraPackages = with pkgs; lib.optionals activeVariant.enableHardwareAccel [
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

  # Network configuration
  modules.networking.firewall.openPorts = [ 3000 ];

  # Programs (conditional)
  programs.steam = lib.mkIf activeVariant.enableHardwareAccel {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
  };

  # Security and sudo access
  security = {
    sudo.extraRules = [
      {
        groups = [ "wheel" ];
        commands = [
          {
            command = "${pkgs.corectrl}/bin/corectrl";
            options = [ "NOPASSWD" ];
          }
        ];
      }
    ];
    
    auditd.enable = activeVariant.enableHardwareAccel;
    audit = lib.mkIf activeVariant.enableHardwareAccel {
      enable = true;
      backlogLimit = 8192;
      failureMode = "printk";
      rules = [ "-a exit,always -F arch=b64 -S execve" ];
    };

    apparmor = lib.mkIf activeVariant.enableHardwareAccel {
      enable = true;
      killUnconfinedConfinables = true;
    };
  };

  # Audio configuration (conditional)
  hardware.pulseaudio.enable = lib.mkIf (!activeVariant.enableHardwareAccel) true;
  services.pipewire.enable = lib.mkIf (!activeVariant.enableHardwareAccel) (lib.mkForce false);

  # Disable conflicting power management services for desktop
  services.power-profiles-daemon.enable = lib.mkForce false;
  services.thermald.enable = lib.mkForce false;
  services.tlp.enable = lib.mkForce false;

  # Service defaults
  services.ollama.enable = lib.mkDefault false;
  services.tailscale.enable = lib.mkDefault false;

  # System state version
  system.stateVersion = "25.11";
}
