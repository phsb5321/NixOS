# ~/NixOS/modules/dotfiles/default.nix
{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.modules.dotfiles;

  # Path to the dotfiles directory within the NixOS project
  dotfilesPath = "${config.users.users.${cfg.username}.home}/NixOS/dotfiles";

  # Script to initialize chezmoi with our custom source directory
  initScript = pkgs.writeShellScriptBin "dotfiles-init" ''
    #!/usr/bin/env bash
    set -euo pipefail

    echo "🧰 Initializing Chezmoi with NixOS Project Dotfiles"
    echo "=================================================="

    # Check if chezmoi is available
    if ! command -v chezmoi &> /dev/null; then
        echo "❌ chezmoi is not installed. Please rebuild your NixOS configuration."
        exit 1
    fi

    # Path to our dotfiles directory
    DOTFILES_DIR="${dotfilesPath}"

    if [[ ! -d "$DOTFILES_DIR" ]]; then
        echo "❌ Dotfiles directory not found: $DOTFILES_DIR"
        exit 1
    fi

    echo "📁 Using dotfiles from: $DOTFILES_DIR"

    # Initialize chezmoi with our source directory
    export CHEZMOI_SOURCE_DIR="$DOTFILES_DIR"

    # Apply dotfiles
    echo "🔄 Applying dotfiles..."
    chezmoi apply --source "$DOTFILES_DIR"

    echo "✅ Dotfiles initialized and applied successfully!"
    echo "💡 Source directory: $DOTFILES_DIR"
    echo "💡 Edit dotfiles: code $DOTFILES_DIR"
    echo "💡 Apply changes: dotfiles-apply"
  '';

  # Script to apply dotfile changes
  applyScript = pkgs.writeShellScriptBin "dotfiles-apply" ''
    #!/usr/bin/env bash
    set -euo pipefail

    DOTFILES_DIR="${dotfilesPath}"

    if [[ ! -d "$DOTFILES_DIR" ]]; then
        echo "❌ Dotfiles directory not found: $DOTFILES_DIR"
        echo "Run 'dotfiles-init' first."
        exit 1
    fi

    echo "🔄 Applying dotfiles from: $DOTFILES_DIR"

    # Show diff if requested
    if [[ "''${1:-}" == "--diff" ]]; then
        chezmoi diff --source "$DOTFILES_DIR" --no-pager
        exit 0
    fi

    # Apply changes
    chezmoi apply --source "$DOTFILES_DIR"
    echo "✅ Dotfiles applied successfully!"
  '';

  # Script to edit dotfiles
  editScript = pkgs.writeShellScriptBin "dotfiles-edit" ''
    #!/usr/bin/env bash
    set -euo pipefail

    DOTFILES_DIR="${dotfilesPath}"

    if [[ ! -d "$DOTFILES_DIR" ]]; then
        echo "❌ Dotfiles directory not found: $DOTFILES_DIR"
        echo "Run 'dotfiles-init' first."
        exit 1
    fi

    echo "📝 Opening dotfiles directory in editor..."

    if command -v code &> /dev/null; then
        code "$DOTFILES_DIR"
    elif command -v cursor &> /dev/null; then
        cursor "$DOTFILES_DIR"
    else
        echo "📁 Dotfiles directory: $DOTFILES_DIR"
        echo "💡 Install VS Code or Cursor for direct editing."
    fi
  '';

  # Script to add new dotfiles
  addScript = pkgs.writeShellScriptBin "dotfiles-add" ''
    #!/usr/bin/env bash
    set -euo pipefail

    DOTFILES_DIR="${dotfilesPath}"

    if [[ ! -d "$DOTFILES_DIR" ]]; then
        echo "❌ Dotfiles directory not found: $DOTFILES_DIR"
        echo "Run 'dotfiles-init' first."
        exit 1
    fi

    if [[ $# -eq 0 ]]; then
        echo "Usage: dotfiles-add <file1> [file2] ..."
        echo "Examples:"
        echo "  dotfiles-add ~/.bashrc"
        echo "  dotfiles-add ~/.config/nvim"
        exit 1
    fi

    for file in "$@"; do
        if [[ -e "$file" ]]; then
            echo "📁 Adding $file to dotfiles..."
            chezmoi add --source "$DOTFILES_DIR" "$file"
            echo "✅ Added $file"
        else
            echo "❌ File not found: $file"
        fi
    done

    echo "💡 Edit dotfiles: dotfiles-edit"
    echo "💡 Apply changes: dotfiles-apply"
  '';

  # Script to show status
  statusScript = pkgs.writeShellScriptBin "dotfiles-status" ''
    #!/usr/bin/env bash
    set -euo pipefail

    DOTFILES_DIR="${dotfilesPath}"

    if [[ ! -d "$DOTFILES_DIR" ]]; then
        echo "❌ Dotfiles directory not found: $DOTFILES_DIR"
        echo "Run 'dotfiles-init' first."
        exit 1
    fi

    echo "🧰 Dotfiles Status"
    echo "================"
    echo "📁 Source directory: $DOTFILES_DIR"
    echo ""

    echo "📋 Managed files:"
    chezmoi managed --source "$DOTFILES_DIR" 2>/dev/null || echo "No files managed yet"
    echo ""

    echo "🔄 Status:"
    if chezmoi status --source "$DOTFILES_DIR" 2>/dev/null | grep -q .; then
        chezmoi status --source "$DOTFILES_DIR"
        echo ""
        echo "⚠️  There are changes. Run 'dotfiles-apply' to apply them."
    else
        echo "✅ All dotfiles are up to date"
    fi
  '';

  # Script to sync with git (if git repository)
  syncScript = pkgs.writeShellScriptBin "dotfiles-sync" ''
    #!/usr/bin/env bash
    set -euo pipefail

    DOTFILES_DIR="${dotfilesPath}"

    if [[ ! -d "$DOTFILES_DIR" ]]; then
        echo "❌ Dotfiles directory not found: $DOTFILES_DIR"
        exit 1
    fi

    cd "$DOTFILES_DIR"

    # Check if this is a git repository
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        echo "📁 Not a git repository. Initialize with:"
        echo "cd $DOTFILES_DIR && git init && git add . && git commit -m 'Initial dotfiles'"
        exit 1
    fi

    echo "� Syncing dotfiles with git..."

    # Add all changes
    git add .

    # Check if there are changes to commit
    if git diff --staged --quiet; then
        echo "✅ No changes to commit"
    else
        # Commit changes
        echo "� Changes detected, committing..."
        read -p "Enter commit message (default: 'Update dotfiles'): " commit_msg
        commit_msg=''${commit_msg:-"Update dotfiles"}
        git commit -m "$commit_msg"
        echo "✅ Changes committed"

        # Push if remote exists
        if git remote get-url origin > /dev/null 2>&1; then
            read -p "Push to remote? (y/N): " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                git push
                echo "✅ Changes pushed to remote"
            fi
        else
            echo "💡 No remote configured. Set up with:"
            echo "git remote add origin <your-repo-url>"
        fi
    fi
  '';
in {
  options.modules.dotfiles = {
    enable = mkEnableOption "dotfiles management with chezmoi";

    username = mkOption {
      type = types.str;
      default = "notroot";
      description = "Username for dotfiles management";
    };

    enableHelperScripts = mkOption {
      type = types.bool;
      default = true;
      description = "Install helper scripts for dotfiles management";
    };
  };

  config = mkIf cfg.enable {
    # Ensure chezmoi is available
    environment.systemPackages =
      [
        pkgs.chezmoi
      ]
      ++ (optionals cfg.enableHelperScripts [
        initScript
        applyScript
        editScript
        addScript
        statusScript
        syncScript
      ]);

    # Create shell aliases for convenience
    environment.shellAliases = mkIf cfg.enableHelperScripts {
      "dotfiles" = "dotfiles-status";
      "dotfiles-diff" = "dotfiles-apply --diff";
    };
  };
}
