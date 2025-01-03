#!/usr/bin/env bash

# Strict error handling
set -euo pipefail
IFS=$'\n\t'

# Script meta information
readonly SCRIPT_VERSION="2.0.0"
readonly SCRIPT_NAME=$(basename "$0")

# Configuration
readonly FLAKE_DIR="$HOME/NixOS"
readonly LOG_DIR="$HOME/.local/share/nixos-rebuild/logs"
readonly STATE_DIR="$HOME/.local/share/nixos-rebuild/state"
readonly CACHE_DIR="$HOME/.cache/nixos-rebuild"

# Color definitions using tput for better portability
readonly RED=$(tput setaf 1)
readonly GREEN=$(tput setaf 2)
readonly YELLOW=$(tput setaf 3)
readonly BLUE=$(tput setaf 4)
readonly MAGENTA=$(tput setaf 5)
readonly CYAN=$(tput setaf 6)
readonly BOLD=$(tput bold)
readonly RESET=$(tput sgr0)

# Logging levels
declare -rA LOG_LEVELS=([DEBUG]=0 [INFO]=1 [WARN]=2 [ERROR]=3)
LOG_LEVEL=${LOG_LEVEL:-INFO}

# Usage information
usage() {
    cat <<EOF
${BOLD}Usage:${RESET} $SCRIPT_NAME [OPTIONS] <host>

${BOLD}Options:${RESET}
  -h, --help              Show this help message
  -v, --version           Show script version
  -d, --debug            Enable debug mode
  -n, --dry-run          Perform a dry run without making changes
  -f, --force            Skip all confirmation prompts
  -l, --log-level LEVEL  Set log level (DEBUG|INFO|WARN|ERROR)
  -k, --keep GENS        Number of generations to keep (default: 5)
  --no-update            Skip flake updates
  --no-optimize          Skip store optimization
  --no-format           Skip nix file formatting
  --no-push             Skip git push
  --rollback            Rollback to the previous generation

${BOLD}Examples:${RESET}
  $SCRIPT_NAME laptop
  $SCRIPT_NAME --debug default
  $SCRIPT_NAME --dry-run --no-update experimental-vm

${BOLD}Available Hosts:${RESET}
$(list_available_hosts | sed 's/^/  /')

${BOLD}Environment Variables:${RESET}
  LOG_LEVEL     Set logging level (default: INFO)
  NIXOS_DEBUG   Enable extra debugging (1=enabled)
EOF
}

# Logging functions
log() {
    local level=$1
    shift
    local message=$*
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local log_file="${LOG_DIR}/nixos-rebuild-$(date '+%Y%m%d').log"

    # Check if we should log this message based on level
    if [[ ${LOG_LEVELS[$level]} -ge ${LOG_LEVELS[$LOG_LEVEL]} ]]; then
        # Ensure log directory exists
        mkdir -p "$(dirname "$log_file")"

        # Format message
        local formatted_message="${timestamp} [${level}] ${message}"

        # Log to file
        echo "${formatted_message}" >> "$log_file"

        # Log to console with colors
        case $level in
            DEBUG) echo "${CYAN}${formatted_message}${RESET}" ;;
            INFO)  echo "${GREEN}${formatted_message}${RESET}" ;;
            WARN)  echo "${YELLOW}${formatted_message}${RESET}" >&2 ;;
            ERROR) echo "${RED}${formatted_message}${RESET}" >&2 ;;
        esac
    fi
}

debug() { log "DEBUG" "$*"; }
info() { log "INFO" "$*"; }
warn() { log "WARN" "$*"; }
error() { log "ERROR" "$*"; }

# Error handling
cleanup() {
    local exit_code=$?
    if [[ $exit_code -ne 0 ]]; then
        error "Script failed with exit code $exit_code"
        if [[ -f "$LOG_FILE" ]]; then
            error "Last 10 lines of the log:"
            tail -n 10 "$LOG_FILE" | sed 's/^/    /'
        fi
    fi
    exit $exit_code
}
trap cleanup EXIT

