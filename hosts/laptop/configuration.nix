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

      # Additional Tools
      bleachbit
      speechd

      # PipeWire Tools
      pipewire
      wireplumber
      easyeffects
      helvum
      pavucontrol
    ];
  };

  # Enable and configure desktop module (using GNOME now)
  modules.desktop = {
    enable = true;
    environment = "gnome"; # switched from "kde" to "gnome"
    autoLogin = {
      enable = true;
      user = "notroot";
    };
    fonts = {
      enable = true;
      packages = with pkgs; [nerd-fonts.jetbrains-mono];
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
    ];
  };

  # Locale settings
  i18n = {
    defaultLocale = "en_US.UTF-8";
    supportedLocales = ["en_US.UTF-8/UTF-8" "pt_BR.UTF-8/UTF-8" "C.UTF-8/UTF-8"];
    glibcLocales = pkgs.glibcLocales;
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
    graphics = {
      enable = true;
      enable32Bit = true;
      extraPackages = with pkgs; [intel-media-driver vaapiIntel vaapiVdpau libvdpau-va-gl];
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
        intelBusId = "PCI:0:2:0";
        nvidiaBusId = "PCI:1:0:0";
      };
      nvidiaSettings = true;
      forceFullCompositionPipeline = true;
    };
    nvidia-container-toolkit.enable = true;
  };

  # Nixpkgs configuration
  nixpkgs.config = {
    allowUnfree = true;
    cudaSupport = true;
  };

  # Services configuration with PipeWire
  services = {
    xserver = {
      enable = true;
      displayManager = {
        defaultSession = "gnome";
        gdm = {
          enable = true;
          wayland = true;
          settings = {};
        };
      };
      desktopManager.gnome.enable = true; # This is the correct path
    };
    dbus = {
      enable = true;
      packages = [pkgs.dconf];
    };
    # Enable PipeWire with standard settings
    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      jack.enable = true;
      wireplumber.enable = true;
    };
    # Disable PulseAudio
    pulseaudio.enable = lib.mkForce false;
    accounts-daemon.enable = true;
    upower.enable = true;
    udisks2.enable = true;
    gvfs.enable = true;
    tumbler.enable = true;
    gnome.gnome-keyring.enable = true;
  };

  # Security and authentication
  security = {
    pam = {
      services = {
        sddm.enableKwallet = true;
        sddm-greeter.enableKwallet = true;
        login.enableGnomeKeyring = true;
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
      LANG = "en_US.UTF-8";
      LC_ALL = "en_US.UTF-8";
    };
    systemPackages = with pkgs; [
      gnome-shell
      gnome-shell-extensions
      gnome-tweaks
      gnomeExtensions.dash-to-dock
      gnomeExtensions.clipboard-indicator
      gnomeExtensions.sound-output-device-chooser
      gnomeExtensions.gsconnect
      gnomeExtensions.blur-my-shell
      networkmanager
      wpa_supplicant
      linux-firmware
      wayland
      xdg-utils
      xdg-desktop-portal
      xdg-desktop-portal-gtk
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
      pkgs.xdg-desktop-portal-gtk
      pkgs.kdePackages.xdg-desktop-portal-kde
    ];
    # Enable wlr portal for better screen sharing support
    wlr.enable = true;
  };

  # Boot configuration – ensure EFI mount point is correct
  boot = {
    extraModulePackages = [config.boot.kernelPackages.nvidia_x11];
    kernelParams = [
      "nvidia.NVreg_PreserveVideoMemoryAllocations=1"
      "nvidia-drm.modeset=1"
    ];
    kernelModules = ["nvidia" "nvidia_drm" "nvidia_modeset" "nvidia_uvm"];
    loader = {
      systemd-boot.enable = true;
      efi = {
        canTouchEfiVariables = true;
        efiSysMountPoint = "/boot"; # Adjust as needed
      };
    };
  };

  services.xserver.videoDrivers = ["nvidia"];

  programs = {
    fish.enable = true;
    zsh.enable = true;
    dconf.enable = true;
    gnupg.agent = {
      enable = true;
      enableSSHSupport = true;
    };
  };

  virtualisation.docker = {enable = true;};

  # Tailscale
  services.tailscale.enable = true;
}
