# ~/NixOS/hosts/laptop/configuration.nix
{
  config,
  pkgs,
  lib,
  inputs,
  hostname,
  systemVersion,
  bleedPkgs,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
  ];

  # 🎯 HOME MANAGER: User-specific configuration
  home-manager = {
    backupFileExtension = "backup";
    users.notroot = {
      home.username = "notroot";
      home.homeDirectory = "/home/notroot";
      home.stateVersion = systemVersion;
      
      # Import laptop-specific home configuration
      imports = [
        ../../modules/home/hosts/laptop.nix
      ];
    };
  };

  # Host-specific metadata and system configuration
  system.stateVersion = systemVersion;
  time.timeZone = "America/Recife";
  i18n.defaultLocale = "en_US.UTF-8";

  # Allow unfree packages (required for NVIDIA drivers and other software)
  nixpkgs.config.allowUnfree = true;

  # 🎯 CORE: Essential system configuration
  boot = {
    loader.systemd-boot.enable = true;
    loader.efi.canTouchEfiVariables = true;
    
    # Blacklist nouveau to prevent conflicts with NVIDIA
    blacklistedKernelModules = ["nouveau"];
    
    # Performance kernel parameters
    kernel.sysctl = {
      # VM optimizations
      "vm.swappiness" = 10;
      "vm.dirty_ratio" = 15;
      "vm.dirty_background_ratio" = 5;
      "vm.vfs_cache_pressure" = 50;
      # Network performance
      "net.core.rmem_max" = 268435456;
      "net.core.wmem_max" = 268435456;
      "net.core.netdev_max_backlog" = 5000;
      # Security hardening
      "kernel.dmesg_restrict" = 1;
      "kernel.kptr_restrict" = 2;
      "net.ipv4.conf.all.log_martians" = 1;
      "net.ipv4.conf.default.log_martians" = 1;
      "net.ipv4.icmp_echo_ignore_broadcasts" = 1;
      "net.ipv4.conf.all.send_redirects" = 0;
      "net.ipv4.conf.default.send_redirects" = 0;
    };
    
    # NVIDIA-specific kernel parameters
    kernelParams = [
      "nvidia.NVreg_UsePageAttributeTable=1"
      "nvidia.NVreg_PreserveVideoMemoryAllocations=1"
      "nvidia.NVreg_TemporaryFilePath=/tmp"
    ];
    
    # Enable ZRAM for better memory management
    kernelModules = ["zram"];
  };

  # ZRAM configuration for improved performance
  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 25;
  };

  # 🎯 NETWORKING: Integrated networking configuration
  networking = {
    hostName = hostname;
    networkmanager.enable = true;
    
    firewall = {
      enable = true;
      allowPing = true;
      allowedTCPPorts = [22]; # SSH
    };
  };

  # DNS configuration
  services.resolved = {
    enable = true;
    fallbackDns = ["1.1.1.1" "1.0.0.1" "8.8.8.8" "8.8.4.4"];
    domains = ["~."];
    extraConfig = ''
      DNS=1.1.1.1#cloudflare-dns.com 1.0.0.1#cloudflare-dns.com
      DNSOverTLS=yes
    '';
  };

  # 🎯 CORE: Users and security
  users = {
    defaultUserShell = pkgs.zsh;
    users.notroot = {
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
        "render"
        "kvm"
        "pipewire"
      ];
    };
  };

  # Security configuration
  security = {
    sudo.wheelNeedsPassword = true;
    polkit.enable = true;
    rtkit.enable = true;
  };

  # 🎯 HARDWARE: Graphics and NVIDIA configuration
  hardware = {
    enableRedistributableFirmware = true;
    
    graphics = {
      enable = true;
      enable32Bit = true;
      extraPackages = with pkgs; [
        # Intel graphics drivers and acceleration
        intel-media-driver      # Modern iHD driver for Gen 8+
        intel-vaapi-driver     # Legacy i965 driver for compatibility
        
        # General acceleration and Vulkan
        mesa
        vulkan-loader
        vulkan-validation-layers
      ];
      # 32-bit support for compatibility
      extraPackages32 = with pkgs.pkgsi686Linux; [
        intel-vaapi-driver
        mesa
        vulkan-loader
      ];
    };
    
    # NVIDIA GPU Configuration
    nvidia = {
      modesetting.enable = true;
      powerManagement.enable = false;
      powerManagement.finegrained = true;
      open = true; # Use open drivers for Turing architecture
      nvidiaSettings = true;
      package = config.boot.kernelPackages.nvidiaPackages.stable;
      
      prime = {
        offload = {
          enable = true;
          enableOffloadCmd = false; # Disable to prevent conflicts with specializations
        };
        intelBusId = "PCI:0:2:0";
        nvidiaBusId = "PCI:1:0:0";
      };
    };
    
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
  };
  # 🎯 SERVICES: Essential services configuration
  services = {
    xserver = {
      enable = true;
      videoDrivers = ["nvidia"];
      desktopManager.gnome.enable = true;
      displayManager.gdm = {
        enable = true;
        wayland = false; # Use X11 for better stability
      };
      
      # Keyboard layout configuration
      xkb = {
        layout = "br";
        variant = "abnt2";
        model = "pc104";
        options = "grp:alt_shift_toggle,compose:ralt";
      };
    };
    
    # GNOME services
    gnome = {
      core-shell.enable = true;
      core-os-services.enable = true;
      core-apps.enable = true;
      gnome-keyring.enable = true;
      gnome-settings-daemon.enable = true;
      evolution-data-server.enable = true;
      glib-networking.enable = true;
      tinysparql.enable = true;
      localsearch.enable = true;
      sushi.enable = true;
    };
    
    # Ensure correct input method configuration
    xserver.desktopManager.gnome.extraGSettingsOverrides = ''
      [org.gnome.desktop.input-sources]
      sources=[('xkb', 'br+abnt2')]
      xkb-options=['grp:alt_shift_toggle','compose:ralt']
      
      [org.gnome.desktop.peripherals.keyboard]
      numlock-state=true
    '';
    
    # Force X11 keyboard layout to be applied consistently
    xserver.displayManager.sessionCommands = ''
      ${pkgs.xorg.setxkbmap}/bin/setxkbmap -layout br -variant abnt2 -option "grp:alt_shift_toggle,compose:ralt"
    '';
    
    # Audio system
    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      wireplumber.enable = true;
      jack.enable = true;
    };
    
    # Essential system services
    openssh = {
      enable = true;
      settings = {
        PermitRootLogin = "no";
        PasswordAuthentication = true;
        KbdInteractiveAuthentication = false;
      };
    };
    
    fstrim.enable = true;
    thermald.enable = true;
    printing.enable = true;
    upower.enable = true;
    geoclue2.enable = true;
    
    # Laptop power management (use TLP instead of power-profiles-daemon)
    power-profiles-daemon.enable = false; # Explicitly disable to prevent conflicts with TLP
    tlp = {
      enable = true;
      settings = {
        CPU_SCALING_GOVERNOR_ON_AC = "performance";
        CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
      };
    };
  };
  # Console keyboard layout
  console.keyMap = "br-abnt2";

  # Input method configuration
  i18n.inputMethod = {
    enabled = null; # Use default input method
  };

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

  # Programs configuration
  programs = {
    zsh.enable = true;
    nix-ld.enable = true;
    dconf.enable = true;
    firefox.enable = true;
    thunderbird.enable = true;
    steam = {
      enable = true;
      remotePlay.openFirewall = true;
      dedicatedServer.openFirewall = true;
    };
    gamemode.enable = true;
  };

  # Laptop-specific configurations (moved from Home Manager)
  environment.etc = {
    # Power management configuration for laptop
    "powertop/powertop.conf".text = ''
      # Laptop power optimization
      echo 'auto' > '/sys/bus/pci/devices/0000:00:1f.3/power/control'
      echo 'auto' > '/sys/bus/i2c/devices/i2c-0/device/power/control'
    '';
  };

  # Laptop-specific services (moved from Home Manager)
  services.redshift = {
    enable = true;
    temperature = {
      day = 6500;
      night = 4500;
    };
    brightness = {
      day = "1";
      night = "0.8";
    };
  };

  # Location for redshift
  location.provider = "geoclue2";

  # 🎯 SYSTEM PACKAGES: Core tools, gaming, and applications
  environment.systemPackages = with pkgs; [
    # Essential system tools
    wget
    vim
    curl
    git
    tree
    htop
    btop
    neofetch
    file
    which
    lsof
    rsync
    unzip
    p7zip
    gum # TUI toolkit for beautiful scripts
    
    # Development tools
    nodejs_22
    go
    elixir
    
    # Network tools
    dig
    nmap
    networkmanager
    networkmanagerapplet
    
    # NVIDIA tools and gaming
    (writeShellScriptBin "nvidia-offload" ''
      export __NV_PRIME_RENDER_OFFLOAD=1
      export __NV_PRIME_RENDER_OFFLOAD_PROVIDER=NVIDIA-G0
      export __GLX_VENDOR_LIBRARY_NAME=nvidia
      export __VK_LAYER_NV_optimus=NVIDIA_only
      exec "$@"
    '')
    vulkan-tools
    glxinfo
    glmark2
    
    # Gaming packages
    lutris
    mangohud
    vkBasalt
    gamemode
    libstrangle
    vulkan-loader
    vulkan-validation-layers
    mesa-demos
    protontricks
    winetricks
    wine-staging
    bottles
    heroic
    legendary-gl
    
    # GNOME applications
    gnome-tweaks
    gnome-extension-manager
    dconf-editor
    gnome-calculator
    gnome-calendar
    gnome-contacts
    gnome-maps
    gnome-weather
    gnome-music
    gnome-photos
    gnome-text-editor
    simple-scan
    seahorse
    file-roller
    
    # Essential desktop applications
    firefox
    libreoffice
    thunderbird
    vlc
    pavucontrol
    
    # System monitoring
    nvtopPackages.full
    gnome-system-monitor
    gnome-disk-utility
    
    # Terminal
    kitty
    
    # Graphics and font utilities
    gnome-font-viewer
    font-manager
    gucharmap
    
    # Additional utilities
    celluloid # Video player
    
    # Laptop-specific packages (moved from Home Manager)
    dbeaver-bin
    amberol # Lightweight music player
    vlc
    discord
    telegram-desktop
    libreoffice
    remmina
    ngrok
    brightnessctl
    acpi
    powertop
    tlp
    texlive.combined.scheme-full
    zellij
    tmux
    
    # Core development tools
    gh
    git-crypt
    gnupg
    ripgrep
    fd
    jq
    yq
    
    # Fonts
    nerd-fonts.jetbrains-mono
    nerd-fonts.fira-code
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-emoji
    liberation_ttf
  ];

  # Environment variables
  environment.sessionVariables = {
    # Nvidia-specific environment variables
    __GL_SHADER_DISK_CACHE = "1";
    __GL_SHADER_DISK_CACHE_PATH = "$HOME/.cache/nvidia-shader-cache";
    
    # Keyboard layout environment variables
    XKB_DEFAULT_LAYOUT = "br";
    XKB_DEFAULT_VARIANT = "abnt2";
    XKB_DEFAULT_OPTIONS = "grp:alt_shift_toggle,compose:ralt";
    
    # Wayland/X11 compatibility
    GDK_BACKEND = "x11";
    QT_QPA_PLATFORM = "xcb";
    
    # Cursor theme
    XCURSOR_THEME = "Adwaita";
    XCURSOR_SIZE = "24";
    
    # Font rendering
    FONTCONFIG_FILE = "${pkgs.fontconfig.out}/etc/fonts/fonts.conf";
    
    # Laptop-specific environment variables (moved from Home Manager)
    POWERTOP_ENABLE = "1";
    DOCKER_BUILDKIT = "1";
    COMPOSE_DOCKER_CLI_BUILD = "1";
    TERM = "xterm-256color";
    COLORTERM = "truecolor";
  };

  # Systemd service to ensure ABNT2 keyboard layout persists
  systemd.user.services.fix-keyboard-layout = {
    description = "Fix ABNT2 keyboard layout";
    after = [ "graphical-session.target" ];
    wantedBy = [ "default.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${pkgs.writeShellScript "fix-keyboard" ''
        # Wait for GNOME to fully load
        sleep 3
        
        # Apply X11 keyboard layout
        ${pkgs.xorg.setxkbmap}/bin/setxkbmap -layout br -variant abnt2 -option "grp:alt_shift_toggle,compose:ralt"
        
        # Apply GNOME settings
        ${pkgs.glib}/bin/gsettings set org.gnome.desktop.input-sources sources "[('xkb', 'br+abnt2')]"
        ${pkgs.glib}/bin/gsettings set org.gnome.desktop.input-sources xkb-options "['grp:alt_shift_toggle','compose:ralt']"
      ''}";
    };
  };

  # Virtualization
  virtualisation = {
    docker = {
      enable = true;
      daemon.settings.features.cdi = true;
    };
    containers.enable = true;
  };

  # XDG Portal configuration
  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-gnome
    ];
  };

  # Gaming specializations for different usage scenarios
  specialisation = {
    # High-performance mode with PRIME sync
    performance.configuration = {
      system.nixos.tags = ["performance"];
      hardware.nvidia.prime.sync.enable = lib.mkForce true;
      hardware.nvidia.prime.offload.enable = lib.mkForce false;
      hardware.nvidia.prime.offload.enableOffloadCmd = lib.mkForce false;
      hardware.nvidia.powerManagement.finegrained = lib.mkForce false;
      powerManagement.cpuFreqGovernor = lib.mkForce "performance";
      services.tlp.enable = lib.mkForce false;
    };
    
    # Battery-saving mode
    battery.configuration = {
      system.nixos.tags = ["battery"];
      hardware.nvidia.prime.offload.enable = lib.mkForce true;
      hardware.nvidia.prime.offload.enableOffloadCmd = lib.mkForce true;
      hardware.nvidia.prime.sync.enable = lib.mkForce false;
      hardware.nvidia.powerManagement.finegrained = lib.mkForce true;
      powerManagement.cpuFreqGovernor = lib.mkForce "powersave";
      services.tlp.enable = lib.mkForce true;
    };
  };
}
