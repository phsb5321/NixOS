# NixOS Laptop Configuration - Working Config
# Synced from /etc/nixos/configuration.nix (the actual working system)
{
  config,
  pkgs,
  lib,
  systemVersion,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
  ];

  # Bootloader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "nixos-laptop";

  # Enable networking
  networking.networkmanager.enable = true;

  # Enable WiFi firmware and drivers - CRITICAL FOR WIFI
  hardware.enableRedistributableFirmware = true;

  # Enable iwd backend for better WiFi support
  networking.networkmanager.wifi.backend = "iwd";

  # WiFi power management
  networking.networkmanager.wifi.powersave = false;

  # Set your time zone
  time.timeZone = "America/Recife";

  # Select internationalisation properties
  i18n.defaultLocale = "en_US.UTF-8";

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

  # Enable the X11 windowing system
  services.xserver.enable = true;

  # Enable the GNOME Desktop Environment (using new option paths)
  services.displayManager.gdm.enable = true;
  services.desktopManager.gnome.enable = true;

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "br";
    variant = "";
  };

  # Configure console keymap
  console.keyMap = "br-abnt2";

  # Enable CUPS to print documents
  services.printing.enable = true;

  # Enable sound with pipewire
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # Enable docker
  virtualisation.docker.enable = true;

  # Enable zsh system-wide (required for user shell)
  programs.zsh.enable = true;

  # Define a user account
  users.users.notroot = {
    isNormalUser = true;
    description = "Pedro Balbino";
    shell = pkgs.zsh;  # Set zsh as default shell
    extraGroups = ["networkmanager" "wheel" "docker"];
    packages = with pkgs; [
      # ===== BROWSERS =====
      firefox
      google-chrome
      brave
      librewolf

      # ===== TERMINAL EMULATORS =====
      ghostty
      kitty
      alacritty
      gnome-terminal
      wezterm

      # ===== DEVELOPMENT TOOLS =====
      # Editors
      vscode
      neovim
      vim
      nano
      helix

      # Version Control
      git
      git-lfs
      gh
      glab
      lazygit
      delta
      gitg
      chezmoi

      # Runtimes & Languages
      nodejs
      python3
      python3Packages.pip
      rustc
      cargo
      go
      jdk17
      dotnet-runtime
      php
      ruby
      elixir
      lua
      zig

      # Language Servers
      rust-analyzer
      gopls
      nodePackages.typescript-language-server
      nodePackages.eslint
      nodePackages.prettier
      marksman
      taplo
      yaml-language-server
      vscode-langservers-extracted
      bash-language-server
      shfmt
      nixd
      nil
      pyright
      ruff
      black

      # Database
      sqlite
      sqlite-utils
      postgresql
      mariadb
      dbeaver-bin

      # API Tools
      insomnia
      postman
      httpie

      # Containers
      docker
      docker-compose
      podman

      # Build Tools
      cmake
      gnumake
      ninja
      meson

      # Modern Development Utilities
      typst
      just
      direnv
      jq
      yq

      # ===== MEDIA & COMMUNICATION =====
      vlc
      mpv
      celluloid
      obs-studio
      gimp
      blender
      krita
      kdePackages.kdenlive
      inkscape
      darktable
      rawtherapee

      # Communication
      discord
      telegram-desktop
      slack
      zoom-us
      signal-desktop
      element-desktop
      wasistlos

      # Music
      spotify
      audacity
      amberol
      lmms

      # ===== PRODUCTIVITY =====
      libreoffice
      onlyoffice-desktopeditors
      notion-app-enhanced
      obsidian
      logseq
      joplin-desktop
      evince
      kdePackages.okular
      zathura

      # ===== TERMINAL & CLI TOOLS =====
      zsh
      fish
      bash
      oh-my-zsh
      bat
      eza
      fd
      ripgrep
      fzf
      zoxide
      btop
      htop
      neofetch
      tree
      lsd
      vivid
      tldr
      ncdu
      duf
      dust
      procs
      bandwhich
      hyperfine

      # File Management
      ranger
      nemo
      yazi-unwrapped

      # Network Tools
      wget
      curl
      netcat-gnu
      nmap
      wireshark

      # Terminal Multiplexers
      tmux
      screen
      zellij

      # ===== UTILITIES =====
      unzip
      zip
      p7zip
      unrar
      gparted
      baobab
      gnupg
      keepassxc
      bitwarden-desktop
      lshw
      usbutils
      pciutils
      hwinfo

      # ===== GNOME EXTENSIONS & TOOLS =====
      gnome-tweaks
      dconf-editor
      gnome-extension-manager
      gnomeExtensions.user-themes
      gnomeExtensions.dash-to-dock
      gnomeExtensions.appindicator
      gnomeExtensions.vitals
      gnomeExtensions.clipboard-indicator
      gnomeExtensions.caffeine
      gnomeExtensions.workspace-indicator
      gnomeExtensions.sound-output-device-chooser
      gnomeExtensions.gsconnect
      gnomeExtensions.just-perfection

      # ===== GAMING =====
      steam
      lutris
      wine-staging
      winetricks
      protontricks
      steam-run
      dxvk
      corectrl
      prismlauncher

      # ===== AUDIO/VIDEO TOOLS =====
      audacity
      lmms
      easyeffects
      pavucontrol
      helvum
      ffmpeg
      handbrake

      # ===== FONTS =====
      nerd-fonts.jetbrains-mono
      noto-fonts-color-emoji
      noto-fonts
      noto-fonts-cjk-sans

      # ===== DEVELOPMENT ENVIRONMENTS =====
      alejandra
      nixfmt-classic

      # ===== SYSTEM MONITORING =====
      iotop
      atop
      smem
      stress-ng
      memtester

      # ===== ADDITIONAL TOOLS =====
      remmina
      texlive.combined.scheme-full
      ngrok
      syncthing
      iw
      iwgtk
      wpa_supplicant
      d2
      grc
      starship
      zsh-powerlevel10k
      zsh-syntax-highlighting
      zsh-autosuggestions
      zsh-you-should-use
      zsh-fast-syntax-highlighting
    ];
  };

  # Enable automatic login for the user
  services.displayManager.autoLogin.enable = true;
  services.displayManager.autoLogin.user = "notroot";

  # Workaround for GNOME autologin
  systemd.services."getty@tty1".enable = false;
  systemd.services."autovt@tty1".enable = false;

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # Enable additional services
  services.openssh.enable = true;

  # Enable flatpak
  services.flatpak.enable = true;

  # System state version
  system.stateVersion = systemVersion;
}
