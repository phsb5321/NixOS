# ~/NixOS/hosts/laptop/configuration.nix
{
  config,
  pkgs,
  lib,
  inputs,
  bleedPkgs,
  systemVersion,
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
    java = {
      enable = true;
      androidTools.enable = true;
    };
    extraSystemPackages = with pkgs; [
      # Development Tools
      llvm
      clang
      cudaPackages.cuda_nvcc
      cudaPackages.cuda_cudart
      cudaPackages.cuda_cccl
      nvtopPackages.full

      # System Utilities
      bleedPkgs.zed-editor
      guvcview
      obs-studio
      gimp

      # Additional Tools
      seahorse
      bleachbit
      speechd
      waydroid
      anydesk

      # NVIDIA and Graphics Tools
      vulkan-tools
      vulkan-loader
      vulkan-validation-layers
      libva-utils
      vdpauinfo
      glxinfo
      ffmpeg-full
      xorg.xrandr
      mesa
    ];
  };

  # Set system options
  console.keyMap = "br-abnt2";
  users.defaultUserShell = pkgs.zsh;

  # Enable and configure desktop module
  modules.desktop = {
    enable = true;
    environment = "kde";
    kde.version = "plasma5";
    autoLogin = {
      enable = true;
      user = "notroot";
    };
    extraPackages = with pkgs; [
      plasma5Packages.plasma-nm
      plasma5Packages.plasma-pa
      networkmanagerapplet
    ];
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

  # Enable and configure networking module
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
      openPorts = [22 3000];
      trustedInterfaces = [];
    };
  };

  # Enable the home module
  modules.home = {
    enable = true;
    username = "notroot";
    hostName = "laptop";
    extraPackages = with pkgs; [
      # Editors and IDEs
      vscode

      # Web Browsers
      google-chrome

      # API Testing
      insomnia
      postman

      # File Management
      gparted
      baobab
      syncthing
      vlc

      # System Utilities
      pigz
      mangohud
      unzip

      # Music Streaming
      spotify

      # Miscellaneous Tools
      lsof
      discord
      corectrl
      inputs.zen-browser.packages.${system}.default

      # Programming Languages
      python3
    ];
  };

  # Additional networking overrides if needed
  networking.networkmanager.dns = lib.mkForce "default";

  # Locale settings
  i18n.extraLocaleSettings = {
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

  # User configuration
  users.users.notroot = {
    isNormalUser = true;
    description = "Pedro Balbino";
    extraGroups = [
      "networkmanager"
      "wheel"
      "audio"
      "video"
      "disk"
      "input"
      "bluetooth"
      "docker"
      "dialout"
      "libvirtd"
      "kvm"
      "render"
      "nvidia"
    ];
  };

  # Hardware configuration
  hardware = {
    enableRedistributableFirmware = true;
    bluetooth = {
      enable = true;
      powerOnBoot = true;
    };
    cpu.intel.updateMicrocode = true;

    # Graphics configuration
    graphics = {
      enable = true;
      extraPackages = with pkgs; [
        intel-media-driver
        vaapiIntel
        vaapiVdpau
        libvdpau-va-gl
      ];
    };

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
        intelBusId = "PCI:0:2:0"; # Verify with `lspci` output
        nvidiaBusId = "PCI:1:0:0"; # Verify with `lspci` output
      };
      nvidiaSettings = true;
      forceFullCompositionPipeline = true;
    };
  };

  # Services configuration
  services = {
    xserver = {
      enable = true;
      videoDrivers = ["nvidia" "modesetting"]; # Replaced "intel" with "modesetting"
    };

    displayManager = {
      sddm = {
        enable = true;
        settings = {
          Theme = {
            Current = "breeze";
            CursorTheme = "breeze_cursors";
          };
        };
      };
      defaultSession = "plasma";
    };

    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      jack.enable = true;
    };

    power-profiles-daemon.enable = true;
    thermald.enable = true;
    fstrim.enable = true;
    acpid.enable = true;
    upower.enable = true;

    syncthing = {
      enable = true;
      user = "notroot";
      dataDir = "/home/notroot/Sync";
      configDir = "/home/notroot/.config/syncthing";
      overrideDevices = true;
      overrideFolders = true;
    };
  };

  # Environment configuration
  environment = {
    sessionVariables = {
      # Removed NIXOS_OZONE_WL unless explicitly needed
      CUDA_PATH = "${pkgs.cudaPackages.cuda_cudart}";
      LD_LIBRARY_PATH = lib.mkForce "/run/opengl-driver/lib:/run/opengl-driver-32/lib:${pkgs.pipewire}/lib";
      __NV_PRIME_RENDER_OFFLOAD = "1";
      __NV_PRIME_RENDER_OFFLOAD_PROVIDER = "NVIDIA-G0";
      __GLX_VENDOR_LIBRARY_NAME = "nvidia";
      __VK_LAYER_NV_optimus = "NVIDIA_only";
      LIBVA_DRIVER_NAME = "nvidia";
      GBM_BACKEND = "nvidia-drm";
      WLR_NO_HARDWARE_CURSORS = "1";
      XDG_SESSION_TYPE = "x11";
      XDG_CURRENT_DESKTOP = "KDE";
      XDG_SESSION_DESKTOP = "KDE";
      KDE_FULL_SESSION = "true";
    };

    systemPackages = with pkgs; [
      # Graphics and Display
      glxinfo
      vulkan-tools
      vulkan-loader
      vulkan-validation-layers
      nvidia-vaapi-driver
      libva
      libva-utils

      # System Tools
      xorg.xrandr
      mesa
    ];
  };

  # Gaming configuration
  programs = {
    fish.enable = true;
    zsh.enable = true;
    steam = {
      enable = true;
      remotePlay.openFirewall = true;
      dedicatedServer.openFirewall = true;
    };
    corectrl = {
      enable = true;
      gpuOverclock = {
        enable = true;
        ppfeaturemask = "0xffffffff";
      };
    };
    dconf.enable = true;
  };

  # Security configuration
  security = {
    sudo.wheelNeedsPassword = true;
    auditd.enable = true;
    apparmor = {
      enable = true;
      killUnconfinedConfinables = true;
    };
    polkit.enable = true;
    rtkit.enable = true;
    pam = {
      services = {
        login.enableGnomeKeyring = true;
        sddm.enableGnomeKeyring = true;
      };
    };
  };

  # Boot configuration
  boot = {
    kernelPackages = pkgs.linuxPackages_latest;
    kernelParams = [
      "nvidia.NVreg_PreserveVideoMemoryAllocations=1"
      "nvidia-drm.modeset=1"
    ];
    kernelModules = ["nvidia" "nvidia_drm" "nvidia_modeset" "nvidia_uvm"];
    extraModulePackages = [config.boot.kernelPackages.nvidia_x11];
    tmp.useTmpfs = true;
  };

  # Enable virtualization support
  virtualisation = {
    docker = {
      enable = true;
      daemon.settings = {
        dns = ["8.8.8.8" "8.8.4.4"];
      };
      rootless = {
        enable = true;
        setSocketVariable = true;
      };
    };
  };
  hardware.nvidia-container-toolkit.enable = true;

  # SSH configuration
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = true;
      KbdInteractiveAuthentication = false;
    };
  };

  # System maintenance and cleanup
  nix = {
    settings = {
      auto-optimise-store = true;
      experimental-features = ["nix-command" "flakes"];
    };
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 30d";
    };
  };
}
