# ~/NixOS/modules/packages/categories/development.nix
# Development tools and packages
<<<<<<< HEAD
{ config, lib, pkgs, pkgs-unstable, ... }:

let
=======
{
  config,
  lib,
  pkgs,
  pkgs-unstable,
  ...
}: let
>>>>>>> origin/host/server
  cfg = config.modules.packages.development;
in {
  options.modules.packages.development = {
    enable = lib.mkEnableOption "development tools";

    editors = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Install code editors (VSCode, Cursor, Zed)";
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
<<<<<<< HEAD
      # Code editors
=======
    # Code editors
>>>>>>> origin/host/server
      (lib.optionals cfg.editors [
        pkgs-unstable.vscode
        code-cursor
        pkgs-unstable.zed-editor
      ])
<<<<<<< HEAD

=======
>>>>>>> origin/host/server
      # API testing
      ++ (lib.optionals cfg.apiTools [
        bruno
        bruno-cli
      ])
<<<<<<< HEAD

=======
>>>>>>> origin/host/server
      # Language runtimes
      ++ (lib.optionals cfg.runtimes [
        nodejs
        python3
        rustc
        cargo
        go
<<<<<<< HEAD
        # openjdk - moved to dedicated Java module (modules.core.java)
      ])

      # Compilers and build tools
      ++ (lib.optionals cfg.compilers [
        # android-tools - moved to dedicated Java module (modules.core.java)
=======
        openjdk
      ])
      # Compilers and build tools
      ++ (lib.optionals cfg.compilers [
        android-tools
>>>>>>> origin/host/server
        llvm
        clang
        gcc
        gdb
        cmake
        ninja
        pkg-config
        mermaid-cli
      ])
<<<<<<< HEAD

=======
>>>>>>> origin/host/server
      # Language servers and formatters
      ++ (lib.optionals cfg.languageServers [
        nixd
        nil
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
<<<<<<< HEAD

=======
>>>>>>> origin/host/server
      # Version control
      ++ (lib.optionals cfg.versionControl [
        chezmoi
        git
        git-lfs
        gh
        glab
        lazygit
        delta
      ])
<<<<<<< HEAD

=======
>>>>>>> origin/host/server
      # Modern utilities
      ++ (lib.optionals cfg.utilities [
        typst
        just
        direnv
        httpie
        jq
        yq
        fd
        ripgrep
        bat
        eza
        zoxide
        fzf
        tree
        htop
        btop
      ])
<<<<<<< HEAD

=======
>>>>>>> origin/host/server
      # Database tools
      ++ (lib.optionals cfg.database [
        sqlite
        sqlite-utils
      ])
<<<<<<< HEAD

=======
>>>>>>> origin/host/server
      # Container and cloud tools
      ++ (lib.optionals cfg.containers [
        docker-compose
        kubectl
      ])
<<<<<<< HEAD

=======
>>>>>>> origin/host/server
      # Debugging and profiling
      ++ (lib.optionals cfg.debugging [
        valgrind
        strace
        ltrace
        perf-tools
      ])
<<<<<<< HEAD

=======
>>>>>>> origin/host/server
      # Network tools
      ++ (lib.optionals cfg.networking [
        nmap
        wireshark
        tcpdump
      ])
<<<<<<< HEAD

=======
>>>>>>> origin/host/server
      # Extra packages
      ++ cfg.extraPackages;
  };
}
