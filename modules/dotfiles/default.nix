# ~/NixOS/modules/dotfiles/default.nix
{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.modules.dotfiles;

  # Helper script to initialize chezmoi with proper setup
  initChezmoiScript = pkgs.writeShellScriptBin "init-chezmoi" ''
    #!/usr/bin/env bash
    # Initialize chezmoi dotfiles management
    
    set -euo pipefail
    
    REPO_URL=""
    DOTFILES_DIR="$HOME/.local/share/chezmoi"
    
    echo "🧰 Chezmoi Dotfiles Setup"
    echo "========================="
    
    # Check if chezmoi is installed
    if ! command -v chezmoi &> /dev/null; then
        echo "❌ chezmoi is not installed. Please rebuild your NixOS configuration first."
        exit 1
    fi
    
    # Ask for repository URL or initialize from scratch
    read -p "Enter your dotfiles repository URL (leave empty to start fresh): " REPO_URL
    
    if [[ -n "$REPO_URL" ]]; then
        echo "📦 Initializing chezmoi from repository: $REPO_URL"
        chezmoi init "$REPO_URL"
        echo "✅ Repository cloned to: $(chezmoi source-path)"
        
        read -p "Apply dotfiles now? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            chezmoi apply
            echo "✅ Dotfiles applied successfully!"
        fi
    else
        echo "🆕 Initializing fresh chezmoi configuration"
        chezmoi init --prompt
        echo "✅ Chezmoi initialized at: $(chezmoi source-path)"
        
        echo ""
        echo "Next steps:"
        echo "1. Add your dotfiles: chezmoi add ~/.bashrc ~/.zshrc ~/.config/nvim"
        echo "2. Edit dotfiles: chezmoi edit ~/.bashrc"
        echo "3. Apply changes: chezmoi apply"
        echo "4. Set up git: cd $(chezmoi source-path) && git init"
    fi
    
    echo ""
    echo "📁 Chezmoi source directory: $(chezmoi source-path)"
    echo "💡 Use 'dotfiles-edit' to open dotfiles in your editor"
    echo "💡 Use 'dotfiles-sync' to sync changes"
  '';

  # Helper script to edit dotfiles in VS Code
  editDotfilesScript = pkgs.writeShellScriptBin "dotfiles-edit" ''
    #!/usr/bin/env bash
    # Open chezmoi source directory in VS Code
    
    if ! command -v chezmoi &> /dev/null; then
        echo "❌ chezmoi is not installed"
        exit 1
    fi
    
    SOURCE_PATH=$(chezmoi source-path)
    
    if [[ ! -d "$SOURCE_PATH" ]]; then
        echo "❌ Chezmoi not initialized. Run 'init-chezmoi' first."
        exit 1
    fi
    
    if command -v code &> /dev/null; then
        echo "📝 Opening dotfiles in VS Code: $SOURCE_PATH"
        code "$SOURCE_PATH"
    elif command -v cursor &> /dev/null; then
        echo "📝 Opening dotfiles in Cursor: $SOURCE_PATH"
        cursor "$SOURCE_PATH"
    else
        echo "📁 Dotfiles directory: $SOURCE_PATH"
        echo "💡 No supported editor found. Install VS Code or Cursor."
    fi
  '';

  # Helper script to sync dotfiles
  syncDotfilesScript = pkgs.writeShellScriptBin "dotfiles-sync" ''
    #!/usr/bin/env bash
    # Sync dotfiles with chezmoi
    
    set -euo pipefail
    
    if ! command -v chezmoi &> /dev/null; then
        echo "❌ chezmoi is not installed"
        exit 1
    fi
    
    SOURCE_PATH=$(chezmoi source-path)
    
    if [[ ! -d "$SOURCE_PATH" ]]; then
        echo "❌ Chezmoi not initialized. Run 'init-chezmoi' first."
        exit 1
    fi
    
    echo "🔄 Syncing dotfiles..."
    
    # Show what would change
    if chezmoi diff --no-pager | grep -q .; then
        echo "📋 Pending changes:"
        chezmoi diff --no-pager
        echo ""
        
        read -p "Apply these changes? (Y/n): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Nn]$ ]]; then
            echo "❌ Sync cancelled"
            exit 0
        fi
    else
        echo "✅ No changes to apply"
    fi
    
    # Apply changes
    chezmoi apply
    echo "✅ Dotfiles synced successfully!"
    
    # If we're in a git repository, offer to commit and push
    cd "$SOURCE_PATH"
    if git rev-parse --git-dir > /dev/null 2>&1; then
        if [[ -n $(git status --porcelain) ]]; then
            echo ""
            read -p "Commit and push changes to git? (y/N): " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                git add .
                read -p "Enter commit message (default: 'Update dotfiles'): " COMMIT_MSG
                COMMIT_MSG=''${COMMIT_MSG:-"Update dotfiles"}
                git commit -m "$COMMIT_MSG"
                
                if git remote get-url origin > /dev/null 2>&1; then
                    git push
                    echo "✅ Changes pushed to remote repository"
                else
                    echo "⚠️  No remote repository configured"
                fi
            fi
        fi
    fi
  '';

  # Helper script to add new files to chezmoi
  addDotfilesScript = pkgs.writeShellScriptBin "dotfiles-add" ''
    #!/usr/bin/env bash
    # Add files to chezmoi management
    
    if ! command -v chezmoi &> /dev/null; then
        echo "❌ chezmoi is not installed"
        exit 1
    fi
    
    if [[ ! -d "$(chezmoi source-path)" ]]; then
        echo "❌ Chezmoi not initialized. Run 'init-chezmoi' first."
        exit 1
    fi
    
    if [[ $# -eq 0 ]]; then
        echo "Usage: dotfiles-add <file1> [file2] ..."
        echo "Examples:"
        echo "  dotfiles-add ~/.bashrc"
        echo "  dotfiles-add ~/.config/nvim"
        echo "  dotfiles-add ~/.ssh/config"
        exit 1
    fi
    
    for file in "$@"; do
        if [[ -e "$file" ]]; then
            echo "📁 Adding $file to chezmoi..."
            chezmoi add "$file"
            echo "✅ Added $file"
        else
            echo "❌ File not found: $file"
        fi
    done
    
    echo ""
    echo "💡 Use 'dotfiles-edit' to modify your dotfiles"
    echo "💡 Use 'dotfiles-sync' to apply changes"
  '';

  # Helper script to show chezmoi status
  statusDotfilesScript = pkgs.writeShellScriptBin "dotfiles-status" ''
    #!/usr/bin/env bash
    # Show chezmoi status and managed files
    
    if ! command -v chezmoi &> /dev/null; then
        echo "❌ chezmoi is not installed"
        exit 1
    fi
    
    if [[ ! -d "$(chezmoi source-path)" ]]; then
        echo "❌ Chezmoi not initialized. Run 'init-chezmoi' first."
        exit 1
    fi
    
    echo "🧰 Chezmoi Status"
    echo "================"
    echo "📁 Source directory: $(chezmoi source-path)"
    echo ""
    
    echo "📋 Managed files:"
    chezmoi managed
    echo ""
    
    echo "🔄 Status:"
    chezmoi status
    echo ""
    
    # Check if there are differences
    if chezmoi diff --no-pager | grep -q .; then
        echo "⚠️  There are pending changes. Run 'dotfiles-sync' to apply them."
    else
        echo "✅ All dotfiles are up to date"
    fi
  '';

in {
  options.modules.dotfiles = {
    enable = mkEnableOption "dotfiles management with chezmoi";
    
    autoSetup = mkOption {
      type = types.bool;
      default = false;
      description = "Automatically run chezmoi init on first boot (requires manual intervention)";
    };
    
    enableHelperScripts = mkOption {
      type = types.bool;
      default = true;
      description = "Install helper scripts for dotfiles management";
    };
  };

  config = mkIf cfg.enable {
    # Ensure chezmoi is available system-wide
    environment.systemPackages = [
      pkgs.chezmoi
    ] ++ (optionals cfg.enableHelperScripts [
      initChezmoiScript
      editDotfilesScript
      syncDotfilesScript
      addDotfilesScript
      statusDotfilesScript
    ]);

    # Create shell aliases for convenience
    environment.shellAliases = mkIf cfg.enableHelperScripts {
      "dotfiles" = "dotfiles-status";
      "chezcd" = "cd $(chezmoi source-path)";
      "chezcode" = "dotfiles-edit";
      "chezsync" = "dotfiles-sync";
      "chezadd" = "dotfiles-add";
    };

    # Add helpful message to MOTD
    environment.etc."motd".text = mkIf cfg.enableHelperScripts ''
      
      🧰 Dotfiles Management Commands:
      ================================
      init-chezmoi      - Initialize chezmoi setup
      dotfiles-status   - Show managed files and status
      dotfiles-edit     - Edit dotfiles in VS Code/Cursor
      dotfiles-add      - Add files to chezmoi
      dotfiles-sync     - Apply changes and sync
      
      Aliases: dotfiles, chezcd, chezcode, chezsync, chezadd
      
    '';
  };
}
