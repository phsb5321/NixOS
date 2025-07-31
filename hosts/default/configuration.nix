# ~/NixOS/hosts/default/configuration.nix
{
  pkgs,
  lib,
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

  # Direct GNOME configuration - no desktop module
  # Force X11 session for AMD GPU compatibility
  services.xserver.enable = true;

  # Display manager configuration - Force X11 completely
  services.displayManager.gdm = {
    enable = true;
    wayland = false; # Force X11 only
    autoSuspend = true;
  };

  # Completely disable Wayland at system level
  environment.sessionVariables.WLR_NO_HARDWARE_CURSORS = "1";

  # Force applications to use X11
  environment.etc."environment".text = ''
    XDG_SESSION_TYPE=x11
    GDK_BACKEND=x11
    QT_QPA_PLATFORM=xcb
    WAYLAND_DISPLAY=
    MOZ_ENABLE_WAYLAND=0
    ELECTRON_OZONE_PLATFORM_HINT=x11
  '';

  # Desktop manager configuration
  services.desktopManager.gnome.enable = true;

  # Ensure only GDM is enabled
  services.displayManager.sddm.enable = false;

  # GNOME services - disable Wayland-specific services
  services.gnome = {
    core-shell.enable = true;
    core-os-services.enable = true;
    core-apps.enable = true;
    gnome-keyring.enable = true;
    gnome-settings-daemon.enable = true;
    evolution-data-server.enable = true;
    glib-networking.enable = true;
    sushi.enable = true;
    gnome-remote-desktop.enable = false; # Disable Wayland remote desktop
    gnome-user-share.enable = true;
    rygel.enable = true;
  };

  # Explicitly disable GNOME Wayland session
  services.desktopManager.gnome.sessionPath = [];
  environment.gnome.excludePackages = with pkgs; [
    gnome-shell-extensions
  ];

  # Essential services for GNOME
  services.geoclue2.enable = true;
  services.upower.enable = true;
  services.power-profiles-daemon.enable = true;
  services.thermald.enable = true;

  # Audio system
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    wireplumber.enable = true;
    jack.enable = true;
  };

  # Hardware support
  hardware.bluetooth.enable = true;
  services.blueman.enable = true;
  services.printing.enable = true;
  services.printing.drivers = with pkgs; [gutenprint hplip epson-escpr];
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
  };

  # Combined environment variables - Force X11, disable Wayland completely
  environment.sessionVariables = {
    # Force X11 session - NO WAYLAND
    XDG_SESSION_TYPE = "x11";
    GDK_BACKEND = "x11";
    QT_QPA_PLATFORM = "xcb";

    # Completely disable Wayland to prevent connection attempts
    WAYLAND_DISPLAY = "";
    MOZ_ENABLE_WAYLAND = "0";
    NIXOS_OZONE_WL = "0";
    ELECTRON_OZONE_PLATFORM_HINT = "x11";

    # AMD GPU configuration
    AMD_VULKAN_ICD = "RADV";
    VDPAU_DRIVER = "radeonsi";
    GALLIUM_DRIVER = "radeonsi";
    MESA_SHADER_CACHE_MAX_SIZE = "2G";
    MESA_DISK_CACHE_MAX_SIZE = "4G";

    # UI and theming
    XCURSOR_THEME = "Adwaita";
    XCURSOR_SIZE = "24";
    GSK_RENDERER = "gl";
    GNOME_SHELL_SLOWDOWN_FACTOR = "1";
    GNOME_SHELL_DISABLE_HARDWARE_ACCELERATION = "0";
  };

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

  # Direct AMD GPU configuration without module
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages = with pkgs; [
      mesa
      amdvlk
      vulkan-tools
      vulkan-loader
      vulkan-validation-layers
      libva-vdpau-driver
      libvdpau-va-gl
    ];
    extraPackages32 = with pkgs.driversi686Linux; [
      mesa
      amdvlk
    ];
  };

  # AMD GPU driver
  services.xserver.videoDrivers = ["amdgpu"];

  # AMD GPU kernel modules
  boot.initrd.kernelModules = ["amdgpu"];

  # AMD GPU kernel parameters (will be merged with boot config below)

  # Environment variables will be merged below

  # Desktop-specific packages
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

  # Boot configuration with AMD GPU parameters
  boot = {
    kernelPackages = pkgs.linuxPackages_latest;
    tmp.useTmpfs = true;
    kernelParams = [
      "mitigations=off"
      # AMD GPU parameters
      "amdgpu.ppfeaturemask=0xffffffff"
      "amdgpu.si_support=1"
      "amdgpu.cik_support=1"
      "amdgpu.audio=1"
      "amdgpu.dc=1"
      "amdgpu.dpm=1"
    ];
  };

  # Memory optimization - ZRAM completely removed due to application issues
  # zramSwap disabled - was causing application crashes and OOM issues

  # Reduced swappiness without ZRAM
  boot.kernel.sysctl."vm.swappiness" = 10;

  # Early OOM killer for memory pressure (disabled due to startup issues)
  # services.earlyoom.enable = false;

  # Disable unnecessary services for this host
  services.ollama.enable = false;
  services.tailscale.enable = false;
}
