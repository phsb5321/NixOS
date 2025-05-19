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
      nvtopPackages.full # Keep for monitoring
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

      # Debugging tools
      pciutils
      glxinfo

      # Make sure bash is in system packages
      bash
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

  # User configuration - Use bash for now until ZSH is fixed
  users = {
    defaultUserShell = "${pkgs.zsh}/bin/zsh";
    users.notroot = {
      isNormalUser = true;
      description = "Pedro Balbino";
      initialPassword = "changeme";
      # Explicitly set the shell with full path to zsh
      shell = "${pkgs.zsh}/bin/zsh";
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

  # Register shells with explicit paths
  environment.shells = [
    "${pkgs.bash}/bin/bash"
    "${pkgs.zsh}/bin/zsh"
    "${pkgs.fish}/bin/fish"
  ];

  # Hardware configuration - Switch to Intel only
  hardware = {
    enableRedistributableFirmware = true;
    cpu.intel.updateMicrocode = true;
    graphics = {
      enable = true;
      enable32Bit = true;
      extraPackages = with pkgs; [
        intel-media-driver
        vaapiIntel
        libvdpau-va-gl
      ];
    };
  };

  # Nixpkgs configuration
  nixpkgs.config = {
    allowUnfree = true;
  };

  # Services configuration with PipeWire enabled
  services = {
    # Fix the renamed option
    displayManager.defaultSession = "gnome";

    xserver = {
      enable = true;
      displayManager = {
        gdm = {
          enable = true;
          wayland = true;
          settings = {};
        };
      };
      # Use Intel driver only
      videoDrivers = ["intel"];
      desktopManager.gnome.enable = true;

      # Use Intel graphics configuration
      deviceSection = ''
        Option "TearFree" "true"
        Option "DRI" "3"
        Option "AccelMethod" "sna"
      '';
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

    # OpenSSH with enhanced shell handling
    openssh = {
      enable = true;
      settings = {
        PermitRootLogin = "no";
        PasswordAuthentication = true;
        KbdInteractiveAuthentication = false;
        UsePAM = true;
      };
    };
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

  # Environment configuration - Updated for Intel only graphics
  environment = {
    sessionVariables = {
      # Use Wayland with GNOME
      XDG_SESSION_TYPE = "wayland";
      # Remove NVIDIA variables
      LD_LIBRARY_PATH = lib.mkForce "/run/opengl-driver/lib:/run/opengl-driver-32/lib:${pkgs.pipewire}/lib";
      LIBVA_DRIVER_NAME = "iHD"; # Intel VAAPI driver

      # Wayland-specific variables
      SDL_VIDEODRIVER = "wayland";
      GDK_BACKEND = "wayland";
      MOZ_ENABLE_WAYLAND = "1";
      QT_QPA_PLATFORM = "wayland";
      CLUTTER_BACKEND = "wayland";

      # Set explicit shell for better compatibility
      SHELL = "${pkgs.zsh}/bin/zsh";
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
      xdg-desktop-portal-gnome
      glxinfo
      vulkan-tools
      vulkan-loader
      vulkan-validation-layers
      mesa-demos
      pciutils
      usbutils
      lshw
      xorg.xrandr
      xorg.xinput
    ];
  };

  # XDG Portal configuration
  xdg.portal = {
    enable = true;
    extraPortals = [
      pkgs.xdg-desktop-portal-gtk
      pkgs.xdg-desktop-portal-gnome
    ];
    # Enable Wayland portal
    wlr.enable = true;
  };

  # Boot configuration – use blacklisted kernel modules to disable NVIDIA
  boot = {
    blacklistedKernelModules = [
      "nouveau"
      "nvidia"
      "nvidia_drm"
      "nvidia_modeset"
      "nvidia_uvm"
    ];

    kernelParams = [
      # Add Intel-specific parameters
      "i915.enable_fbc=1"
      "i915.enable_psr=2"
      "i915.enable_hd_vgaarb=1" # Enable HDMI audio for Intel
      "i915.enable_dc=2" # Improved display connection handling
    ];

    # Focus on Intel modules
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
