# ~/NixOS/modules/services/waydroid-desktop-hygiene.nix
# Waydroid Desktop Entry Hygiene - Hides Waydroid per-app launchers from GNOME
#
# Problem: Waydroid creates .desktop files for each Android app, cluttering
# the application launcher. Deleting or setting NoDisplay=true is temporary
# as Waydroid recreates/overwrites them.
#
# Solution: Replace desktop files with symlinks to /dev/null. Waydroid sees
# "file exists" and skips recreation.
{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.modules.services.waydroid-desktop-hygiene;

  # The cleanup script
  hygieneScript = pkgs.writeShellScriptBin "waydroid-desktop-hygiene" ''
    set -euo pipefail

    # Configuration from NixOS options
    BACKUP_ENABLED="${toString cfg.backupEnabled}"
    BACKUP_DIR="$HOME/${cfg.backupDir}"
    HIDE_MAIN_LAUNCHER="${toString cfg.hideMainLauncher}"
    APPS_DIR="$HOME/.local/share/applications"

    # Script state
    DRY_RUN=false
    VERBOSE=false
    RESTORE=false

    # Colors for output
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    NC='\033[0m' # No Color

    log_info() {
      echo -e "''${GREEN}[INFO]''${NC} $1"
    }

    log_warn() {
      echo -e "''${YELLOW}[WARN]''${NC} $1"
    }

    log_error() {
      echo -e "''${RED}[ERROR]''${NC} $1" >&2
    }

    log_verbose() {
      if [ "$VERBOSE" = true ]; then
        echo -e "[DEBUG] $1"
      fi
    }

    show_help() {
      cat << 'EOF'
    waydroid-desktop-hygiene - Hide Waydroid app launchers from GNOME

    USAGE:
        waydroid-desktop-hygiene [OPTIONS]

    OPTIONS:
        --help      Show this help message
        --dry-run   Show what would be done without making changes
        --verbose   Increase logging verbosity
        --restore   Remove symlinks and restore from backups

    DESCRIPTION:
        This tool replaces Waydroid-generated .desktop files with symlinks
        to /dev/null, preventing them from appearing in GNOME's application
        launcher while stopping Waydroid from recreating them.

    EXAMPLES:
        waydroid-desktop-hygiene              # Hide all Waydroid app entries
        waydroid-desktop-hygiene --dry-run    # Preview changes
        waydroid-desktop-hygiene --restore    # Restore original files
    EOF
      exit 0
    }

    # Parse arguments
    while [[ $# -gt 0 ]]; do
      case $1 in
        --help)
          show_help
          ;;
        --dry-run)
          DRY_RUN=true
          shift
          ;;
        --verbose)
          VERBOSE=true
          shift
          ;;
        --restore)
          RESTORE=true
          shift
          ;;
        *)
          log_error "Unknown option: $1"
          echo "Use --help for usage information"
          exit 2
          ;;
      esac
    done

    # Check if applications directory exists
    if [ ! -d "$APPS_DIR" ]; then
      log_warn "Applications directory does not exist: $APPS_DIR"
      log_info "Nothing to do."
      exit 0
    fi

    # Get matching files based on configuration
    get_target_files() {
      local pattern="waydroid.*.desktop"

      # Find matching files
      find "$APPS_DIR" -maxdepth 1 -name "$pattern" -type f -o -name "$pattern" -type l 2>/dev/null || true

      # Optionally include main launcher
      if [ "$HIDE_MAIN_LAUNCHER" = "true" ]; then
        if [ -e "$APPS_DIR/Waydroid.desktop" ]; then
          echo "$APPS_DIR/Waydroid.desktop"
        fi
      fi
    }

    # Check if file is already a symlink to /dev/null
    is_null_symlink() {
      local file="$1"
      if [ -L "$file" ]; then
        local target
        target=$(readlink "$file")
        if [ "$target" = "/dev/null" ]; then
          return 0
        fi
      fi
      return 1
    }

    # Backup a file before modification
    backup_file() {
      local file="$1"
      local filename
      filename=$(basename "$file")

      if [ "$BACKUP_ENABLED" = "true" ]; then
        if [ "$DRY_RUN" = true ]; then
          log_verbose "Would backup: $filename -> $BACKUP_DIR/"
        else
          mkdir -p "$BACKUP_DIR"
          cp "$file" "$BACKUP_DIR/$filename"
          log_verbose "Backed up: $filename"
        fi
      fi
    }

    # Neutralize a desktop file (replace with /dev/null symlink)
    neutralize_file() {
      local file="$1"
      local filename
      filename=$(basename "$file")

      # Skip if already a symlink to /dev/null
      if is_null_symlink "$file"; then
        log_verbose "Skipped (already processed): $filename"
        return 0
      fi

      # Skip if it's a symlink to something else
      if [ -L "$file" ]; then
        local target
        target=$(readlink "$file")
        log_warn "Skipped (unexpected symlink to $target): $filename"
        return 0
      fi

      # Process regular file
      if [ -f "$file" ]; then
        if [ "$DRY_RUN" = true ]; then
          log_info "Would neutralize: $filename"
        else
          backup_file "$file"
          rm "$file"
          ln -s /dev/null "$file"
          log_info "Neutralized: $filename"
        fi
      fi
    }

    # Restore a desktop file from backup
    restore_file() {
      local file="$1"
      local filename
      filename=$(basename "$file")
      local backup_path="$BACKUP_DIR/$filename"

      # Only process symlinks to /dev/null
      if ! is_null_symlink "$file"; then
        if [ -e "$file" ]; then
          log_verbose "Skipped (not a null symlink): $filename"
        fi
        return 0
      fi

      if [ "$DRY_RUN" = true ]; then
        if [ -f "$backup_path" ]; then
          log_info "Would restore from backup: $filename"
        else
          log_info "Would remove symlink (no backup, Waydroid will recreate): $filename"
        fi
      else
        rm "$file"

        if [ -f "$backup_path" ]; then
          cp "$backup_path" "$file"
          log_info "Restored from backup: $filename"
        else
          log_warn "No backup found for $filename - Waydroid will recreate it"
        fi
      fi
    }

    # Main execution
    main() {
      local files
      local count=0

      if [ "$DRY_RUN" = true ]; then
        log_info "DRY RUN MODE - No changes will be made"
      fi

      if [ "$RESTORE" = true ]; then
        log_info "Restore mode - removing symlinks and restoring backups"

        # In restore mode, look for symlinks to /dev/null
        while IFS= read -r file; do
          [ -z "$file" ] && continue
          restore_file "$file"
          ((count++)) || true
        done < <(get_target_files)

        if [ $count -eq 0 ]; then
          log_info "No files to restore."
        else
          log_info "Processed $count file(s)."
        fi
      else
        log_info "Scanning for Waydroid desktop entries..."

        while IFS= read -r file; do
          [ -z "$file" ] && continue
          neutralize_file "$file"
          ((count++)) || true
        done < <(get_target_files)

        if [ $count -eq 0 ]; then
          log_info "No Waydroid desktop files found."
        else
          log_info "Processed $count file(s)."
        fi
      fi
    }

    main
  '';
