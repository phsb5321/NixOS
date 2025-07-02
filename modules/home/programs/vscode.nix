# ~/NixOS/modules/home/programs/vscode.nix
{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.modules.home;
  desktopCfg = config.modules.desktop;
in {
  config = mkIf cfg.enable {
    # Allow unfree packages for VSCode
    nixpkgs.config.allowUnfree = true;

    # Home Manager VSCode configuration
    home-manager.users.${cfg.username} = {
      programs.vscode = {
        enable = true;
        package = pkgs.vscode;

        # User settings for optimal experience with Gnome integration
        userSettings = {
          # Editor settings
          "editor.fontFamily" = "'JetBrainsMono Nerd Font', monospace";
          "editor.fontSize" = 14;
          "editor.fontLigatures" = true;
          "editor.formatOnSave" = true;
          "editor.minimap.enabled" = false;
          "editor.lineNumbers" = "relative";
          "editor.renderWhitespace" = "boundary";
          "editor.tabSize" = 2;
          "editor.insertSpaces" = true;
          "editor.wordWrap" = "on";
          "editor.bracketPairColorization.enabled" = true;
          "editor.guides.bracketPairs" = true;

          # Workbench settings - Gnome-style theming
          "workbench.colorTheme" = if desktopCfg.theming.preferDark then "Adwaita Dark" else "Adwaita Light";
          "workbench.iconTheme" = "adwaita";
          "workbench.productIconTheme" = "adwaita";
          "workbench.startupEditor" = "welcomePage";
          "workbench.editor.enablePreview" = false;
          "workbench.activityBar.location" = "default";
          "workbench.tree.indent" = 12;

          # Window settings for Gnome integration
          "window.titleBarStyle" = "custom";
          "window.commandCenter" = true;
          "window.autoDetectColorScheme" = true;
          "workbench.preferredDarkColorTheme" = "Adwaita Dark";
          "workbench.preferredLightColorTheme" = "Adwaita Light";

          # Terminal integration with kitty
          "terminal.integrated.fontFamily" = "'JetBrainsMono Nerd Font'";
          "terminal.integrated.fontSize" = 14;
          "terminal.integrated.defaultProfile.linux" = "bash";
          "terminal.external.linuxExec" = "kitty";

          # File settings
          "files.autoSave" = "afterDelay";
          "files.autoSaveDelay" = 1000;
          "files.trimTrailingWhitespace" = true;
          "files.insertFinalNewline" = true;
          "files.trimFinalNewlines" = true;

          # Git integration
          "git.enableSmartCommit" = true;
          "git.confirmSync" = false;
          "git.autofetch" = true;

          # Security and trust
          "security.workspace.trust.enabled" = false;

          # Nix specific settings
          "nix.enableLanguageServer" = true;
          "nix.serverPath" = "nixd";

          # Performance settings
          "search.smartCase" = true;
          "search.showLineNumbers" = true;
          "extensions.autoCheckUpdates" = false;
          "extensions.autoUpdate" = false;

          # Gnome-specific enhancements
          "editor.renderLineHighlight" = "none";
        };

        # Key bindings for better workflow
        keybindings = [
          {
            key = "ctrl+shift+t";
            command = "workbench.action.terminal.new";
          }
          {
            key = "ctrl+`";
            command = "workbench.action.terminal.toggleTerminal";
          }
          {
            key = "ctrl+shift+p";
            command = "workbench.action.showCommands";
          }
        ];

        # Essential extensions for development with Gnome themes
        extensions = with pkgs.vscode-extensions; [
          # Gnome theme integration
          piousdeer.adwaita-theme
          
          # Nix language support
          jnoortheen.nix-ide
          
          # Git integration
          eamodio.gitlens
          
          # General development
          ms-vscode.hexeditor
          esbenp.prettier-vscode
          bradlc.vscode-tailwindcss
          
          # Language support
          ms-python.python
          ms-python.black-formatter
          rust-lang.rust-analyzer
          golang.go
          ms-vscode.cpptools
          
          # Productivity
          ms-vscode.live-share
          formulahendry.auto-rename-tag
          christian-kohler.path-intellisense
          
          # UI enhancements
          pkief.material-icon-theme
          ms-vscode.vscode-icons

          # Additional useful extensions
          ms-vscode-remote.remote-ssh
          ms-vscode.remote-explorer
          usernamehw.errorlens
          streetsidesoftware.code-spell-checker
        ];

        # User snippets for common workflows
        userSnippets = {
          "nix" = {
            "NixOS Module" = {
              "prefix" = ["nixmodule" "module"];
              "body" = [
                "{"
                "  config,"
                "  lib,"
                "  pkgs,"
                "  ..."
                "}:"
                "with lib; let"
                "  cfg = config.modules.$1;"
                "in {"
                "  config = mkIf cfg.enable {"
                "    $0"
                "  };"
                "}"
              ];
              "description" = "Create a basic NixOS module structure";
            };
          };
        };
      };

      # Ensure proper desktop integration
      xdg.desktopEntries.code = {
        name = "Visual Studio Code";
        comment = "Code Editing. Redefined.";
        genericName = "Text Editor";
        exec = "code %F";
        icon = "vscode";
        startupNotify = true;
        categories = ["TextEditor" "Development" "IDE"];
        mimeType = [
          "text/plain"
          "inode/directory"
          "application/x-code-workspace"
        ];
        settings = {
          Keywords = "vscode;editor;development;programming;";
          StartupWMClass = "Code";
        };
      };

      # Set VSCode as default editor
      home.sessionVariables = {
        EDITOR = "code --wait";
        VISUAL = "code --wait";
      };

      # Configure Git to use VSCode as editor
      programs.git = {
        extraConfig = {
          core.editor = "code --wait";
          merge.tool = "vscode";
          mergetool.vscode = {
            cmd = "code --wait $MERGED";
          };
          diff.tool = "vscode";
          difftool.vscode = {
            cmd = "code --wait --diff $LOCAL $REMOTE";
          };
        };
      };
    };
  };
} 