# Function to list available hosts
list_available_hosts() {
    local hosts_dir="$FLAKE_DIR/hosts"
    if [[ -d "$hosts_dir" ]]; then
        for host in "$hosts_dir"/*/; do
            if [[ -d "$host" ]]; then
                basename "$host"
            fi
        done
    fi
}

# Verify host exists
verify_host() {
    local host=$1
    if [[ ! -d "$FLAKE_DIR/hosts/$host" ]]; then
        error "Host '$host' not found in $FLAKE_DIR/hosts/"
        echo "Available hosts:"
        list_available_hosts | sed 's/^/  /'
        exit 1
    fi
}

# Function to handle command execution with logging
execute() {
    local cmd_name=$1
    shift
    local cmd=("$@")

    debug "Executing: ${cmd[*]}"

    if [[ "${DRY_RUN:-false}" == true ]]; then
        info "[DRY-RUN] Would execute: ${cmd[*]}"
        return 0
    fi

    local start_time=$(date +%s)
    local temp_log="${CACHE_DIR}/temp_${RANDOM}.log"
    mkdir -p "$(dirname "$temp_log")"

    if gum spin --spinner dot --title "Running $cmd_name..." -- \
        "${cmd[@]}" > "$temp_log" 2>&1; then
        local end_time=$(date +%s)
        local duration=$((end_time - start_time))
        info "✓ $cmd_name completed in ${duration}s"
        cat "$temp_log" >> "$LOG_FILE"
    else
        local exit_code=$?
        error "✗ $cmd_name failed with exit code $exit_code"
        echo "Last 50 lines of output:"
        tail -n 50 "$temp_log" | sed 's/^/    /'
        cat "$temp_log" >> "$LOG_FILE"
        rm -f "$temp_log"
        return $exit_code
    fi
    rm -f "$temp_log"
}

# Parse command line arguments
TEMP=$(getopt -o hvdnfl:k: --long help,version,debug,dry-run,force,log-level:,keep:,no-update,no-optimize,no-format,no-push,rollback -n "$SCRIPT_NAME" -- "$@")
eval set -- "$TEMP"

# Default values
DRY_RUN=false
FORCE=false
KEEP_GENERATIONS=5
SKIP_UPDATE=false
SKIP_OPTIMIZE=false
SKIP_FORMAT=false
SKIP_PUSH=false
ROLLBACK=false

# Parse options
while true; do
    case "$1" in
        -h|--help) usage; exit 0 ;;
        -v|--version) echo "$SCRIPT_NAME version $SCRIPT_VERSION"; exit 0 ;;
        -d|--debug) LOG_LEVEL=DEBUG; set -x; shift ;;
        -n|--dry-run) DRY_RUN=true; shift ;;
        -f|--force) FORCE=true; shift ;;
        -l|--log-level) LOG_LEVEL=$2; shift 2 ;;
        -k|--keep) KEEP_GENERATIONS=$2; shift 2 ;;
        --no-update) SKIP_UPDATE=true; shift ;;
        --no-optimize) SKIP_OPTIMIZE=true; shift ;;
        --no-format) SKIP_FORMAT=true; shift ;;
        --no-push) SKIP_PUSH=true; shift ;;
        --rollback) ROLLBACK=true; shift ;;
        --) shift; break ;;
        *) error "Invalid option: $1"; usage; exit 1 ;;
    esac
done

# Verify host argument
if [[ $# -ne 1 ]]; then
    error "Host argument is required"
    usage
    exit 1
fi

HOST=$1
verify_host "$HOST"

# Setup logging
mkdir -p "$LOG_DIR" "$STATE_DIR" "$CACHE_DIR"
LOG_FILE="${LOG_DIR}/nixos-rebuild-${HOST}-$(date '+%Y%m%d_%H%M%S').log"
touch "$LOG_FILE"

# Print banner
gum style \
    --border double \
    --align center \
    --width 50 \
    --margin "1 2" \
    --padding "1 2" \
    "NixOS Rebuild Script v${SCRIPT_VERSION}
Host: ${HOST}
Mode: $(if [[ $DRY_RUN == true ]]; then echo "Dry Run"; else echo "Normal"; fi)"

# Confirm operation
if [[ $FORCE == false && $DRY_RUN == false ]]; then
    if ! gum confirm "Proceed with rebuilding host '${HOST}'?"; then
        info "Operation cancelled by user"
        exit 0
    fi
fi

# Main rebuild process
cd "$FLAKE_DIR"

if [[ $ROLLBACK == true ]]; then
    info "Rolling back to previous generation..."
    execute "Rollback" sudo nixos-rebuild rollback --flake ".#${HOST}"
    exit $?
fi

# Update channels and flake inputs
if [[ $SKIP_UPDATE == false ]]; then
    execute "Update Channels" sudo nix-channel --update
    execute "Update Flake" nix flake update
fi

# Clean and optimize
execute "Garbage Collection" sudo nix-collect-garbage --delete-older-than "${KEEP_GENERATIONS}d"

if [[ $SKIP_OPTIMIZE == false ]]; then
    execute "Store Optimization" sudo nix-store --optimize
fi

# Format Nix files
if [[ $SKIP_FORMAT == false ]]; then
    execute "Format Files" alejandra .
fi

# Show changes
if [[ $DRY_RUN == false ]]; then
    git_changes=$(git diff -U0 *.nix)
    if [[ -n "$git_changes" ]]; then
        info "Changes detected in Nix files:"
        echo "$git_changes" | gum format
    fi
fi

# Rebuild NixOS
rebuild_cmd=(sudo nixos-rebuild switch --flake ".#${HOST}")
if [[ $DRY_RUN == true ]]; then
    rebuild_cmd+=(--dry-run)
fi

if ! execute "NixOS Rebuild" "${rebuild_cmd[@]}"; then
    error "Build failed! Check the logs at $LOG_FILE"
    exit 1
fi

# Clean up old boot entries
execute "Boot Cleanup" sudo /run/current-system/bin/switch-to-configuration boot

if [[ $DRY_RUN == false ]]; then
    # Get current generation info
    gen=$(nixos-rebuild --flake ".#${HOST}" list-generations | grep current)

    # Commit and push changes
    execute "Git Commit" git add .
    execute "Git Commit" git commit -m "rebuild(${HOST}): ${gen}"

    if [[ $SKIP_PUSH == false ]]; then
        execute "Git Push" git push
    fi
fi

# Final success message
gum style \
    --border double \
    --align center \
    --width 50 \
    --margin "1 2" \
    --padding "1 2" \
    "🎉 NixOS update completed successfully! 🎉
Host: ${HOST}
Log: ${LOG_FILE}"

info "Done! You may need to restart for all changes to take effect."