in {
  options.modules.services.waydroid-desktop-hygiene = {
    enable = mkEnableOption "Waydroid desktop entry hygiene";

    hideMainLauncher = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Also process the main Waydroid.desktop launcher.
        Note: Waydroid already sets NoDisplay=true on this file by default.
        Enable this only if you want additional persistence against Waydroid
        overwriting the file.
      '';
    };

    backupEnabled = mkOption {
      type = types.bool;
      default = true;
      description = "Backup original desktop files before replacing with symlinks";
    };

    backupDir = mkOption {
      type = types.str;
      default = ".local/share/waydroid-desktop-backups";
      description = "Directory (relative to home) for desktop file backups";
    };
  };

  config = mkIf cfg.enable {
    # Add CLI command to system packages
    environment.systemPackages = [hygieneScript];

    # Path watcher - triggers on any changes to applications directory
    systemd.user.paths.waydroid-desktop-hygiene = {
      description = "Watch for Waydroid desktop file changes";
      wantedBy = ["default.target"];

      pathConfig = {
        PathChanged = "%h/.local/share/applications";
        MakeDirectory = true;
      };
    };

    # Service to run the cleanup script
    systemd.user.services.waydroid-desktop-hygiene = {
      description = "Neutralize Waydroid desktop entries";

      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = false;
        # Small delay to let batch operations complete
        ExecStartPre = "${pkgs.coreutils}/bin/sleep 1";
        ExecStart = "${hygieneScript}/bin/waydroid-desktop-hygiene";
        StandardOutput = "journal";
        StandardError = "journal";
      };
    };
  };
}
