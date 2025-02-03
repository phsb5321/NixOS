# ~/NixOS/hosts/laptop/configuration.nix
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
    inputs.home-manager.nixosModules.default
    ../../modules
  ];

  # Enable core module with basic system configuration
  modules.core = {
    enable = true;
    stateVersion = systemVersion;
    timeZone = "America/Recife";
    defaultLocale = "en_US.UTF-8";
    extraSystemPackages = with pkgs; [
      # Development Tools
      llvm
      clang
      cudaPackages.cuda_nvcc
      cudaPackages.cuda_cudart
      cudaPackages.cuda_cccl
      nvtopPackages.full
      seahorse

      # System Utilities
      bleedPkgs.zed-editor

      # Additional Tools
      bleachbit
      speechd
    ];
  };

  # Enable and configure desktop module
  modules.desktop = {
    enable = true;
    environment = "kde";
    kde.version = "plasma6";
    autoLogin = {
      enable = false;
      user = "notroot";
    };
    fonts = {
      enable = true;
      packages = with pkgs; [
        nerd-fonts.jetbrains-mono
      ];
      defaultFonts = {
        monospace = ["JetBrainsMono Nerd Font" "FiraCode Nerd Font Mono" "Fira Code"];
      };
    };
  };

  # Network configuration
  modules.networking = {
    enable = true;
    hostName = "nixos";
    optimizeTCP = true;
    enableNetworkManager = true;
    dns = {
      enableSystemdResolved = true;
      enableDNSOverTLS = true;
      primaryProvider = "cloudflare";
    };
    firewall = {
      enable = true;
      allowPing = true;
      openPorts = [22];
      trustedInterfaces = [];
    };
  };

  # Home configuration
  modules.home = {
    enable = true;
    username = "notroot";
    hostName = "laptop";
    extraPackages = with pkgs; [
      vscode
      google-chrome
      insomnia
      postman
      gparted
      baobab
      syncthing
      vlc
      pigz
      mangohud
      unzip
      spotify
      lsof
      discord
      corectrl
      inputs.zen-browser.packages.${system}.default
      python3
      waydroid
    ];
  };

  # Locale settings
  i18n = {
    defaultLocale = "en_US.UTF-8";
    supportedLocales = [
      "en_US.UTF-8/UTF-8"
      "pt_BR.UTF-8/UTF-8"
    ];
    extraLocaleSettings = {
      LC_ADDRESS = "pt_BR.UTF-8";
      LC_IDENTIFICATION = "pt_BR.UTF-8";
      LC_MEASUREMENT = "pt_BR.UTF-8";
      LC_MONETARY = "pt_BR.UTF-8";
      LC_NAME = "pt_BR.UTF-8";
      LC_NUMERIC = "pt_BR.UTF-8";
      LC_PAPER = "pt_BR.UTF-8";
      LC_TELEPHONE = "pt_BR.UTF-8";
      LC_TIME = "pt_BR.UTF-8";
    };
  };

  # User configuration
  users = {
    defaultUserShell = pkgs.zsh;
    users.notroot = {
      isNormalUser = true;
      description = "Pedro Balbino";
      initialPassword = "changeme";
      extraGroups = [
        "networkmanager"
        "wheel"
        "audio"
        "video"
        "disk"
        "input"
        "bluetooth"
        "docker"
        "render"
        "nvidia"
        "kvm"
        "sddm"
        "pipewire"
      ];
    };
  };

  # Hardware configuration
  hardware = {
    enableRedistributableFirmware = true;
    cpu.intel.updateMicrocode = true;

    # Graphics configuration
    graphics = {
      enable = true;
      enable32Bit = true;
      extraPackages = with pkgs; [
        intel-media-driver
        vaapiIntel
        vaapiVdpau
        libvdpau-va-gl
      ];
    };

    # NVIDIA configuration
    nvidia = {
      package = config.boot.kernelPackages.nvidiaPackages.stable;
      open = false;
      modesetting.enable = true;
      powerManagement = {
        enable = true;
        finegrained = true;
      };
      prime = {
        offload = {
          enable = true;
          enableOffloadCmd = true;
        };
        intelBusId = "PCI:0:2:0";
        nvidiaBusId = "PCI:1:0:0";
      };
      nvidiaSettings = true;
      forceFullCompositionPipeline = true;
    };

    # Nvidia Container Toolkit
    nvidia-container-toolkit.enable = true;
  };

  # Nixpkgs configuration
  nixpkgs.config = {
    allowUnfree = true;
    cudaSupport = true;
  };

  # Services configuration
  services = {
    # Display Manager Configuration (Updated paths)
    displayManager = {
      sddm = {
        enable = true;
        wayland.enable = true;
        autoNumlock = true;
        settings = {
          Theme = {
            CursorTheme = "breeze_cursors";
            Font = "Noto Sans";
          };
          General = {
            InputMethod = "";
            Numlock = "on";
          };
          Wayland = {
            CompositorCommand = "kwin_wayland --drm --no-lockscreen";
          };
        };
      };
    };

    # Plasma Desktop Configuration
    desktopManager.plasma6.enable = true;

    # System Services
    dbus = {
      enable = true;
      packages = [pkgs.dconf];
    };

    # Audio Configuration (Updated from pulseaudio)
    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      jack.enable = true;
    };

    # Additional Services
    accounts-daemon.enable = true;
    upower.enable = true;
    udisks2.enable = true;
    gvfs.enable = true;
    tumbler.enable = true;
  };

  # Security and authentication
  security = {
    pam = {
      services = {
        sddm.enableKwallet = true;
        sddm-greeter.enableKwallet = true;
        login.enableKwallet = true;
      };
    };
    rtkit.enable = true;
    polkit.enable = true;
  };

  # Environment configuration
  environment = {
    sessionVariables = {
      NIXOS_OZONE_WL = "1";
      XDG_SESSION_TYPE = "wayland";
      SDL_VIDEODRIVER = "wayland";
      CLUTTER_BACKEND = "wayland";
      CUDA_PATH = "${pkgs.cudaPackages.cuda_cudart}";
      LD_LIBRARY_PATH = lib.mkForce "/run/opengl-driver/lib:/run/opengl-driver-32/lib:${pkgs.pipewire}/lib";
      __NV_PRIME_RENDER_OFFLOAD = "1";
      __NV_PRIME_RENDER_OFFLOAD_PROVIDER = "NVIDIA-G0";
      __GLX_VENDOR_LIBRARY_NAME = "nvidia";
      __VK_LAYER_NV_optimus = "NVIDIA_only";
      LIBVA_DRIVER_NAME = "nvidia";
      PLASMA_USE_QT_SCALING = "1";
      QT_AUTO_SCREEN_SCALE_FACTOR = "1";
    };

    systemPackages = with pkgs; [
      # KDE Packages
      kdePackages.plasma-workspace
      kdePackages.plasma-desktop
      kdePackages.kwin
      kdePackages.kscreen
      kdePackages.plasma-pa
      kdePackages.kgamma
      kdePackages.sddm-kcm
      kdePackages.breeze
      kdePackages.breeze-gtk
      kdePackages.breeze-icons
      kdePackages.plasma-nm
      kdePackages.plasma-vault
      kdePackages.plasma-browser-integration
      kdePackages.kdeconnect-kde

      # System packages
      wayland
      libsForQt5.qt5.qtwayland
      qt6.qtwayland
      xdg-utils
      xdg-desktop-portal
      xdg-desktop-portal-kde
      libsForQt5.polkit-kde-agent

      # GPU packages
      glxinfo
      vulkan-tools
      vulkan-loader
      vulkan-validation-layers
      nvidia-vaapi-driver
    ];
  };

  # XDG Portal configuration
  xdg.portal = {
    enable = true;
    extraPortals = [
      pkgs.xdg-desktop-portal-kde
      pkgs.xdg-desktop-portal-gtk
    ];
  };

  # Boot configuration
  boot = {
    extraModulePackages = [config.boot.kernelPackages.nvidia_x11];
    kernelParams = [
      "nvidia.NVreg_PreserveVideoMemoryAllocations=1"
      "nvidia-drm.modeset=1"
    ];
    kernelModules = ["nvidia" "nvidia_drm" "nvidia_modeset" "nvidia_uvm"];
  };

  # X server configuration for NVIDIA
  services.xserver.videoDrivers = ["nvidia"];

  # Enable required programs
  programs = {
    fish.enable = true;
    zsh.enable = true;
    dconf.enable = true;
  };

  # Docker configuration
  virtualisation.docker = {
    enable = true;
  };
}
