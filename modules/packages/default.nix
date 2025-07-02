# ~/NixOS/modules/packages/default.nix
{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
with lib; let
  cfg = config.modules.packages;
in {
  options.modules.packages = {
    enable = mkEnableOption "shared packages module";

    # Browser packages
    browsers = {
      enable = mkEnableOption "browser packages";
      packages = mkOption {
        type = types.listOf types.package;
        default = with pkgs; [
          google-chrome
          brave
          librewolf
          inputs.zen-browser.packages.${pkgs.system}.default
        ];
        description = "List of browser packages to install";
      };
    };

    # Development tools
    development = {
      enable = mkEnableOption "development tools";
      packages = mkOption {
        type = types.listOf types.package;
        default = with pkgs; [
          # Code editors (VSCode manages its own extensions)
          vscode
          code-cursor

          # API testing and development
          bruno # Open-source API client (Postman alternative)
          bruno-cli # Bruno command-line interface

          # Language runtimes and package managers
          nodejs # Node.js runtime
          python3 # Python 3 interpreter
          rustc # Rust compiler
          cargo # Rust package manager
          go # Go programming language
          openjdk # OpenJDK Java runtime

          # Development tools and compilers
          android-tools # Android development tools
          llvm # LLVM compiler infrastructure
          clang # C/C++ compiler
          gcc # GNU Compiler Collection
          gdb # GNU Debugger
          cmake # Cross-platform build system
          ninja # Small build system with focus on speed
          pkg-config # Package configuration tool

          # Version control and collaboration
          gh # GitHub CLI
          glab # GitLab CLI
          lazygit # Simple terminal UI for git commands

          # Modern development utilities
          typst # Modern typesetting system
          just # Command runner (make alternative)
          direnv # Environment variable manager per directory
          httpie # User-friendly CLI HTTP client
          jq # Command-line JSON processor
          yq # YAML processor (jq for YAML)

          # Database tools
          sqlite # Lightweight database
          sqlite-utils # SQLite command-line utilities

          # Container and cloud tools
          docker-compose # Define and run multi-container applications
          kubectl # Kubernetes command-line tool

          # Performance and debugging
          valgrind # Memory debugging tools
          strace # System call tracer
          ltrace # Library call tracer
          perf-tools # Performance analysis tools

          # Network tools
          nmap # Network scanner
          wireshark # Network protocol analyzer
          tcpdump # Network packet analyzer
        ];
        description = "List of development packages to install";
      };
    };

    # Media and entertainment
    media = {
      enable = mkEnableOption "media packages";
      packages = mkOption {
        type = types.listOf types.package;
        default = with pkgs; [
          vlc
          spotify
          discord
          obs-studio
          gimp
        ];
        description = "List of media packages to install";
      };
    };

    # System utilities
    utilities = {
      enable = mkEnableOption "system utilities";
      packages = mkOption {
        type = types.listOf types.package;
        default = with pkgs; [
          gparted
          baobab
          syncthing
          pigz
          unzip
          lsof
          seahorse
          bleachbit
          # PDF viewer (modern Qt 6 version)
          kdePackages.okular
          
          # Font packages to fix UI cramping issues
          corefonts # Microsoft Core Fonts
          vistafonts # Microsoft Vista fonts
          cantarell-fonts # GNOME default fonts
          liberation_ttf # Microsoft font alternatives
          noto-fonts # Google Noto fonts
          noto-fonts-cjk-sans # CJK character support
          noto-fonts-emoji # Emoji support
        ];
        description = "List of utility packages to install";
      };
    };

    # Gaming packages
    gaming = {
      enable = mkEnableOption "gaming packages";
      packages = mkOption {
        type = types.listOf types.package;
        default = with pkgs; [
          gamemode
          gamescope
          mangohud
          protontricks
          winetricks
          corectrl
          btop # System monitoring
          heroic # Epic Games launcher
          lutris # Gaming platform
          steam-run # Run non-Steam games with Steam runtime
          wine-staging # Latest Wine with staging patches
          dxvk # DirectX to Vulkan
        ];
        description = "List of gaming packages to install";
      };
    };

    # Audio/Video tools
    audioVideo = {
      enable = mkEnableOption "audio/video tools";
      packages = mkOption {
        type = types.listOf types.package;
        default = with pkgs; [
          pipewire
          wireplumber
          easyeffects
          pavucontrol
          helvum
          guvcview
        ];
        description = "List of audio/video packages to install";
      };
    };

    # Python with common packages
    python = {
      enable = mkEnableOption "Python with common packages";
      withGTK = mkEnableOption "Include GTK support for Python";
      package = mkOption {
        type = types.package;
        default =
          if cfg.python.withGTK
          then
            pkgs.python3.withPackages (ps:
              with ps; [
                pygobject3
                pycairo
                dbus-python
                python-dbusmock
              ])
          else pkgs.python3;
        description = "Python package with optional GTK support";
      };
    };

    # Additional packages that can be enabled per host
    extraPackages = mkOption {
      type = types.listOf types.package;
      default = [];
      description = "Additional packages specific to this host";
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with cfg;
      (optionals browsers.enable browsers.packages)
      ++ (optionals development.enable development.packages)
      ++ (optionals media.enable media.packages)
      ++ (optionals utilities.enable utilities.packages)
      ++ (optionals gaming.enable gaming.packages)
      ++ (optionals audioVideo.enable audioVideo.packages)
      ++ (optionals python.enable [python.package])
      ++ extraPackages;
  };
}
