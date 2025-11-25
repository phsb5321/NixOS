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
  dotfilesPath = "${config.users.users.${cfg.username}.home}/${cfg.projectDir}/dotfiles";

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
            USERNAME="${cfg.username}"

            if [[ ! -d "$DOTFILES_DIR" ]]; then
                echo "❌ Dotfiles directory not found: $DOTFILES_DIR"
                exit 1
            fi

            echo "📁 Using dotfiles from: $DOTFILES_DIR"

            # Ensure config directory exists
            mkdir -p ~/.config/chezmoi

            # Create chezmoi configuration
            cat > ~/.config/chezmoi/chezmoi.toml <<EOF
    # Chezmoi configuration for NixOS project
    # This configures chezmoi to use the dotfiles directory within the project

    # Set the source directory to our NixOS dotfiles
    sourceDir = "$DOTFILES_DIR"

    [data]
        # Hostname for templating
        hostname = "{{ .chezmoi.hostname }}"
        # Username for templating
        username = "{{ .chezmoi.username }}"
        # OS for templating
        os = "{{ .chezmoi.os }}"
        # Architecture for templating
        arch = "{{ .chezmoi.arch }}"
        # Host type detection
        isDesktop = {{ if eq .chezmoi.hostname "nixos" }}true{{ else }}false{{ end }}
        isLaptop = {{ if eq .chezmoi.hostname "laptop" }}true{{ else }}false{{ end }}

    [git]
        # Auto-commit changes to dotfiles
        autoCommit = true
        # Auto-push changes (set to false initially for safety)
        autoPush = false

    [edit]
        # Use VS Code as the default editor for dotfiles
        command = "code"
        args = ["--wait"]

    [diff]
        # Use VS Code for diffs
        command = "code"
        args = ["--wait", "--diff"]
    EOF

            # Apply dotfiles
            echo "🔄 Applying dotfiles..."
            chezmoi apply

            echo "✅ Dotfiles initialized and applied successfully!"
            echo "💡 Source directory: $DOTFILES_DIR"
            echo "💡 Edit dotfiles: code $DOTFILES_DIR"
            echo "💡 Apply changes: dotfiles-apply"
            echo "💡 Check status: chezmoi status"
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
        chezmoi diff --no-pager
        exit 0
    fi

    # Apply changes
    chezmoi apply
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

  # Script to show backup info and manage dotfiles
  syncScript = pkgs.writeShellScriptBin "dotfiles-sync" ''
    #!/usr/bin/env bash
    set -euo pipefail

    DOTFILES_DIR="${dotfilesPath}"

    if [[ ! -d "$DOTFILES_DIR" ]]; then
        echo "❌ Dotfiles directory not found: $DOTFILES_DIR"
        exit 1
    fi

    echo "📁 Dotfiles Management Info"
    echo "=========================="
    echo "📁 Source directory: $DOTFILES_DIR"
    echo "🏠 Target directory: $HOME"
    echo ""
    echo "💡 Dotfiles are managed as part of your NixOS project."
    echo "💡 Changes are version controlled with the main NixOS repository."
    echo "💡 Use your main git workflow to commit dotfiles changes:"
    echo ""
    echo "   cd /home/notroot/NixOS"
    echo "   git add dotfiles/"
    echo "   git commit -m 'Update dotfiles'"
    echo ""
    echo "📋 Currently managed files:"
    chezmoi managed --source "$DOTFILES_DIR" 2>/dev/null || echo "No files managed yet"
  '';

  # Script to validate dotfiles before applying
  checkScript = pkgs.writeShellScriptBin "dotfiles-check" ''
    #!/usr/bin/env bash
    set -euo pipefail

    DOTFILES_DIR="${dotfilesPath}"

    if [[ ! -d "$DOTFILES_DIR" ]]; then
        echo "❌ Dotfiles directory not found: $DOTFILES_DIR"
        exit 1
    fi

    echo "🔍 Validating Dotfiles"
    echo "====================="
    echo ""

    # Track validation status
    VALIDATION_FAILED=0

    # Check SSH config syntax
    echo "📝 Checking SSH config..."
    SSH_CONFIG="$HOME/.ssh/config"
    if [[ -f "$SSH_CONFIG" ]]; then
        if ssh -G test >/dev/null 2>&1; then
            echo "✅ SSH config is valid"
        else
            echo "❌ SSH config has syntax errors"
            VALIDATION_FAILED=1
        fi
    else
        echo "⚠️  No SSH config found (will be created on apply)"
    fi
    echo ""

    # Check Git config syntax
    echo "📝 Checking Git config..."
    GIT_CONFIG="$HOME/.gitconfig"
    if [[ -f "$GIT_CONFIG" ]]; then
        if git config --file "$GIT_CONFIG" --list >/dev/null 2>&1; then
            echo "✅ Git config is valid"
            # Check for user.email
            if git config --file "$GIT_CONFIG" user.email >/dev/null 2>&1; then
                EMAIL=$(git config --file "$GIT_CONFIG" user.email)
                echo "   Email: $EMAIL"
            else
                echo "⚠️  No user.email configured"
            fi
        else
            echo "❌ Git config has syntax errors"
            VALIDATION_FAILED=1
        fi
    else
        echo "⚠️  No Git config found (will be created on apply)"
    fi
    echo ""

    # Check for sensitive data in dotfiles
    echo "🔒 Checking for sensitive data..."
    SENSITIVE_PATTERNS="password|secret|api[_-]?key|private[_-]?key|token"
    if grep -rE -i "$SENSITIVE_PATTERNS" "$DOTFILES_DIR" 2>/dev/null | grep -v ".tmpl" | grep -v "Binary file"; then
        echo "❌ Found potential sensitive data in dotfiles (see above)"
        echo "   Consider using chezmoi encryption for sensitive files"
        VALIDATION_FAILED=1
    else
        echo "✅ No obvious sensitive data found"
    fi
    echo ""

    # Check for hardcoded paths
    echo "🔍 Checking for hardcoded paths..."
    HARDCODED_PATTERNS="/home/notroot"
    if grep -r "$HARDCODED_PATTERNS" "$DOTFILES_DIR" --exclude="*.tmpl" 2>/dev/null; then
        echo "⚠️  Found hardcoded paths (see above)"
        echo "   Consider using templates with {{ .chezmoi.homeDir }}"
    else
        echo "✅ No hardcoded paths found"
    fi
    echo ""

    # Summary
    echo "📊 Validation Summary"
    echo "===================="
    if [[ $VALIDATION_FAILED -eq 0 ]]; then
        echo "✅ All validations passed"
        echo "💡 You can safely run 'dotfiles-apply'"
        exit 0
    else
        echo "❌ Some validations failed"
        echo "⚠️  Fix the issues before applying dotfiles"
        exit 1
    fi
  '';
