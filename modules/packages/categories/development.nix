# ~/NixOS/modules/packages/categories/development.nix
# Development tools and packages
{
  config,
  lib,
  pkgs,
  pkgs-unstable,
  ...
}: let
  cfg = config.modules.packages.development;
in {
  options.modules.packages.development = {
    enable = lib.mkEnableOption "development tools";

    editors = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Install code editors (VSCode, Zed)";
    };

    apiTools = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Install API testing tools (Bruno)";
    };

    runtimes = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Install language runtimes (Node, Python, Rust, Go, Java)";
    };

    compilers = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Install compilers and build tools (LLVM, GCC, CMake)";
    };

    languageServers = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Install language servers and formatters";
    };

    versionControl = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Install Git and related tools";
    };

    utilities = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Install modern development utilities";
    };

    database = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Install database tools";
    };

    containers = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Install container and cloud tools";
    };

    debugging = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Install debugging and profiling tools";
    };

    networking = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Install network analysis tools";
    };

    extraPackages = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [];
      description = "Additional development packages";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs;
    # Code editors
      (lib.optionals cfg.editors [
        pkgs-unstable.vscode
        pkgs-unstable.zed-editor
      ])
      # API testing
      ++ (lib.optionals cfg.apiTools [
        bruno
        bruno-cli
      ])
      # Language runtimes (go, nodejs_22 already in core)
      ++ (lib.optionals cfg.runtimes [
        python3
        rustc
        cargo
        openjdk
      ])
      # Compilers and build tools (gcc already in core)
      ++ (lib.optionals cfg.compilers [
        android-tools
        llvm
        clang
        gdb
        cmake
        ninja
        pkg-config
        mermaid-cli
      ])
      # Language servers and formatters (nixd, nil already in core)
      ++ (lib.optionals cfg.languageServers [
        nodePackages.typescript-language-server
        nodePackages.eslint
        nodePackages.prettier
        marksman
        taplo
        yaml-language-server
        vscode-langservers-extracted
        bash-language-server
        shfmt
        rust-analyzer
        gopls
        pyright
        ruff
        black
      ])
      # Version control (git, gh, lazygit already in core)
      ++ (lib.optionals cfg.versionControl [
        chezmoi
        git-lfs
        glab
        delta
      ])
      # Modern utilities (just, jq, fd, ripgrep, bat, eza, zoxide, tree, htop already in core)
      ++ (lib.optionals cfg.utilities [
        typst
        direnv
        httpie
        yq
        fzf
        btop
      ])
      # Database tools
      ++ (lib.optionals cfg.database [
        sqlite
        sqlite-utils
      ])
      # Container and cloud tools
      ++ (lib.optionals cfg.containers [
        docker-compose
        kubectl
      ])
      # Debugging and profiling
      ++ (lib.optionals cfg.debugging [
        valgrind
        strace
        ltrace
        perf-tools
      ])
      # Network tools (nmap already in core)
      ++ (lib.optionals cfg.networking [
        wireshark
        tcpdump
      ])
      # Extra packages
      ++ cfg.extraPackages;
  };
}
