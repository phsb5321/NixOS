# ~/NixOS/hosts/default/configuration.nix
{
  pkgs,
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

  # Minimal GNOME setup following NixOS wiki recommendations
  services.displayManager.gdm.enable = true;
  services.desktopManager.gnome.enable = true;

  # Simple AMD GPU support
  boot.initrd.kernelModules = ["amdgpu"];
  services.xserver.videoDrivers = ["amdgpu"];

  # Comprehensive GNOME extensions and applications
  environment.systemPackages = with pkgs; [
    # Core GNOME applications
    gnome-text-editor
    gnome-calculator
    gnome-calendar
    gnome-contacts
    gnome-maps
    gnome-weather
    gnome-music
    gnome-photos
    simple-scan
    seahorse # Keyring management

    # GNOME utilities
    gnome-tweaks
    gnome-extension-manager
    dconf-editor

    # File management
    file-roller # Archive manager

    # Multimedia
    celluloid # Modern video player

    # Essential GNOME extensions - Core functionality
    gnomeExtensions.dash-to-dock
    gnomeExtensions.user-themes
    gnomeExtensions.just-perfection

    # System monitoring extensions - Multiple options for comprehensive monitoring
    gnomeExtensions.vitals # Temperature, voltage, fan speed, memory, CPU, network, storage
    gnomeExtensions.system-monitor-next # Classic system monitor with graphs
    gnomeExtensions.tophat # Elegant system resource monitor
    gnomeExtensions.resource-monitor # Real-time monitoring in top bar

    # Productivity and customization extensions
    gnomeExtensions.caffeine # Prevent screen lock
    gnomeExtensions.appindicator # System tray support
    gnomeExtensions.blur-my-shell # Blur effects for shell elements
    gnomeExtensions.clipboard-indicator # Clipboard manager
    gnomeExtensions.night-theme-switcher # Automatic dark/light theme switching
    gnomeExtensions.gsconnect # Phone integration (KDE Connect)
    
    # Workspace and window management
    gnomeExtensions.workspace-indicator # Better workspace indicator
    gnomeExtensions.advanced-alttab-window-switcher # Enhanced Alt+Tab
    
    # Quick access and navigation
    gnomeExtensions.places-status-indicator # Quick access to bookmarks
    gnomeExtensions.removable-drive-menu # USB drive management
    gnomeExtensions.sound-output-device-chooser # Audio device switching
    
    # Visual enhancements
    gnomeExtensions.weather-or-not # Weather in top panel
    
    # Additional useful extensions
    gnomeExtensions.clipboard-history # Enhanced clipboard manager
    gnomeExtensions.panel-workspace-scroll # Scroll on panel to switch workspaces

    # Essential system packages for desktop functionality
    xdg-utils
    glib
    gsettings-desktop-schemas

    # AMD GPU tools
    vulkan-tools
    vulkan-loader
    vulkan-validation-layers
    libva-utils
    vdpauinfo
    glxinfo
    mesa-demos
    clinfo
  ];

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

  # Additional development and media packages
  modules.packages.extraPackages = with pkgs; [
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

  # Boot configuration
  boot = {
    kernelPackages = pkgs.linuxPackages_latest;
    tmp.useTmpfs = true;
    # AMD GPU kernel parameters are now handled by the hardware module
  };

  # Memory optimization - reduced swappiness for better performance
  boot.kernel.sysctl."vm.swappiness" = 10;

  # Disable unnecessary services for this host
  services.ollama.enable = false;
  services.tailscale.enable = false;
}
