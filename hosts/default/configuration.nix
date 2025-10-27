# NixOS Desktop Configuration - Host Specific
# Contains only host-specific configuration, GNOME config is in shared modules
{
  pkgs,
  lib,
  hostname,
  ...
}: let
  # Configuration variants for different scenarios
  variants = {
    # Normal operation with hardware acceleration
    hardware = {
      kernelParams = [
        "amdgpu.runpm=0" # Disable runtime power management (prevents flickering)
        "amdgpu.dpm=1" # Enable dynamic power management
        "amdgpu.dc=1" # Enable display core
        "consoleblank=0" # Disable console blanking
        "rd.systemd.show_status=true"
        "quiet"
      ];
      videoDrivers = ["amdgpu"];
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
      videoDrivers = ["amdgpu"];
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
      videoDrivers = [
        "vesa"
        "fbdev"
      ];
      enableHardwareAccel = false;
      blacklistModules = [
        "amdgpu"
        "radeon"
        "nouveau"
      ];
    };
  };
  # Simple default variant selection (hardcoded to hardware for stability)
  activeVariant = variants.hardware; # Default to hardware variant
in {
  imports = [
    ./hardware-configuration.nix
    ../../modules
    ../shared/common.nix
    ./gnome.nix
  ];

  # Host-specific metadata
  modules.networking.hostName = lib.mkForce hostname;

  # Boot configuration with variants
  boot = {
    # Temporary files and kernel optimization
    tmp.useTmpfs = true;

    # Kernel configuration
    kernelPackages = pkgs.linuxPackages_6_6;

    # Dynamic kernel parameters based on variant
    kernelParams = activeVariant.kernelParams;

    # Conditional kernel module handling
    initrd.kernelModules =
      if activeVariant.enableHardwareAccel
      then ["amdgpu"]
      else [];
    kernelModules =
      if activeVariant.enableHardwareAccel
      then [
        "kvm-intel"
        "amdgpu"
      ]
      else [];
    blacklistedKernelModules = activeVariant.blacklistModules or [];
  };

  # Hardware configuration based on variant
  hardware = {
    graphics = lib.mkIf activeVariant.enableHardwareAccel {
      enable = true;
      # RADV (Mesa RADV driver) is now the default and preferred AMD Vulkan driver
      # amdvlk was deprecated and removed from nixpkgs
    };
    cpu.intel.updateMicrocode = true;
  };

  # X11 configuration (includes video drivers)
  services.xserver = {
    enable = true;
    videoDrivers = lib.mkForce activeVariant.videoDrivers;
    # X11 config only needed for software rendering fallback
    config = lib.mkIf (!activeVariant.enableHardwareAccel) ''
      Section "Device"
        Identifier "Software Graphics"
        Driver "vesa"
        Option "AccelMethod" "none"
        Option "ShadowFB" "true"
      EndSection

      Section "Screen"
        Identifier "Default Screen"
        Device "Software Graphics"
        DefaultDepth 24
        SubSection "Display"
          Depth 24
          Modes "1024x768" "800x600"
        EndSubSection
      EndSection
    '';
  };

  # Host-specific SystemD service for AMD GPU optimization
  systemd.services.amd-gpu-optimization = lib.mkIf activeVariant.enableHardwareAccel {
    description = "AMD GPU Performance Optimization";
    after = ["graphical-session.target"];
    wantedBy = ["multi-user.target"];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = pkgs.writeShellScript "amd-gpu-optimization" ''
        # Set performance level based on variant
        ${
          if activeVariant == variants.conservative
          then ''
            echo "high" > /sys/class/drm/card0/device/power_dpm_force_performance_level 2>/dev/null || true
            echo "1" > /sys/class/drm/card0/device/pp_power_profile_mode 2>/dev/null || true
          ''
          else ''
            echo "auto" > /sys/class/drm/card0/device/power_dpm_force_performance_level 2>/dev/null || true
            echo "1" > /sys/class/drm/card0/device/power_dpm_state 2>/dev/null || true
          ''
        }
      '';
    };
  };

  # Host-specific user groups
  users.groups.plugdev = {};
  users.users.notroot.extraGroups = [
    "dialout" # Serial device access for development
    "libvirtd" # Virtualization access
    "plugdev" # USB device access
    "input" # Input device access
  ];

  # Host-specific desktop packages (hardware-dependent applications)
  environment.systemPackages = with pkgs;
    [
      # GPU-specific tools for AMD hardware debugging
      vulkan-tools
      vulkan-loader
      vulkan-validation-layers
      libva-utils
      vdpauinfo
      glxinfo
      mesa-demos
      clinfo
      radeontop

      # Essential development tools for desktop host
      gcc
      gnumake
      python3
      nodejs

      # System monitoring
      neofetch
      lm_sensors

      # Host-specific terminal (GPU-accelerated)
      kitty
    ]
    ++ lib.optionals (!activeVariant.enableHardwareAccel) [
      # Essential packages for software rendering mode
      firefox
      gnome-text-editor
      gnome-terminal
      nano
      htop
    ];

  # Host-specific module configuration
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
      extraPackages = lib.optionals activeVariant.enableHardwareAccel (
        with pkgs; [
          biber
          texlive.combined.scheme-context
        ]
      );
    };
    markdown = {
      enable = true;
      lsp = true;
      linting = {
        enable = true;
        markdownlint = true;
        vale = {
          enable = true;
          styles = ["google" "write-good"];
        };
        linkCheck = true;
      };
      formatting = {
        enable = true;
        mdformat = true;
        prettier = false;
      };
      preview = {
        enable = true;
        glow = true;
        grip = false;
      };
      utilities = {
        enable = true;
        doctoc = true;
        mdbook = activeVariant.enableHardwareAccel;
        mermaid = true;
      };
    };
  };

  modules.packages.extraPackages = with pkgs;
    lib.optionals activeVariant.enableHardwareAccel [
      # Development tools
      calibre
      anydesk
      postman
      dbeaver-bin
      android-studio
      android-tools

      # Media and Graphics (GPU-accelerated)
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
      # massif-visualizer # Temporarily disabled due to build issues

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

  # Host-specific network configuration
  modules.networking.firewall.openPorts = [3000]; # Development server port

  # Tailscale for remote access and mesh networking
  modules.networking.tailscale = {
    enable = true;
    useRoutingFeatures = "both"; # Can serve as exit node and use routes
    extraUpFlags = [
      "--advertise-exit-node"
      "--accept-routes"
    ];
  };

  # Programs (conditional)
  programs.steam = lib.mkIf activeVariant.enableHardwareAccel {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
    gamescopeSession.enable = true;
  };

  # Shell configuration is now handled by the shell module

  # Host-specific security configuration
  security = {
    auditd.enable = activeVariant.enableHardwareAccel;
    audit = lib.mkIf activeVariant.enableHardwareAccel {
      enable = true;
      backlogLimit = 8192;
      failureMode = "printk";
      rules = ["-a exit,always -F arch=b64 -S execve"];
    };

    apparmor = lib.mkIf activeVariant.enableHardwareAccel {
      enable = true;
      killUnconfinedConfinables = true;
    };
  };

  # Note: Wayland environment variables are now managed by the GNOME module
  # to prevent conflicts and ensure consistency across all applications

  # System state version
  system.stateVersion = "25.11";
}