in {
  imports = [
    ./auto-sync.nix
  ];

  options.modules.dotfiles = {
    enable = mkEnableOption "dotfiles management with chezmoi";

    username = mkOption {
      type = types.str;
      default = "notroot";
      description = "Username for dotfiles management";
    };

    projectDir = mkOption {
      type = types.str;
      default = "NixOS";
      description = "Name of NixOS project directory in user home";
    };

    enableHelperScripts = mkOption {
      type = types.bool;
      default = true;
      description = "Install helper scripts for dotfiles management";
    };

    secretsIntegration = mkOption {
      type = types.bool;
      default = false;
      description = "Enable secrets integration with chezmoi templates";
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
        checkScript
      ]);

    # Create shell aliases for convenience
    environment.shellAliases = mkIf cfg.enableHelperScripts {
      "dotfiles" = "dotfiles-status";
      "dotfiles-diff" = "dotfiles-apply --diff";
      "dotfiles-info" = "dotfiles-sync";
    };

    # Expose secrets as environment variables for chezmoi templates
    # This allows templates to use: {{ env "CHEZMOI_SECRET_NAME" }}
    # Secrets will be available when sops-nix is configured
    environment.sessionVariables = mkIf cfg.secretsIntegration {
      # These paths will be populated by sops-nix when configured
      # Example: CHEZMOI_GITHUB_TOKEN points to decrypted secret
      # Add your secrets here following the pattern:
      # CHEZMOI_SECRET_NAME = "/run/secrets/secret-name";
    };
  };
}
