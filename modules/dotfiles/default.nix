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
    MUTABLE_FILE="$DOTFILES_DIR/.chezmoimutable"
    FORCE_ALL=false
    DIFF_MODE=false
    SPECIFIC_FILES=()

    show_help() {
        echo "🔄 dotfiles-apply - Apply dotfiles from source to target"
        echo ""
        echo "Usage: dotfiles-apply [OPTIONS] [FILE...]"
        echo ""
        echo "Options:"
        echo "  --diff        Show diff without applying changes"
        echo "  --force-all   Force apply all files, including mutable files with drift"
        echo "  -h, --help    Show this help message"
        echo ""
        echo "Examples:"
        echo "  dotfiles-apply                    # Apply all, skip mutable with drift"
        echo "  dotfiles-apply --force-all        # Apply all, overwrite everything"
        echo "  dotfiles-apply ~/.config/zed/settings.json  # Apply specific file"
    }

    # Check if file is mutable
    is_mutable() {
        local file="$1"
        [[ -f "$MUTABLE_FILE" ]] && grep -qF "$file" "$MUTABLE_FILE" 2>/dev/null
    }

    # Check if file has drifted (target differs from what source would generate)
    has_drift() {
        local file="$1"
        chezmoi status --source "$DOTFILES_DIR" 2>/dev/null | grep -qE "^.M.*$file$|^MM.*$file$"
    }

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --diff)
                DIFF_MODE=true
                shift
                ;;
            --force-all)
                FORCE_ALL=true
                shift
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            -*)
                echo "Unknown option: $1"
                show_help
                exit 1
                ;;
            *)
                SPECIFIC_FILES+=("$1")
                shift
                ;;
        esac
    done

    if [[ ! -d "$DOTFILES_DIR" ]]; then
        echo "❌ Dotfiles directory not found: $DOTFILES_DIR"
        echo "Run 'dotfiles-init' first."
        exit 1
    fi

    echo "🔄 Applying dotfiles from: $DOTFILES_DIR"

    # Show diff if requested
    if [[ "$DIFF_MODE" == "true" ]]; then
        chezmoi diff --no-pager
        exit 0
    fi

    # If specific files requested, apply only those
    if [[ ''${#SPECIFIC_FILES[@]} -gt 0 ]]; then
        for file in "''${SPECIFIC_FILES[@]}"; do
            echo "Applying: $file"
            chezmoi apply "$file"
        done
        echo "✅ Applied ''${#SPECIFIC_FILES[@]} file(s)"
        exit 0
    fi

    # Check for mutable files with drift
    SKIPPED_FILES=()
    if [[ "$FORCE_ALL" == "false" && -f "$MUTABLE_FILE" ]]; then
        echo "Checking mutable files for drift..."

        while IFS= read -r line; do
            [[ -z "$line" ]] && continue
            [[ "$line" == \#* ]] && continue  # Skip comments

            if has_drift "$line"; then
                SKIPPED_FILES+=("$line")
                echo "  ⏭️  Skipping $line [mutable with drift]"
            fi
        done < "$MUTABLE_FILE"
    fi

    if [[ ''${#SKIPPED_FILES[@]} -gt 0 ]]; then
        echo ""
        echo "⚠️  Skipping ''${#SKIPPED_FILES[@]} mutable file(s) with local changes"
        echo "   💡 Use 'dotfiles-capture' to adopt changes to source"
        echo "   💡 Use 'dotfiles-apply --force-all' to overwrite anyway"
        echo ""

        # Apply only non-skipped files by excluding mutable ones
        # chezmoi doesn't have a direct exclude flag, so we apply with confirmation
        echo "Applying remaining files..."

        # Get list of all managed files
        MANAGED_FILES=$(chezmoi managed --source "$DOTFILES_DIR" 2>/dev/null || true)

        for file in $MANAGED_FILES; do
            skip=false
            for skipped in "''${SKIPPED_FILES[@]}"; do
                [[ "$file" == "$skipped" ]] && skip=true && break
            done

            if [[ "$skip" == "false" ]]; then
                # Check if file has changes to apply
                if chezmoi status --source "$DOTFILES_DIR" 2>/dev/null | grep -q "$file"; then
                    chezmoi apply "$HOME/$file" 2>/dev/null || true
                fi
            fi
        done
    else
        # No mutable files to skip, apply everything
        chezmoi apply
    fi

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
    MUTABLE_FILE="$DOTFILES_DIR/.chezmoimutable"

    if [[ ! -d "$DOTFILES_DIR" ]]; then
        echo "❌ Dotfiles directory not found: $DOTFILES_DIR"
        echo "Run 'dotfiles-init' first."
        exit 1
    fi

    # Check if file is mutable
    is_mutable() {
        local file="$1"
        [[ -f "$MUTABLE_FILE" ]] && grep -qF "$file" "$MUTABLE_FILE" 2>/dev/null
    }

    echo "🧰 Dotfiles Status"
    echo "================"
    echo "📁 Source: $DOTFILES_DIR"
    echo ""

    # Count managed files and mutability stats
    TOTAL_MANAGED=0
    MUTABLE_COUNT=0
    while IFS= read -r file; do
        [[ -z "$file" ]] && continue
        ((TOTAL_MANAGED++)) || true
        is_mutable "$file" && ((MUTABLE_COUNT++)) || true
    done < <(chezmoi managed --source "$DOTFILES_DIR" 2>/dev/null)

    echo "📋 Files: $TOTAL_MANAGED managed ($MUTABLE_COUNT mutable)"
    echo ""

    # Get status and show drift info
    echo "🔄 Drift Status:"
    STATUS_OUTPUT=$(chezmoi status --source "$DOTFILES_DIR" 2>/dev/null || true)

    if [[ -z "$STATUS_OUTPUT" ]]; then
        echo "✅ All dotfiles are in sync"
    else
        DRIFTED=0
        SOURCE_CHANGED=0

        while IFS= read -r line; do
            [[ -z "$line" ]] && continue
            status="''${line:0:2}"
            file="''${line:3}"

            # Determine label based on status
            label=""
            if [[ "$status" == "MM" || "$status" == " M" ]]; then
                label="[DRIFTED]"
                ((DRIFTED++)) || true
            elif [[ "$status" == "M " ]]; then
                label="[SOURCE]"
                ((SOURCE_CHANGED++)) || true
            elif [[ "$status" == "A " ]]; then
                label="[NEW]"
                ((SOURCE_CHANGED++)) || true
            fi

            # Add mutability indicator
            if is_mutable "$file"; then
                echo "  📝 $file $label [mutable]"
            else
                echo "  📄 $file $label"
            fi
        done <<< "$STATUS_OUTPUT"

        echo ""

        # Show summary and suggestions
        if [[ $DRIFTED -gt 0 ]]; then
            echo "⚠️  $DRIFTED file(s) have drifted from source"
            echo "   💡 Run 'dotfiles-drift --diff' to see differences"
            echo "   💡 Run 'dotfiles-capture' to adopt runtime changes"
            echo "   💡 Run 'dotfiles-apply' to restore from source"
        fi
        if [[ $SOURCE_CHANGED -gt 0 ]]; then
            echo "📤 $SOURCE_CHANGED file(s) have source changes to apply"
            echo "   💡 Run 'dotfiles-apply' to update"
        fi
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

    # Check JSON files for syntax errors and duplicate keys
    echo "📝 Checking JSON configuration files..."
    SCRIPTS_DIR="$DOTFILES_DIR/../modules/dotfiles/scripts"
    JSON_FILES=$(find "$DOTFILES_DIR" -name "*.json" -type f 2>/dev/null || true)
    if [[ -n "$JSON_FILES" ]]; then
        if ${pkgs.python3}/bin/python3 "$SCRIPTS_DIR/json-validator.py" --quiet $JSON_FILES 2>/dev/null; then
            JSON_COUNT=$(echo "$JSON_FILES" | wc -l)
            echo "✅ All $JSON_COUNT JSON file(s) are valid"
        else
            echo "❌ JSON validation failed"
            echo "   Run 'dotfiles-validate' for detailed errors"
            VALIDATION_FAILED=1
        fi
    else
        echo "⚠️  No JSON files found in dotfiles"
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

  # Script to validate JSON/JSONC files for syntax errors and duplicate keys
  validateScript = pkgs.writeShellScriptBin "dotfiles-validate" ''
    #!/usr/bin/env bash
    set -euo pipefail

    DOTFILES_DIR="${dotfilesPath}"
    SCRIPTS_DIR="${dotfilesPath}/../modules/dotfiles/scripts"
    FIX_MODE=false
    QUIET_MODE=false
    SOURCE_MODE=true
    TARGET_MODE=false
    FILES=()

    show_help() {
        echo "🔍 dotfiles-validate - Validate JSON/JSONC configuration files"
        echo ""
        echo "Usage: dotfiles-validate [OPTIONS] [FILE...]"
        echo ""
        echo "Options:"
        echo "  --fix         Automatically fix duplicate keys (keeps last value)"
        echo "  --source      Validate source files in dotfiles directory (default)"
        echo "  --target      Validate target files in home directory"
        echo "  --both        Validate both source and target"
        echo "  -q, --quiet   Only output errors"
        echo "  -h, --help    Show this help message"
        echo ""
        echo "Examples:"
        echo "  dotfiles-validate                    # Validate all JSON files in source"
        echo "  dotfiles-validate --fix              # Fix duplicate keys"
        echo "  dotfiles-validate ~/.config/zed/settings.json  # Validate specific file"
    }

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --fix)
                FIX_MODE=true
                shift
                ;;
            --source)
                SOURCE_MODE=true
                TARGET_MODE=false
                shift
                ;;
            --target)
                SOURCE_MODE=false
                TARGET_MODE=true
                shift
                ;;
            --both)
                SOURCE_MODE=true
                TARGET_MODE=true
                shift
                ;;
            -q|--quiet)
                QUIET_MODE=true
                shift
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            -*)
                echo "Unknown option: $1"
                show_help
                exit 1
                ;;
            *)
                FILES+=("$1")
                shift
                ;;
        esac
    done

    # If no files specified, find all JSON files
    if [[ ''${#FILES[@]} -eq 0 ]]; then
        if [[ "$SOURCE_MODE" == "true" ]]; then
            while IFS= read -r -d "" file; do
                FILES+=("$file")
            done < <(find "$DOTFILES_DIR" -name "*.json" -type f -print0 2>/dev/null)
        fi
        if [[ "$TARGET_MODE" == "true" ]]; then
            # Add common target locations
            for target in ~/.config/zed/settings.json ~/.config/zed/keymap.json ~/.config/Code/User/settings.json; do
                [[ -f "$target" ]] && FILES+=("$target")
            done
        fi
    fi

    if [[ ''${#FILES[@]} -eq 0 ]]; then
        echo "No JSON files found to validate."
        exit 0
    fi

    [[ "$QUIET_MODE" == "false" ]] && echo "🔍 Validating configuration files"
    [[ "$QUIET_MODE" == "false" ]] && echo "================================="

    # Build python command arguments
    PYTHON_ARGS=()
    [[ "$FIX_MODE" == "true" ]] && PYTHON_ARGS+=("--fix")
    [[ "$QUIET_MODE" == "true" ]] && PYTHON_ARGS+=("--quiet")

    # Run the Python validator
    ${pkgs.python3}/bin/python3 "$SCRIPTS_DIR/json-validator.py" "''${PYTHON_ARGS[@]}" "''${FILES[@]}"
  '';

  # Script to show detailed drift report
  driftScript = pkgs.writeShellScriptBin "dotfiles-drift" ''
    #!/usr/bin/env bash
    set -euo pipefail

    DOTFILES_DIR="${dotfilesPath}"
    MUTABLE_FILE="$DOTFILES_DIR/.chezmoimutable"
    JSON_OUTPUT=false
    DIFF_MODE=false
    MUTABLE_ONLY=false

    show_help() {
        echo "📊 dotfiles-drift - Show drift between source and target dotfiles"
        echo ""
        echo "Usage: dotfiles-drift [OPTIONS] [FILE...]"
        echo ""
        echo "Options:"
        echo "  --json          Output in JSON format"
        echo "  --diff          Show full unified diff for each file"
        echo "  --mutable-only  Only show mutable files"
        echo "  -h, --help      Show this help message"
    }

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --json)
                JSON_OUTPUT=true
                shift
                ;;
            --diff)
                DIFF_MODE=true
                shift
                ;;
            --mutable-only)
                MUTABLE_ONLY=true
                shift
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            *)
                shift
                ;;
        esac
    done

    # Check if file is mutable
    is_mutable() {
        local file="$1"
        [[ -f "$MUTABLE_FILE" ]] && grep -qF "$file" "$MUTABLE_FILE" 2>/dev/null
    }

    if [[ "$JSON_OUTPUT" == "true" ]]; then
        # JSON output mode
        echo "{"
        echo "  \"source\": \"$DOTFILES_DIR\","
        echo "  \"target\": \"$HOME\","
        echo "  \"files\": ["

        first=true
        while IFS= read -r line; do
            [[ -z "$line" ]] && continue
            status="''${line:0:2}"
            file="''${line:3}"

            # Determine mutability
            mutable="false"
            is_mutable "$file" && mutable="true"

            [[ "$MUTABLE_ONLY" == "true" && "$mutable" == "false" ]] && continue

            [[ "$first" == "false" ]] && echo ","
            first=false

            state="SYNC"
            [[ "$status" == "MM" || "$status" == " M" ]] && state="TARGET_MODIFIED"
            [[ "$status" == "M " ]] && state="SOURCE_MODIFIED"
            [[ "$status" == "A " ]] && state="MISSING"

            echo -n "    {\"path\": \"$file\", \"state\": \"$state\", \"mutable\": $mutable}"
        done < <(chezmoi status --source "$DOTFILES_DIR" 2>/dev/null || true)

        echo ""
        echo "  ]"
        echo "}"
    else
        # Human-readable output
        echo "📊 Dotfiles Drift Report"
        echo "========================"
        echo ""
        echo "Source: $DOTFILES_DIR"
        echo "Target: $HOME"
        echo ""

        # Get status
        STATUS_OUTPUT=$(chezmoi status --source "$DOTFILES_DIR" 2>/dev/null || true)

        if [[ -z "$STATUS_OUTPUT" ]]; then
            echo "✅ All dotfiles are in sync"
            exit 0
        fi

        MUTABLE_FILES=""
        IMMUTABLE_FILES=""
        DRIFTED_COUNT=0

        while IFS= read -r line; do
            [[ -z "$line" ]] && continue
            status="''${line:0:2}"
            file="''${line:3}"

            label="[SYNC]"
            [[ "$status" == "MM" || "$status" == " M" ]] && { label="[MODIFIED]"; ((DRIFTED_COUNT++)) || true; }
            [[ "$status" == "M " ]] && label="[SOURCE]"
            [[ "$status" == "A " ]] && label="[NEW]"

            if is_mutable "$file"; then
                [[ "$MUTABLE_ONLY" == "false" || "$label" != "[SYNC]" ]] && \
                    MUTABLE_FILES+="  $file  $label"$'\n'
            else
                [[ "$MUTABLE_ONLY" == "false" ]] && \
                    IMMUTABLE_FILES+="  $file  $label"$'\n'
            fi

            # Show diff if requested
            if [[ "$DIFF_MODE" == "true" && "$label" == "[MODIFIED]" ]]; then
                echo "--- Diff: $file ---"
                chezmoi diff "$HOME/$file" 2>/dev/null || true
                echo ""
            fi
        done <<< "$STATUS_OUTPUT"

        if [[ -n "$MUTABLE_FILES" ]]; then
            echo "MUTABLE FILES"
            echo "─────────────"
            echo -n "$MUTABLE_FILES"
            echo ""
        fi

        if [[ -n "$IMMUTABLE_FILES" && "$MUTABLE_ONLY" == "false" ]]; then
            echo "IMMUTABLE FILES"
            echo "───────────────"
            echo -n "$IMMUTABLE_FILES"
            echo ""
        fi

        echo "SUMMARY"
        echo "───────"
        echo "Drifted files: $DRIFTED_COUNT"

        if [[ $DRIFTED_COUNT -gt 0 ]]; then
            echo ""
            echo "💡 Run 'dotfiles-capture' to adopt changes to source"
            echo "💡 Run 'dotfiles-apply' to overwrite target with source"
            exit 1
        fi
    fi
  '';

  # Script to capture runtime changes back to source
  captureScript = pkgs.writeShellScriptBin "dotfiles-capture" ''
    #!/usr/bin/env bash
    set -euo pipefail

    DOTFILES_DIR="${dotfilesPath}"
    MUTABLE_FILE="$DOTFILES_DIR/.chezmoimutable"
    DRY_RUN=false
    FORCE=false
    CAPTURE_ALL=false
    FILES=()

    show_help() {
        echo "📥 dotfiles-capture - Capture runtime changes back to dotfiles source"
        echo ""
        echo "Usage: dotfiles-capture [OPTIONS] [FILE...]"
        echo ""
        echo "Options:"
        echo "  --all       Capture all files with drift (prompts for immutable)"
        echo "  --dry-run   Show what would be captured without making changes"
        echo "  --force     Skip confirmation prompts"
        echo "  -h, --help  Show this help message"
        echo ""
        echo "Examples:"
        echo "  dotfiles-capture                          # Capture all mutable changes"
        echo "  dotfiles-capture ~/.config/zed/settings.json  # Capture specific file"
        echo "  dotfiles-capture --dry-run                # Preview changes"
    }

    # Check if file is mutable
    is_mutable() {
        local file="$1"
        [[ -f "$MUTABLE_FILE" ]] && grep -qF "$file" "$MUTABLE_FILE" 2>/dev/null
    }

    # Check if file is a template
    is_template() {
        local file="$1"
        local source_file
        source_file=$(chezmoi source-path "$file" 2>/dev/null || echo "")
        [[ "$source_file" == *.tmpl ]]
    }

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --all)
                CAPTURE_ALL=true
                shift
                ;;
            --dry-run)
                DRY_RUN=true
                shift
                ;;
            --force)
                FORCE=true
                shift
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            -*)
                echo "Unknown option: $1"
                show_help
                exit 1
                ;;
            *)
                FILES+=("$1")
                shift
                ;;
        esac
    done

    echo "📥 Capturing dotfiles changes"
    echo "============================"
    echo ""

    # Get files with drift
    DRIFTED=()
    while IFS= read -r line; do
        [[ -z "$line" ]] && continue
        status="''${line:0:2}"
        file="''${line:3}"

        # Only capture modified files
        [[ "$status" != "MM" && "$status" != " M" ]] && continue

        # If specific files requested, filter
        if [[ ''${#FILES[@]} -gt 0 ]]; then
            match=false
            for f in "''${FILES[@]}"; do
                [[ "$HOME/$file" == "$f" || "$file" == "$f" ]] && match=true
            done
            [[ "$match" == "false" ]] && continue
        fi

        DRIFTED+=("$file")
    done < <(chezmoi status --source "$DOTFILES_DIR" 2>/dev/null || true)

    if [[ ''${#DRIFTED[@]} -eq 0 ]]; then
        echo "✅ No files with drift to capture"
        exit 0
    fi

    echo "Files with changes:"
    CAPTURE_LIST=()
    for file in "''${DRIFTED[@]}"; do
        # Check if template
        if is_template "$HOME/$file"; then
            echo "  ⚠️  $file [TEMPLATE - cannot capture]"
            continue
        fi

        # Check mutability
        if is_mutable "$file"; then
            echo "  📝 $file [mutable]"
            CAPTURE_LIST+=("$HOME/$file")
        elif [[ "$CAPTURE_ALL" == "true" ]]; then
            echo "  📝 $file [immutable - will capture]"
            CAPTURE_LIST+=("$HOME/$file")
        else
            echo "  ⏭️  $file [immutable - skipped]"
        fi
    done
    echo ""

    if [[ ''${#CAPTURE_LIST[@]} -eq 0 ]]; then
        echo "No files to capture (templates and immutable files skipped)"
        echo "💡 Use --all to include immutable files"
        exit 0
    fi

    if [[ "$DRY_RUN" == "true" ]]; then
        echo "[DRY RUN] Would capture ''${#CAPTURE_LIST[@]} file(s)"
        exit 0
    fi

    # Confirm unless forced
    if [[ "$FORCE" == "false" ]]; then
        echo -n "Capture these ''${#CAPTURE_LIST[@]} file(s) to source? [y/N] "
        read -r response
        [[ "$response" != "y" && "$response" != "Y" ]] && { echo "Aborted."; exit 0; }
    fi

    # Capture files
    for file in "''${CAPTURE_LIST[@]}"; do
        echo "Capturing: $file"
        chezmoi re-add "$file" || echo "  ⚠️  Failed to capture $file"
    done

    echo ""
    echo "✅ Captured ''${#CAPTURE_LIST[@]} file(s)"
    echo ""
    echo "📝 Changes in source:"
    git -C "$DOTFILES_DIR/.." diff --stat dotfiles/ 2>/dev/null || true
    echo ""
    echo "💡 Remember to commit: cd ~/NixOS && git add dotfiles/ && git commit -m 'Capture dotfiles changes'"
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

    # New options for mutable dotfiles sync
    validateJson = mkOption {
      type = types.bool;
      default = true;
      description = "Enable JSON/JSONC validation with duplicate key detection";
    };

    mutableFiles = mkOption {
      type = types.listOf types.str;
      default = [];
      example = [".config/zed/settings.json" ".config/Code/User/settings.json"];
      description = "List of dotfile paths that should be mutable (not overwritten on apply)";
    };
  };

  config = mkIf cfg.enable {
    # Ensure chezmoi and required tools are available
    environment.systemPackages =
      [
        pkgs.chezmoi
        pkgs.jq
        pkgs.python3
      ]
      ++ (optionals cfg.enableHelperScripts [
        initScript
        applyScript
        editScript
        addScript
        statusScript
        syncScript
        checkScript
        validateScript
        driftScript
        captureScript
      ]);

    # Create shell aliases for convenience
    environment.shellAliases = mkIf cfg.enableHelperScripts {
      "dotfiles" = "dotfiles-status";
      "dotfiles-diff" = "dotfiles-apply --diff";
      "dotfiles-info" = "dotfiles-sync";
    };

    # Bash completions for dotfiles commands
    programs.bash.interactiveShellInit = mkIf cfg.enableHelperScripts ''
      # Dotfiles command completions
      _dotfiles_complete() {
        local cur="''${COMP_WORDS[COMP_CWORD]}"
        local cmd="''${COMP_WORDS[0]}"

        case "$cmd" in
          dotfiles-apply)
            COMPREPLY=($(compgen -W "--diff --force-all --help" -- "$cur"))
            ;;
          dotfiles-validate)
            COMPREPLY=($(compgen -W "--fix --source --target --both --quiet --help" -- "$cur"))
            ;;
          dotfiles-drift)
            COMPREPLY=($(compgen -W "--diff --json --mutable-only --help" -- "$cur"))
            ;;
          dotfiles-capture)
            COMPREPLY=($(compgen -W "--dry-run --all --force --help" -- "$cur"))
            ;;
        esac
      }

      complete -F _dotfiles_complete dotfiles-apply
      complete -F _dotfiles_complete dotfiles-validate
      complete -F _dotfiles_complete dotfiles-drift
      complete -F _dotfiles_complete dotfiles-capture
    '';

    # Zsh completions for dotfiles commands
    programs.zsh.interactiveShellInit = mkIf cfg.enableHelperScripts ''
      # Dotfiles command completions
      _dotfiles_apply() {
        _arguments \
          '--diff[Show diff without applying]' \
          '--force-all[Force apply all files including mutable]' \
          '--help[Show help message]' \
          '*:file:_files'
      }

      _dotfiles_validate() {
        _arguments \
          '--fix[Automatically fix duplicate keys]' \
          '--source[Validate source files]' \
          '--target[Validate target files]' \
          '--both[Validate both locations]' \
          '(-q --quiet)'{-q,--quiet}'[Only output errors]' \
          '--help[Show help message]' \
          '*:file:_files'
      }

      _dotfiles_drift() {
        _arguments \
          '--diff[Show full unified diff]' \
          '--json[Output in JSON format]' \
          '--mutable-only[Only show mutable files]' \
          '--help[Show help message]'
      }

      _dotfiles_capture() {
        _arguments \
          '--dry-run[Preview without changes]' \
          '--all[Include immutable files]' \
          '--force[Skip confirmation]' \
          '--help[Show help message]' \
          '*:file:_files'
      }

      compdef _dotfiles_apply dotfiles-apply
      compdef _dotfiles_validate dotfiles-validate
      compdef _dotfiles_drift dotfiles-drift
      compdef _dotfiles_capture dotfiles-capture
    '';

    # Expose secrets as environment variables for chezmoi templates
    # This allows templates to use: {{ env "CHEZMOI_SECRET_NAME" }}
    # Secrets will be available when sops-nix is configured
    environment.sessionVariables = mkIf cfg.secretsIntegration {
      # These paths will be populated by sops-nix when configured
      # Example: CHEZMOI_GITHUB_TOKEN points to decrypted secret
      # Add your secrets here following the pattern:
      # CHEZMOI_SECRET_NAME = "/run/secrets/secret-name";
    };

    # Generate .chezmoimutable file from mutableFiles option
    # This activation script runs during system rebuild and creates the mutable file list
    system.activationScripts.dotfilesMutable = mkIf (cfg.mutableFiles != []) {
      text = ''
        # Generate .chezmoimutable file from NixOS configuration
        MUTABLE_FILE="${dotfilesPath}/.chezmoimutable"
        echo "# Generated by NixOS - do not edit directly" > "$MUTABLE_FILE"
        echo "# Configure via modules.dotfiles.mutableFiles option" >> "$MUTABLE_FILE"
        echo "" >> "$MUTABLE_FILE"
        ${concatStringsSep "\n" (map (f: ''echo "${f}" >> "$MUTABLE_FILE"'') cfg.mutableFiles)}
        chmod 644 "$MUTABLE_FILE"
      '';
      deps = [];
    };
  };
}
