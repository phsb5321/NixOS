{ config, pkgs, inputs, ... }:

{
  # Import External Modules
  imports = [
    inputs.nixvim.homeManagerModules.nixvim
  ];

  # User Configuration
  home = {
    username = "notroot";
    homeDirectory = "/home/notroot";
    stateVersion = "23.11"; # Ensure compatibility with Home Manager release
    packages = with pkgs; [
      (nerdfonts.override { fonts = [ "JetBrainsMono" ]; })
      fish
      kitty
      grc
      eza
      ffmpeg
      nodejs_22 # For copilot nvim plugin
      awscli2
      calibre
      activitywatch
      anki
      gh
      brave
      yazi-unwrapped
      texlive.combined.scheme-full
      dbeaver-bin
      d2 # D2 is a Diagram as Code tool
      zed-editor
    ];
    sessionVariables = {
      EDITOR = "nvim";
      SHELL = "${pkgs.fish}/bin/fish"; # Use Fish as default shell
    };
    file = {
      # ".screenrc".source = dotfiles/screenrc;
      # ".gradle/gradle.properties".text = '''
      #   org.gradle.console=verbose
      #   org.gradle.daemon.idletimeout=3600000
      # ''';
    };
  };

  # Fish Shell Configuration
  programs.fish = {
    enable = true;
    interactiveShellInit = ''
      # Initialize zoxide for fish
      ${pkgs.zoxide}/bin/zoxide init fish | source

      # Zellij Settings
      set -gx ZELLIJ_AUTO_ATTACH false
      set -gx ZELLIJ_AUTO_EXIT false

      # Uncomment to generate auto-start
      # eval (zellij setup --generate-auto-start fish | string collect)
    '';
    shellAliases = {
      vim = "nvim";
      fishconfig = "source ~/.config/fish/config.fish";
      textractor = "~/NixOS/user-scripts/file-text-extractor";
      nixswitch = "~/NixOS/user-scripts/nixos-rebuild.sh default"; # Default flake
      ls = "eza -l --icons";
    };
    plugins = [
      { name = "tide"; src = pkgs.fishPlugins.tide.src; }
      { name = "grc"; src = pkgs.fishPlugins.grc.src; }
    ];
  };

  # Kitty Terminal Configuration
  programs.kitty = {
    enable = true;
    theme = "Tokyo Night";
    font = {
      name = "JetBrainsMono Nerd Font";
      size = 18;
    };
    shellIntegration.enableFishIntegration = true;
    settings = {
      copy_on_select = true;
      clipboard_control = "write-clipboard read-clipboard write-primary read-primary";
      enable_ligatures = true;
    };
  };

  # Zellij Terminal Multiplexer Configuration
  programs.zellij = {
    enable = true;
    settings = {
      theme = "one-half-dark";
      default_shell = "fish";
    };
  };

  # DConf Settings (specific to GNOME)
  dconf.settings = {
    "org/virt-manager/virt-manager/connections" = {
      autoconnect = [ "qemu:///system" ];
      uris = [ "qemu:///system" ];
    };
  };

  # Home Manager Self-Management
  programs.home-manager.enable = true;
}
