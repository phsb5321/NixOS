# ~/NixOS/modules/packages/default.nix
{
  config,
  lib,
  pkgs,
  pkgs-unstable,
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
          # Code editors - use unstable for latest VS Code
          pkgs-unstable.vscode
          code-cursor # Temporarily disabled due to download issues

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
          mermaid-cli # Mermaid CLI for generating diagrams

          # Language servers for Zed Editor
          nixd # Nix language server
          nil # Alternative Nix language server
          nodePackages.typescript-language-server # TypeScript/JavaScript LSP
          nodePackages.eslint # JavaScript/TypeScript linter
          nodePackages.prettier # Code formatter
          marksman # Markdown language server
          taplo # TOML language server
          yaml-language-server # YAML language server
          vscode-langservers-extracted # HTML, CSS, JSON language servers
          bash-language-server # Bash language server
          shfmt # Shell script formatter
          rust-analyzer # Rust language server
          gopls # Go language server
          pyright # Python language server
          ruff # Python linter and formatter
          black # Python code formatter

          # Dotfiles management
          chezmoi # Manage your dotfiles across multiple machines

          # Version control and collaboration
          git # Git version control system
          git-lfs # Git Large File Storage
          gh # GitHub CLI
          glab # GitLab CLI
          lazygit # Simple terminal UI for git commands
          gitui # Terminal UI for git
          delta # Syntax-highlighting pager for git

          # Modern development utilities
          typst # Modern typesetting system
          just # Command runner (make alternative)
          direnv # Environment variable manager per directory
          httpie # User-friendly CLI HTTP client
          jq # Command-line JSON processor
          yq # YAML processor (jq for YAML)
          fd # Fast alternative to find
          ripgrep # Fast grep alternative
          bat # Cat with syntax highlighting
          eza # Modern ls replacement
          zoxide # Smart cd command
          fzf # Fuzzy finder
          tree # Directory tree viewer
          htop # Interactive process viewer
          btop # Modern htop alternative

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

          # Audio/Video development tools
          # audacity # Audio editor - temporarily disabled due to build issues
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
          spotify # Official Spotify client
          spot # Native GNOME Spotify client (lightweight)
          ncspot # Terminal-based Spotify client (minimal resources)
          vesktop # Better Discord client with Vencord built-in
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
          ferdium

          # Font packages to fix UI cramping issues
          # corefonts # Microsoft Core Fonts - temporarily disabled due to network issues
          # vistafonts # Microsoft Vista fonts - temporarily disabled due to network issues
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
          prismlauncher # Prism Launcher for Minecraft
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
            pkgs.python3.withPackages (
              ps:
                with ps; [
                  pygobject3
                  pycairo
                  dbus-python
                  python-dbusmock
                ]
            )
          else pkgs.python3;
        description = "Python package with optional GTK support";
      };
    };

    # Terminal and shell tools (migrated from home-manager)
    terminal = {
      enable = mkEnableOption "terminal and shell tools";
      packages = mkOption {
        type = types.listOf types.package;
        default = with pkgs; [
          # Fonts
          nerd-fonts.jetbrains-mono
          noto-fonts-emoji
          noto-fonts
          noto-fonts-cjk-sans

          # Shell and Terminal
          zsh
          oh-my-zsh # ZSH framework
          zsh-powerlevel10k # Powerlevel10k theme
          starship # Cross-shell prompt (alternative)
          grc # Generic colorizer
          eza # Modern ls replacement
          bat # Modern cat replacement
          vivid # LS_COLORS generator
          zsh-syntax-highlighting
          zsh-autosuggestions
          zsh-you-should-use
          zsh-fast-syntax-highlighting

          # Development Tools (basic ones not covered in development packages)
          ffmpeg # Media processing tool
          zoxide # Smart directory jumper
          neovim # Text editor (replaces nixvim)

          # Applications (from home-manager)
          yazi-unwrapped
          texlive.combined.scheme-full
          dbeaver-bin
          amberol
          remmina
          obsidian
          d2
          ngrok
          zellij
          # vscode removed from here as it's already in development packages
        ];
        description = "List of terminal and shell packages to install";
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
      ++ (optionals terminal.enable terminal.packages)
      ++ (optionals python.enable [python.package])
      ++ extraPackages;
  };
}
