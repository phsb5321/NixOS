# ~/NixOS/hosts/default/configuration.nix
{
  pkgs,
  lib,
  hostname,
  ...
}:
{
  imports = [
    ./hardware-configuration.nix
    ../../modules
    ../shared/common.nix
  ];

  # Host-specific metadata
  networking.hostName = hostname;

  # Override shared configuration as needed
  modules.networking.hostName = hostname;

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

  # Enable comprehensive AMD GPU support with extensive VRAM management
  modules.hardware.amd = {
    enable = true;

    # Use performance profile for desktop workstation
    vram.profile = "performance";

    # Enable all GPU features
    gpu = {
      enableOpenCL = true;
      enableROCm = true;
      enableVulkan = true;
    };

    # Advanced VRAM configuration
    vram = {
      vmFragmentSize = 10;
      vmBlockSize = 10;
      gttSize = 32768;
      enableLargePages = true;
      hugePages = {
        enable = true;
        count = 4096;
      };
    };

    # Performance optimizations
    performance = {
      powerProfile = "high";
      enableMemoryBandwidthOptimization = true;
      pcie.disableASPM = true;
    };

    # Enhanced monitoring and debugging
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

    # Gaming optimizations
    environment.gaming = {
      enableDXVKHUD = true;
      dxvkHudElements = "memory,gpuload,fps,frametime,version";
    };

    # Development support
    development = {
      enableCMake = true;
      enableMLFrameworks = true;
    };
  };

  # Desktop-specific extra packages (non-GPU related)
  modules.packages.extraPackages = with pkgs; [
    # Additional GPU monitoring and benchmarking tools not in AMD module
    vulkan-tools
    vulkan-loader
    vulkan-validation-layers
    libva-utils
    vdpauinfo
    glxinfo
    ffmpeg-full
    mesa-demos
    vulkan-caps-viewer
    clinfo
    renderdoc # Graphics debugging with memory analysis

    # Development tools specific to desktop
    calibre
    anydesk
    postman
    dbeaver-bin
    android-studio
    android-tools

    # Media and Graphics - Desktop workstation
    gimp
    inkscape
    blender
    krita
    kdePackages.kdenlive
    obs-studio

    # Music streaming
    spotify # Official Spotify client
    spot # Native GNOME Spotify client (lightweight)
    ncspot # Terminal-based Spotify client (minimal resources)

    # Communication
    telegram-desktop
    vesktop # Better Discord client with Vencord built-in
    slack
    zoom-us

    # Gaming (desktop only)
    steam
    lutris
    wine
    winetricks

    # Productivity - Desktop
    obsidian
    notion-app-enhanced

    # System monitoring
    htop
    btop

    # Core development tools
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

  # Desktop-specific networking ports
  modules.networking.firewall.openPorts = [
    22
    3000
  ];

  # CPU microcode updates
  hardware.cpu.intel.updateMicrocode = true;

  # Desktop development environment variables (non-GPU related)
  environment.sessionVariables = {
    CHROME_EXECUTABLE = "${pkgs.google-chrome}/bin/google-chrome-stable";
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
  users.groups.plugdev = { };
  users.users.notroot.extraGroups = [
    "dialout"
    "libvirtd"
    "plugdev"
  ];

  # Desktop-specific boot configuration
  boot = {
    kernelPackages = pkgs.linuxPackages_latest;
    tmp.useTmpfs = true;

    # Basic kernel parameters (GPU-specific ones handled by AMD module)
    kernelParams = [
      "mitigations=off"
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

  # CoreCtrl sudo configuration
  security.sudo.extraRules = [
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

  # ESP32 Development
  services.udev.packages = [
    pkgs.platformio-core
    pkgs.openocd
  ];

  # Desktop-specific system configuration (GPU optimization handled by AMD module)

  # Desktop-specific services
  services.ollama.enable = false;
  services.tailscale.enable = false;

  # Additional desktop-specific optimizations (GPU optimization handled by AMD module)
}
