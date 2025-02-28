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
      # Gaming Tools
      gamemode
      gamescope
      mangohud
      protontricks
      winetricks

      # System Utilities
      bleedPkgs.zed-editor
      guvcview
      obs-studio
      gimp
      calibre

      # Development Tools
      llvm
      clang

      # Additional Tools
      seahorse
      bleachbit
      lact
      speechd
      waydroid
      anydesk

      # AMD GPU and Video Tools
      pkgs.vulkan-tools
      pkgs.vulkan-loader
      pkgs.vulkan-validation-layers
      pkgs.libva-utils
      pkgs.vdpauinfo
      pkgs.glxinfo
      pkgs.ffmpeg-full

      # Bluetooth GUI manager
      blueman
    ];
  };

  # Set system options
  console.keyMap = "br-abnt2";
  users.defaultUserShell = pkgs.zsh;

  # Enable and configure desktop module
  modules.desktop = {
    enable = true;
    environment = "gnome"; # Changed from "kde" to "gnome"
    autoLogin = {
      enable = true;
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
    hostName = "default";
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
      openai-whisper
      python3
      android-tools
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
    ];
  };

  # Hardware configuration
  hardware = {
    enableRedistributableFirmware = true;
    bluetooth = {
      enable = true;
      powerOnBoot = true;
      disabledPlugins = ["sap"];
      settings = {
        General = {
          AutoEnable = "true";
          ControllerMode = "dual";
          Experimental = "true";
        };
      };
    };
    cpu.intel.updateMicrocode = true;
    graphics = {
      enable = true;
      enable32Bit = true;
      extraPackages = with pkgs; [
        amdvlk
        vaapiVdpau
        libvdpau-va-gl
      ];
    };
  };

  # Pulseaudio configuration (using PulseAudio, not PipeWire)
  services.pulseaudio = lib.mkForce {
    enable = true;
    package = pkgs.pulseaudioFull;
    extraConfig = "load-module module-switch-on-connect";
  };

  # Force disable PipeWire to resolve conflicting definitions
  services.pipewire.enable = lib.mkForce false;

  # Services configuration
  services = {
    syncthing = {
      enable = true;
      user = "notroot";
      dataDir = "/home/notroot/Sync";
      configDir = "/home/notroot/.config/syncthing";
      overrideDevices = true;
      overrideFolders = true;
    };

    fstrim.enable = true;
    thermald.enable = true;
    ollama.enable = false;
  };

  # Gaming configuration and other programs
  programs = {
    fish.enable = true;
    zsh.enable = true;
    nix-ld.enable = true;
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
    thunderbird.enable = true;
  };

  # LACT daemon service
  systemd.packages = with pkgs; [lact];
  systemd.services.lactd.wantedBy = ["multi-user.target"];

  # Security configuration
  security = {
    sudo.wheelNeedsPassword = true;
    auditd.enable = true;
    apparmor = {
      enable = true;
      killUnconfinedConfinables = true;
    };
    polkit.enable = true;
  };

  # SSH configuration
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = true;
      KbdInteractiveAuthentication = false;
    };
  };

  # Boot configuration
  boot = {
    kernelPackages = pkgs.linuxPackages_latest;
    kernelParams = [
      "mitigations=off"
      "amdgpu.ppfeaturemask=0xffffffff"
      "radeon.si_support=0"
      "amdgpu.si_support=1"
      "radeon.cik_support=0"
      "amdgpu.cik_support=1"
    ];
    tmp.useTmpfs = true;
  };

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
}
